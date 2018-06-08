import "tasks/gatk.wdl" as gatk
import "tasks/biopet.wdl" as biopet
import "tasks/picard.wdl" as picard

workflow GatkPreprocess {
    File bamFile
    File bamIndex
    String outputBamPath
    File refFasta
    File refDict
    File refFastaIndex
    Boolean? splitSplicedReads

    String scatterDir = sub(outputBamPath, basename(outputBamPath), "/scatter/")

    call biopet.ScatterRegions as scatterList {
        input:
            ref_fasta = refFasta,
            ref_dict = refDict,
            outputDirPath = scatterDir
    }

    scatter (bed in scatterList.scatters) {
           call gatk.BaseRecalibrator as baseRecalibrator {
            input:
                sequence_group_interval = [bed],
                ref_fasta = refFasta,
                ref_dict = refDict,
                ref_fasta_index = refFastaIndex,
                input_bam = bamFile,
                input_bam_index = bamIndex,
                recalibration_report_filename = scatterDir + "/" + basename(bed) + ".bqsr"
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            input_bqsr_reports = baseRecalibrator.recalibration_report,
            output_report_filepath = sub(bamFile, ".bam$", ".bqsr")
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
                sequence_group_interval = [bed],
                ref_fasta = refFasta,
                ref_dict = refDict,
                ref_fasta_index = refFastaIndex,
                input_bam = if splitSplicedReads2
                    then select_first([splitNCigarReads.bam])
                    else bamFile,
                recalibration_report = gatherBqsr.output_bqsr_report,
                output_bam_path = scatterDir + "/" + basename(bed) + ".bqsr.bam"
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