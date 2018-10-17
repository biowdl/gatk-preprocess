version 1.0

import "tasks/biopet/biopet.wdl" as biopet
import "tasks/gatk.wdl" as gatk
import "tasks/picard.wdl" as picard
import "tasks/common.wdl" as common

workflow GatkPreprocess {
    input{
        IndexedBamFile bamFile
        String outputBamPath
        Reference reference
        Boolean splitSplicedReads = false
        IndexedVcfFile dbsnpVCF
        Int scatterSize = 10000000
    }

    String outputDir = sub(outputBamPath, basename(outputBamPath), "")
    String scatterDir = outputDir +  "/scatter/"

    call biopet.ScatterRegions as scatterList {
        input:
            reference = reference,
            outputDirPath = scatterDir,
            scatterSize = scatterSize
    }

    # Glob messes with order of scatters (10 comes before 1), which causes problem at gatherBamFiles
    call biopet.ReorderGlobbedScatters as orderedScatters {
        input:
            scatters = scatterList.scatters,
            scatterDir = scatterDir
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
            outputReportPath = outputDir + "/" + sub(basename(bamFile.file), ".bam$", ".bqsr")
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
        }

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
        File chunkBamIndxes = applyBqsr.recalibratedBam.index
    }

    call picard.GatherBamFiles as gatherBamFiles {
        input:
            inputBams = chunkBamFiles,
            inputBamsIndex = chunkBamIndxes,
            outputBamPath = outputBamPath
    }

    output {
        IndexedBamFile outputBamFile = gatherBamFiles.outputBam
    }
}
