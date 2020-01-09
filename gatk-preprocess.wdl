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
          "picard":"quay.io/biocontainers/picard:2.20.5--0",
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

    parameter_meta {
        bamFile: {description: "The BAM file which should be processed and its index.",
                  category: "required"}
        bamName: {description: "The basename for the produced BAM files. This should not include any parent direcoties, use `outputDir` if the output directory should be changed.",
                  category: "common"}
        outputDir: {description: "The directory to which the outputs will be written.", category: "common"}
        reference: {description: "The reference files: a fasta, its index and sequence dictionary.", category: "required"}
        splitSplicedReads: {description: "Whether or not gatk's SplitNCgarReads should be run to split spliced reads. This should be enabled for RNAseq samples.",
                            category: "common"}
        outputRecalibratedBam: {description: "Whether or not a base quality score recalibrated BAM file will be outputed.",
                                category: "advanced"}
        dbsnpVCF: {description: "A dbSNP vcf and its index.", category: "required"}

        scatterSize: {description: "The size of the scattered regions in bases. Scattering is used to speed up certain processes. The genome will be sseperated into multiple chunks (scatters) which will be processed in their own job, allowing for parallel processing. Higher values will result in a lower number of jobs. The optimal value here will depend on the available resources.",
                      category: "advanced"}
        regions: {description: "A bed file describing the regions to operate on.", category: "common"}
        dockerImages: {description: "The docker images used. Changing this may result in errors which the developers may choose not to address.",
                       category: "advanced"}
    }
}
