version 1.0

import "tasks/biopet/biopet.wdl" as biopet
import "tasks/gatk.wdl" as gatk
import "tasks/picard.wdl" as picard
import "tasks/common.wdl" as common

workflow GatkPreprocess {
    input{
        IndexedBamFile bamFile
        String basePath
        Reference reference
        Boolean splitSplicedReads = false
        Boolean outputRecalibratedBam = false
        IndexedVcfFile dbsnpVCF
        # Scatter size is based on bases in the reference genome. The human genome is approx 3 billion base pairs
        # With a scatter size of 0.4 billion this will lead to 8 scatters.
        Int scatterSize = 400000000
        File? regions
    }

    String outputDir = sub(basePath, basename(basePath) + "$", "")
    String scatterDir = outputDir +  "/gatk_preprocess_scatter/"

    call biopet.ScatterRegions as scatterList {
        input:
            reference = reference,
            outputDirPath = scatterDir,
            scatterSize = scatterSize,
            notSplitContigs = true,
            regions = regions
    }

    # Glob messes with order of scatters (10 comes before 1), which causes problem at gatherBamFiles
    call biopet.ReorderGlobbedScatters as orderedScatters {
        input:
            scatters = scatterList.scatters
    }

    scatter (bed in orderedScatters.reorderedScatters) {
        call gatk.BaseRecalibrator as baseRecalibrator {
            input:
                sequenceGroupInterval = [bed],
                reference = reference,
                inputBam = bamFile,
                recalibrationReportPath = scatterDir + "/" + basename(bed) + ".bqsr",
                dbsnpVCF = dbsnpVCF
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            inputBQSRreports = baseRecalibrator.recalibrationReport,
            outputReportPath = basePath + ".bqsr"
    }

    scatter (bed in orderedScatters.reorderedScatters) {
        if (splitSplicedReads) {
            call gatk.SplitNCigarReads as splitNCigarReads {
                input:
                    intervals = [bed],
                    reference = reference,
                    inputBam = bamFile,
                    outputBam = scatterDir + "/" + basename(bed) + ".split.bam"
            }

            File splicedBamFiles = splitNCigarReads.bam.file
            File splicedBamIndexes = splitNCigarReads.bam.index
        }

        if (outputRecalibratedBam) {
            call gatk.ApplyBQSR as applyBqsr {
                input:
                    sequenceGroupInterval = [bed],
                    reference = reference,
                    inputBam = if splitSplicedReads
                        then select_first([splitNCigarReads.bam])
                        else bamFile,
                    recalibrationReport = gatherBqsr.outputBQSRreport,
                    outputBamPath = if splitSplicedReads
                        then scatterDir + "/" + basename(bed) + ".split.bqsr.bam"
                        else scatterDir + "/" + basename(bed) + ".bqsr.bam"
            }

            File chunkBamFiles = applyBqsr.recalibratedBam.file
            File chunkBamIndexes = applyBqsr.recalibratedBam.index
        }
    }

    # If splitSplicedReads a is true a new bam file should be made even if
    # ouputRecalibratedBam is false.
    if (outputRecalibratedBam || splitSplicedReads) {
        call picard.GatherBamFiles as gatherBamFiles {
            input:
                inputBams = if outputRecalibratedBam
                    then select_all(chunkBamFiles)
                    else select_all(splicedBamFiles),
                inputBamsIndex = if outputRecalibratedBam
                    then select_all(chunkBamIndexes)
                    else select_all(splicedBamIndexes),
                outputBamPath = basePath + ".bam"
        }
    }

    output {
        IndexedBamFile? outputBamFile = gatherBamFiles.outputBam
        File BQSRreport = gatherBqsr.outputBQSRreport
    }
}
