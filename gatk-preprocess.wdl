version 1.0

# Copyright (c) 2018 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import "tasks/biopet/biopet.wdl" as biopet
import "tasks/gatk.wdl" as gatk
import "tasks/picard.wdl" as picard

workflow GatkPreprocess {
    input{
        File bam
        File bamIndex
        String bamName = "recalibrated"
        String outputDir = "."
        File referenceFasta
        File referenceFastaFai
        File referenceFastaDict
        Boolean splitSplicedReads = false
        File dbsnpVCF
        File dbsnpVCFIndex
        # Added scatterSizeMillions to overcome Json max int limit
        Int scatterSizeMillions = 1000
        # Scatter size is based on bases in the reference genome. The human genome is approx 3 billion base pairs
        # With a scatter size of 1 billion this will lead to ~3 scatters.
        Int scatterSize = scatterSizeMillions * 1000000
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
            referenceFasta = referenceFasta,
            referenceFastaDict = referenceFastaDict,
            scatterSize = scatterSize,
            notSplitContigs = true,
            regions = regions,
            dockerImage = dockerImages["biopet-scatterregions"]
    }

    scatter (bed in scatterList.scatters) {

        if (splitSplicedReads) {
            call gatk.SplitNCigarReads as splitNCigarReads {
                input:
                    intervals = [bed],
                    referenceFasta = referenceFasta,
                    referenceFastaFai = referenceFastaFai,
                    referenceFastaDict = referenceFastaDict,
                    inputBam = bam,
                    inputBamIndex = bamIndex,
                    outputBam = scatterDir + "/" + basename(bed) + ".split.bam",
                    dockerImage = dockerImages["gatk4"]
            }
        }

        call gatk.BaseRecalibrator as baseRecalibrator {
            input:
                sequenceGroupInterval = [bed],
                referenceFasta = referenceFasta,
                referenceFastaFai = referenceFastaFai,
                referenceFastaDict = referenceFastaDict,
                inputBam = select_first([splitNCigarReads.bam, bam]),
                inputBamIndex = select_first([splitNCigarReads.bamIndex, bamIndex]),
                recalibrationReportPath = scatterDir + "/" + basename(bed) + ".bqsr",
                dbsnpVCF = dbsnpVCF,
                dbsnpVCFIndex = dbsnpVCFIndex,
                dockerImage = dockerImages["gatk4"]
        }
    }

    call gatk.GatherBqsrReports as gatherBqsr {
        input:
            inputBQSRreports = baseRecalibrator.recalibrationReport,
            outputReportPath = outputDir + "/" + bamName + ".bqsr",
            dockerImage = dockerImages["gatk4"]
    }

    scatter (index in range(length(scatterList.scatters))) {
        call gatk.ApplyBQSR as applyBqsr {
            input:
                sequenceGroupInterval = [scatterList.scatters[index]],
                referenceFasta = referenceFasta,
                referenceFastaFai = referenceFastaFai,
                referenceFastaDict = referenceFastaDict,
                inputBam = select_first([splitNCigarReads.bam[index], bam]),
                inputBamIndex = select_first([splitNCigarReads.bamIndex[index], bamIndex]),
                recalibrationReport = gatherBqsr.outputBQSRreport,
                outputBamPath = if splitSplicedReads
                    then scatterDir + "/" + basename(scatterList.scatters[index]) + ".split.bqsr.bam"
                    else scatterDir + "/" + basename(scatterList.scatters[index]) + ".bqsr.bam",
                dockerImage = dockerImages["gatk4"]
        }
    }


    call picard.GatherBamFiles as gatherBamFiles {
        input:
            inputBams = applyBqsr.recalibratedBam,
            inputBamsIndex = applyBqsr.recalibratedBamIndex,
            outputBamPath = outputDir + "/" + bamName + ".bam",
            dockerImage = dockerImages["picard"]
    }

    output {
        File recalibratedBam = gatherBamFiles.outputBam
        File recalibratedBamIndex = gatherBamFiles.outputBamIndex
        File BQSRreport = gatherBqsr.outputBQSRreport
    }

    parameter_meta {
        bam: {description: "The BAM file which should be processed", category: "required"}
        bamIndex: {description: "The index for the BAM file", category: "required"}
        bamName: {description: "The basename for the produced BAM files. This should not include any parent direcoties, use `outputDir` if the output directory should be changed.",
                  category: "common"}
        outputDir: {description: "The directory to which the outputs will be written.", category: "common"}
        referenceFasta: {description: "The reference fasta file", category: "required"}
        referenceFastaFai: {description: "Fasta index (.fai) for the reference fasta file", category: "required"}
        referenceFastaDict: {description: "Sequence dictionary (.dict) for the reference fasta file", category: "required"}
        splitSplicedReads: {description: "Whether or not gatk's SplitNCgarReads should be run to split spliced reads. This should be enabled for RNAseq samples.",
                            category: "common"}
        dbsnpVCF: {description: "A dbSNP vcf.", category: "required"}
        dbsnpVCFIndex: {description: "Index for dbSNP vcf.", category: "required"}

        scatterSize: {description: "The size of the scattered regions in bases. Scattering is used to speed up certain processes. The genome will be sseperated into multiple chunks (scatters) which will be processed in their own job, allowing for parallel processing. Higher values will result in a lower number of jobs. The optimal value here will depend on the available resources.",
                      category: "advanced"}
        scatterSizeMillions:{ description: "Same as scatterSize, but is multiplied by 1000000 to get scatterSize. This allows for setting larger values more easily",
                      category: "advanced"}
        regions: {description: "A bed file describing the regions to operate on.", category: "common"}
        dockerImages: {description: "The docker images used. Changing this may result in errors which the developers may choose not to address.",
                       category: "advanced"}
    }
}
