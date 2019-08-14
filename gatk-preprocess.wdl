version 1.0

import "tasks/biopet/biopet.wdl" as biopet
import "tasks/gatk.wdl" as gatk
import "tasks/picard.wdl" as picard
import "tasks/common.wdl" as common

workflow GatkPreprocess {
    input{
        IndexedBamFile bamFile
        String bamName = "recalibrated"
        String outputDir = "."
        Reference reference
        Boolean splitSplicedReads = false
        Boolean outputRecalibratedBam = false
        IndexedVcfFile dbsnpVCF
        # Scatter size is based on bases in the reference genome. The human genome is approx 3 billion base pairs
        # With a scatter size of 1 billion this will lead to ~3 scatters.
        Int scatterSize = 1000000000
        File? regions
        Map[String, String] dockerImages = {
          "picard":"quay.io/biocontainers/picard:2.18.26--0",
          "gatk4":"quay.io/biocontainers/gatk4:4.1.0.0--0",
          "biopet-scatterregions":"quay.io/biocontainers/biopet-scatterregions:0.2--0"
        }
    }

    String scatterDir = outputDir +  "/gatk_preprocess_scatter/"

    call biopet.ScatterRegions as scatterList {
        input:
            referenceFasta = reference.fasta,
            referenceFastaDict = reference.dict,
            scatterSize = scatterSize,
            notSplitContigs = true,
            regions = regions,
            dockerImage = dockerImages["biopet-scatterregions"]
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
                referenceFasta = reference.fasta,
                referenceFastaFai = reference.fai,
                referenceFastaDict = reference.dict,
                inputBam = bamFile.file,
                inputBamIndex = bamFile.index,
                recalibrationReportPath = scatterDir + "/" + basename(bed) + ".bqsr",
                dbsnpVCF = dbsnpVCF.file,
                dbsnpVCFIndex = dbsnpVCF.index,
                dockerImage = dockerImages["gatk4"]
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            inputBQSRreports = baseRecalibrator.recalibrationReport,
            outputReportPath = outputDir + "/" + bamName + ".bqsr",
            dockerImage = dockerImages["gatk4"]
    }

    scatter (bed in orderedScatters.reorderedScatters) {
        if (splitSplicedReads) {
            call gatk.SplitNCigarReads as splitNCigarReads {
                input:
                    intervals = [bed],
                    referenceFasta = reference.fasta,
                    referenceFastaFai = reference.fai,
                    referenceFastaDict = reference.dict,
                    inputBam = bamFile.file,
                    inputBamIndex = bamFile.index,
                    outputBam = scatterDir + "/" + basename(bed) + ".split.bam",
                    dockerImage = dockerImages["gatk4"]
            }

        }

        if (outputRecalibratedBam) {
            call gatk.ApplyBQSR as applyBqsr {
                input:
                    sequenceGroupInterval = [bed],
                    referenceFasta = reference.fasta,
                    referenceFastaFai = reference.fai,
                    referenceFastaDict = reference.dict,
                    inputBam = if splitSplicedReads
                        then select_first([splitNCigarReads.bam])
                        else bamFile.file,
                    inputBamIndex = if splitSplicedReads
                        then select_first([splitNCigarReads.bamIndex])
                        else bamFile.index,
                    recalibrationReport = gatherBqsr.outputBQSRreport,
                    outputBamPath = if splitSplicedReads
                        then scatterDir + "/" + basename(bed) + ".split.bqsr.bam"
                        else scatterDir + "/" + basename(bed) + ".bqsr.bam",
                    dockerImage = dockerImages["gatk4"]
            }
        }
    }

    # If splitSplicedReads a is true a new bam file should be made even if
    # ouputRecalibratedBam is false.
    if (outputRecalibratedBam || splitSplicedReads) {
        call picard.GatherBamFiles as gatherBamFiles {
            input:
                inputBams = if outputRecalibratedBam
                    then select_all(applyBqsr.recalibratedBam)
                    else select_all(splitNCigarReads.bam),
                inputBamsIndex = if outputRecalibratedBam
                    then select_all(applyBqsr.recalibratedBamIndex)
                    else select_all(splitNCigarReads.bamIndex),
                outputBamPath = outputDir + "/" + bamName + ".bam",
                dockerImage = dockerImages["picard"]
        }

        IndexedBamFile gatheredBam = object {
            file: gatherBamFiles.outputBam,
            index: gatherBamFiles.outputBamIndex,
            md5sum: gatherBamFiles.outputBamMd5
        }
    }

    output {
        IndexedBamFile? outputBamFile = gatheredBam
        File BQSRreport = gatherBqsr.outputBQSRreport
    }
}
