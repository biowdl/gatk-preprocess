import "tasks/gatk.wdl" as gatk
import "tasks/biopet.wdl" as biopet
import "tasks/picard.wdl" as picard

workflow BaseRecalibration {
    File bamFile
    File bamIndex
    String outputBamPath
    File ref_fasta
    File ref_dict
    File ref_fasta_index
    Boolean? splitSplicedReads

    call biopet.ScatterRegions as scatterList {
        input:
            ref_fasta = ref_fasta,
            ref_dict = ref_dict,
            outputDirPath = "."
    }

    scatter (bed in scatterList.scatters) {
        if (splitSplicedReads) {
            call gatk.SplitNCigarReads as splitNCigarReads{
                input:
                    intervals = [bed],
                    ref_fasta = ref_fasta,
                    ref_dict = ref_dict,
                    ref_fasta_index = ref_fasta_index,
                    input_bam = bamFile,
                    output_bam = sub(basename(bamFile), ".bam$", "." + basename(bed) + ".bam")
            }
        }

        call gatk.BaseRecalibrator as baseRecalibrator {
            input:
                sequence_group_interval = [bed],
                ref_fasta = ref_fasta,
                ref_dict = ref_dict,
                ref_fasta_index = ref_fasta_index,
                input_bam = if splitSplicedReads then splitNCigarReads.bam else bamFile,
                input_bam_index = if splitSplicedReads then splitNCigarReads.bam_index else bamIndex,
                recalibration_report_filename = sub(basename(bamFile), ".bam$", ".bqsr")
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            input_bqsr_reports = baseRecalibrator.recalibration_report,
            output_report_filepath = sub(bamFile, ".bam$", ".bqsr")
    }

    scatter (bed in scatterList.scatters) {
        call gatk.ApplyBQSR as applyBqsr {
            input:
                sequence_group_interval = [bed],
                ref_fasta = ref_fasta,
                ref_dict = ref_dict,
                ref_fasta_index = ref_fasta_index,
                input_bam = bamFile,
                recalibration_report = gatherBqsr.output_bqsr_report,
                output_bam_path = sub(basename(bamFile), ".bam$", ".bqsr.bam")
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