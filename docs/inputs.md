---
layout: default
title: "Inputs: GatkPreprocess"
---

# Inputs for GatkPreprocess

The following is an overview of all available inputs in
GatkPreprocess.


## Required inputs
<dl>
<dt id="GatkPreprocess.bam"><a href="#GatkPreprocess.bam">GatkPreprocess.bam</a></dt>
<dd>
    <i>File </i><br />
    The BAM file which should be processed
</dd>
<dt id="GatkPreprocess.bamIndex"><a href="#GatkPreprocess.bamIndex">GatkPreprocess.bamIndex</a></dt>
<dd>
    <i>File </i><br />
    The index for the BAM file
</dd>
<dt id="GatkPreprocess.dbsnpVCF"><a href="#GatkPreprocess.dbsnpVCF">GatkPreprocess.dbsnpVCF</a></dt>
<dd>
    <i>File </i><br />
    A dbSNP vcf.
</dd>
<dt id="GatkPreprocess.dbsnpVCFIndex"><a href="#GatkPreprocess.dbsnpVCFIndex">GatkPreprocess.dbsnpVCFIndex</a></dt>
<dd>
    <i>File </i><br />
    Index for dbSNP vcf.
</dd>
<dt id="GatkPreprocess.referenceFasta"><a href="#GatkPreprocess.referenceFasta">GatkPreprocess.referenceFasta</a></dt>
<dd>
    <i>File </i><br />
    The reference fasta file
</dd>
<dt id="GatkPreprocess.referenceFastaDict"><a href="#GatkPreprocess.referenceFastaDict">GatkPreprocess.referenceFastaDict</a></dt>
<dd>
    <i>File </i><br />
    Sequence dictionary (.dict) for the reference fasta file
</dd>
<dt id="GatkPreprocess.referenceFastaFai"><a href="#GatkPreprocess.referenceFastaFai">GatkPreprocess.referenceFastaFai</a></dt>
<dd>
    <i>File </i><br />
    Fasta index (.fai) for the reference fasta file
</dd>
</dl>

## Other common inputs
<dl>
<dt id="GatkPreprocess.bamName"><a href="#GatkPreprocess.bamName">GatkPreprocess.bamName</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"recalibrated"</code><br />
    The basename for the produced BAM files. This should not include any parent direcoties, use `outputDir` if the output directory should be changed.
</dd>
<dt id="GatkPreprocess.outputDir"><a href="#GatkPreprocess.outputDir">GatkPreprocess.outputDir</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"."</code><br />
    The directory to which the outputs will be written.
</dd>
<dt id="GatkPreprocess.regions"><a href="#GatkPreprocess.regions">GatkPreprocess.regions</a></dt>
<dd>
    <i>File? </i><br />
    A bed file describing the regions to operate on.
</dd>
<dt id="GatkPreprocess.splitSplicedReads"><a href="#GatkPreprocess.splitSplicedReads">GatkPreprocess.splitSplicedReads</a></dt>
<dd>
    <i>Boolean </i><i>&mdash; Default:</i> <code>false</code><br />
    Whether or not gatk's SplitNCgarReads should be run to split spliced reads. This should be enabled for RNAseq samples.
</dd>
</dl>

## Advanced inputs
<details>
<summary> Show/Hide </summary>
<dl>
<dt id="GatkPreprocess.applyBqsr.javaXmx"><a href="#GatkPreprocess.applyBqsr.javaXmx">GatkPreprocess.applyBqsr.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"4G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.applyBqsr.memory"><a href="#GatkPreprocess.applyBqsr.memory">GatkPreprocess.applyBqsr.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"12G"</code><br />
    The amount of memory this job will use.
</dd>
<dt id="GatkPreprocess.baseRecalibrator.javaXmx"><a href="#GatkPreprocess.baseRecalibrator.javaXmx">GatkPreprocess.baseRecalibrator.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"4G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFIndexes"><a href="#GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFIndexes">GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFIndexes</a></dt>
<dd>
    <i>Array[File] </i><i>&mdash; Default:</i> <code>[]</code><br />
    The indexed for the known variant VCFs.
</dd>
<dt id="GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFs"><a href="#GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFs">GatkPreprocess.baseRecalibrator.knownIndelsSitesVCFs</a></dt>
<dd>
    <i>Array[File] </i><i>&mdash; Default:</i> <code>[]</code><br />
    VCF files with known indels.
