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
        File? regions
        Map[String, String] dockerImages = {
          "picard":"quay.io/biocontainers/picard:2.18.26--0",
          "gatk4":"quay.io/biocontainers/gatk4:4.1.0.0--0",
          "biopet-scatterregions":"quay.io/biocontainers/biopet-scatterregions:0.2--0"
        }
    }


    call gatk.BaseRecalibrator as baseRecalibrator {
        input:
            referenceFasta = reference.fasta,
            referenceFastaFai = reference.fai,
            referenceFastaDict = reference.dict,
            inputBam = bamFile.file,
            inputBamIndex = bamFile.index,
            recalibrationReportPath = outputDir + "/" + bamName + ".bqsr",
            dbsnpVCF = dbsnpVCF.file,
            dbsnpVCFIndex = dbsnpVCF.index,
            dockerImage = dockerImages["gatk4"]
    }


    if (splitSplicedReads) {
        call gatk.SplitNCigarReads as splitNCigarReads {
            input:
                referenceFasta = reference.fasta,
                referenceFastaFai = reference.fai,
                referenceFastaDict = reference.dict,
                inputBam = bamFile.file,
                inputBamIndex = bamFile.index,
                outputBam = outputDir + "/" + bamName + ".split.bam",
                dockerImage = dockerImages["gatk4"]
        }
         IndexedBamFile splitNCigarBam = object {
            file: splitNCigarReads.bam,
            index: splitNCigarReads.bamIndex
        }
    }

    if (outputRecalibratedBam) {
        call gatk.ApplyBQSR as applyBqsr {
            input:
                referenceFasta = reference.fasta,
                referenceFastaFai = reference.fai,
                referenceFastaDict = reference.dict,
                inputBam = if splitSplicedReads
                    then select_first([splitNCigarReads.bam])
                    else bamFile.file,
                inputBamIndex = if splitSplicedReads
                    then select_first([splitNCigarReads.bamIndex])
                    else bamFile.index,
                recalibrationReport = baseRecalibrator.recalibrationReport,
                outputBamPath = if splitSplicedReads
                    then outputDir + "/" + bamName + ".split.bqsr.bam"
                    else outputDir + "/" + bamName + ".bqsr.bam",
                dockerImage = dockerImages["gatk4"]
        }

         IndexedBamFile recalibratedBam = object {
            file: applyBqsr.recalibratedBam,
            index: applyBqsr.recalibratedBamIndex,
            md5: applyBqsr.recalibratedBamMd5
        }
    }


    output {
        IndexedBamFile? outputBamFile = if outputRecalibratedBam then recalibratedBam else splitNCigarBam
        File BQSRreport = baseRecalibrator.recalibrationReport
    }
}
