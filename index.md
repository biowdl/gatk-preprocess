---
layout: default
---

This workflow performs preprocessing steps required for variantcalling based
on the
[GATK Best Practices](https://software.broadinstitute.org/gatk/best-practices/).
This workflow can be used for either germline DNA data or RNA-seq data.

## Usage
`gatk-preprocess.wdl` can be run using
[Cromwell](http://cromwell.readthedocs.io/en/stable/):
```
java -jar cromwell-<version>.jar run -i inputs.json gatk-preprocess.wdl
```

The inputs JSON can be generated using WOMtools as described in the [WOMtools
documentation](http://cromwell.readthedocs.io/en/stable/WOMtool/).

The primary inputs are described below, additional inputs (such as precommands
and JAR paths) are available. Please use the above mentioned WOMtools command
to see all available inputs.

| field | type | |
|-|-|-|
| bamFile | `File` | The BAM file for which preprocessing will be performed. |
| bamIndex | `File` | The index associated with the input BAM file. |
| outputBamPath | `String` | The path for the output (preprocessed) BAM file. |
| refFasta | `File` | The fasta file for the reference genome used during mapping. |
| refDict | `File` | The dict file associated with the reference fasta. |
| refFastaIndex | `File` | The index associated with the reference fasta. |
| dbsnpVCF | `File` | The dbSNP VCF file to be used for preprocessing. |
| dbsnpVCFindex | `File` | The index associated with the input dbSNP VCF. |
| splitSplicedReads | `Boolean?` | Whether or not SplitNCigarReads should be run. This should be true for RNA-seq samples and false for DNA sample. |

>All inputs have to be preceded by with `GatkPreprocess.`.
Type is indicated according to the WDL data types: `File` should be indicators
of file location (a string in JSON). Types ending in `?` indicate the input is
optional, types ending in `+` indicate they require at least one element.

## Output
This workflow will produce a new BAM file on which preprocessing has been
performed.

## About
This workflow is part of [BioWDL](https://biowdl.github.io/)
developed by [the SASC team](http://sasc.lumc.nl/).

## Contact
<p>
  <!-- Obscure e-mail address for spammers -->
For any question related to gatk-preprocess, please use the
<a href='https://github.com/biowdl/gatk-preprocess/issues'>github issue tracker</a>
or contact
 <a href='http://sasc.lumc.nl/'>the SASC team</a> directly at: <a href='&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;'>
&#115;&#97;&#115;&#99;&#64;&#108;&#117;&#109;&#99;&#46;&#110;&#108;</a>.
</p>