</dd>
<dt id="GatkPreprocess.baseRecalibrator.memory"><a href="#GatkPreprocess.baseRecalibrator.memory">GatkPreprocess.baseRecalibrator.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"12G"</code><br />
    The amount of memory this job will use.
</dd>
<dt id="GatkPreprocess.dockerImages"><a href="#GatkPreprocess.dockerImages">GatkPreprocess.dockerImages</a></dt>
<dd>
    <i>Map[String,String] </i><i>&mdash; Default:</i> <code>{"picard": "quay.io/biocontainers/picard:2.20.5--0", "gatk4": "quay.io/biocontainers/gatk4:4.1.0.0--0", "biopet-scatterregions": "quay.io/biocontainers/biopet-scatterregions:0.2--0"}</code><br />
    The docker images used. Changing this may result in errors which the developers may choose not to address.
</dd>
<dt id="GatkPreprocess.gatherBamFiles.javaXmx"><a href="#GatkPreprocess.gatherBamFiles.javaXmx">GatkPreprocess.gatherBamFiles.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"4G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.gatherBamFiles.memory"><a href="#GatkPreprocess.gatherBamFiles.memory">GatkPreprocess.gatherBamFiles.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"12G"</code><br />
    The amount of memory this job will use.
</dd>
<dt id="GatkPreprocess.gatherBqsr.javaXmx"><a href="#GatkPreprocess.gatherBqsr.javaXmx">GatkPreprocess.gatherBqsr.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"4G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.gatherBqsr.memory"><a href="#GatkPreprocess.gatherBqsr.memory">GatkPreprocess.gatherBqsr.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"12G"</code><br />
    The amount of memory this job will use.
</dd>
<dt id="GatkPreprocess.scatterList.bamFile"><a href="#GatkPreprocess.scatterList.bamFile">GatkPreprocess.scatterList.bamFile</a></dt>
<dd>
    <i>File? </i><br />
    Equivalent to biopet scatterregions' `--bamfile` option.
</dd>
<dt id="GatkPreprocess.scatterList.bamIndex"><a href="#GatkPreprocess.scatterList.bamIndex">GatkPreprocess.scatterList.bamIndex</a></dt>
<dd>
    <i>File? </i><br />
    The index for the bamfile given through bamFile.
</dd>
<dt id="GatkPreprocess.scatterList.javaXmx"><a href="#GatkPreprocess.scatterList.javaXmx">GatkPreprocess.scatterList.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"8G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.scatterList.memory"><a href="#GatkPreprocess.scatterList.memory">GatkPreprocess.scatterList.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"24G"</code><br />
    The amount of memory this job will use.
</dd>
<dt id="GatkPreprocess.scatterSize"><a href="#GatkPreprocess.scatterSize">GatkPreprocess.scatterSize</a></dt>
<dd>
    <i>Int </i><i>&mdash; Default:</i> <code>scatterSizeMillions * 1000000</code><br />
    The size of the scattered regions in bases. Scattering is used to speed up certain processes. The genome will be sseperated into multiple chunks (scatters) which will be processed in their own job, allowing for parallel processing. Higher values will result in a lower number of jobs. The optimal value here will depend on the available resources.
</dd>
<dt id="GatkPreprocess.scatterSizeMillions"><a href="#GatkPreprocess.scatterSizeMillions">GatkPreprocess.scatterSizeMillions</a></dt>
<dd>
    <i>Int </i><i>&mdash; Default:</i> <code>1000</code><br />
    Same as scatterSize, but is multiplied by 1000000 to get scatterSize. This allows for setting larger values more easily
</dd>
<dt id="GatkPreprocess.splitNCigarReads.javaXmx"><a href="#GatkPreprocess.splitNCigarReads.javaXmx">GatkPreprocess.splitNCigarReads.javaXmx</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"4G"</code><br />
    The maximum memory available to the program. Should be lower than `memory` to accommodate JVM overhead.
</dd>
<dt id="GatkPreprocess.splitNCigarReads.memory"><a href="#GatkPreprocess.splitNCigarReads.memory">GatkPreprocess.splitNCigarReads.memory</a></dt>
<dd>
    <i>String </i><i>&mdash; Default:</i> <code>"16G"</code><br />
    The amount of memory this job will use.
</dd>
</dl>
</details>




