---
layout: default
title: Home
version: v0.1
latest: true
---

This workflow performs preprocessing steps required for variantcalling based
on the
[GATK Best Practices](https://software.broadinstitute.org/gatk/best-practices/).
This workflow can be used for both DNA data and RNA-seq data.

This workflow is part of [BioWDL](https://biowdl.github.io/)
developed by [the SASC team](http://sasc.lumc.nl/).

## Usage
This workflow can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```bash
java -jar cromwell-<version>.jar run -i inputs.json gatk-preprocess.wdl
```

### Inputs
Inputs are provided through a JSON file. The minimally required inputs are
described below and a template containing all possible inputs can be generated
using Womtool as described in the
[WOMtool documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/). See
[this page](/inputs.html) for some additional general notes and information
about pipeline inputs.

```json
{
  "GatkPreprocess.reference": {
    "fasta": "A path to a reference fasta",
    "fai": "The path to the index associated with the reference fasta",
    "dict": "The path to the dict file associated with the reference fasta"
  },
  "GatkPreprocess.basePath": "The base bath (prefix) for the output. The final output will be <basePath>.bam or <basePath>.bqsr",
  "GatkPreprocess.dbsnpVCF": {
    "file": "A path to a dbSNP VCF file",
    "index": "The path to the index (.tbi) file associated with the dbSNP VCF"
  },
  "GatkPreprocess.bamFile": {
    "file": "The path to an input BAM file",
    "index":"The path to the index for the input BAM file"
  }
}
```

Some additional inputs that may be of interest are:
```json
{
  "GatkPreprocess.scatterSize": "The size of scatter regions (see explanation of scattering below), defaults to 10,000,000",
  "GatkPreprocess.outputRecalibratedBam": "Whether or not a recalibrated BAM file should be outputted, defaults to false",
  "GatkPreprocess.splitSplicedReads": "Whether or not SplitNCigarReads should be executed (recommended for RNA-seq data), defaults to false",
  "GatkPreprocess.scatterList.regions": "A bed file for which preprocessing will be performed"
}

```

#### Example
```json
{
  "GatkPreprocess.reference": {
    "fasta": "/home/user/genomes/human/GRCh38.fasta",
    "fai": "/home/user/genomes/human/GRCh38.fasta.fai",
    "dict": "/home/user/genomes/human/GRCh38.dict"
  },
  "GatkPreprocess.basePath": "/home/user/mapping/results/s1_preprocessed",
  "GatkPreprocess.dbsnpVCF": {
    "file": "/home/user/genomes/human/dbsnp/dbsnp-151.vcf.gz",
    "index": "/home/user/genomes/human/dbsnp/dbsnp-151.vcf.gz.tbi"
  },
  "GatkPreprocess.bamFile": {
    "file": "/home/user/mapping/results/s1.bam",
    "index":"/home/user/mapping/results/s1.bai"
  },
  "GatkPreprocess.splitSplicedReads": true,
  "GatkPreprocess.outputRecalibratedBam": true
}
```

### Dependency requirements and tool versions
Included in the repository is an `environment.yml` file. This file includes
all the tool version on which the workflow was tested. You can use conda and
this file to create an environment with all the correct tools.

### Output
This workflow will produce a BQSR report named according to the `basePath`
input (basePath + '.bqsr'). If one of the `splitSplicedReads` or
`outputRecalibratedBam` inputs is set to true, a new BAM file (basePath +
'.bam') will be produced as well.

## Scattering
This pipeline performs scattering to speed up analysis on grid computing
clusters. This is done by splitting the reference genome into regions of
roughly equal size (see the `scatterSize` input). Each of these regions will
be analyzed in separate jobs, allowing them to be processed in parallel.

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question about running this workflow and feature requests, please use
the
<a href='https://github.com/biowdl/gatk-preprocess/issues'>github issue tracker</a>
or contact
<a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
