import "tasks/biopet.wdl" as biopet
import "tasks/gatk.wdl" as gatk
import "tasks/picard.wdl" as picard

workflow GatkPreprocess {
    File bamFile
    File bamIndex
    String outputBamPath
    File refFasta
    File refDict
    File refFastaIndex
    Boolean? splitSplicedReads

    String outputDir = sub(outputBamPath, basename(outputBamPath), "")
    String scatterDir = outputDir +  "/scatter/"

    call biopet.ScatterRegions as scatterList {
        input:
            ref_fasta = refFasta,
            ref_dict = refDict,
            outputDirPath = scatterDir
    }

    scatter (bed in scatterList.scatters) {
        call gatk.BaseRecalibrator as baseRecalibrator {
            input:
                sequenceGroupInterval = [bed],
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex,
                inputBam = bamFile,
                inputBamIndex = bamIndex,
                recalibrationReportPath = scatterDir + "/" + basename(bed) + ".bqsr"
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            inputBQSRreports = baseRecalibrator.recalibrationReport,
            outputReportPath = outputDir + "/" + sub(basename(bamFile), ".bam$", ".bqsr")
    }

    Boolean splitSplicedReads2 = select_first([splitSplicedReads, false])
    scatter (bed in scatterList.scatters) {
        if (splitSplicedReads2) {
            call gatk.SplitNCigarReads as splitNCigarReads {
                input:
                    intervals = [bed],
                    refFasta = refFasta,
                    refDict = refDict,
                    refFastaIndex = refFastaIndex,
                    inputBam = bamFile,
                    inputBamIndex= bamIndex,
                    outputBam = scatterDir + "/" + basename(bed) + ".split.bam"
            }
        }

        call gatk.ApplyBQSR as applyBqsr {
            input:
                sequenceGroupInterval = [bed],
                refFasta = refFasta,
                refDict = refDict,
                refFastaIndex = refFastaIndex,
                inputBam = if splitSplicedReads2
                    then select_first([splitNCigarReads.bam])
                    else bamFile,
                inputBamIndex = if splitSplicedReads2
                    then select_first([splitNCigarReads.bamIndex])
                    else bamIndex,
                recalibrationReport = gatherBqsr.outputBQSRreport,
                outputBamPath = scatterDir + "/" + basename(bed) + ".bqsr.bam"
        }
    }

    call picard.GatherBamFiles as gatherBamFiles {
        input:
            input_bams = applyBqsr.recalibrated_bam,
            output_bam_path = outputBamPath
    }

    output {
        File outputBamFile = gatherBamFiles.output_bam
        File outputBamIndex = gatherBamFiles.output_bam_index
    }
}