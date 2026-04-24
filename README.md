# Overview

The purpose of this repos is to give an example of using [nf-core](https://nf-co.re/) pipelines to easily conduct reproducible analysis rather than to discuss that analysis and the rationale behind it. 

Still, this can also serve as a genome assembly tutorial.

And, I'd strongly encourage anyone who uses this repos to check out the repositories for the two pipelines used in it
* [bacass](https://github.com/nf-core/bacass)
* [genomeqc](https://github.com/nf-core/genomeqc/tree/dev)

__Important__ If you are using Windows please use Ubuntu through WSL


# Tutorial

## Install Software

### Install Conda (if needed)

Conda is a program manager, so it makes it easier for us to install other software that we'll need.
- Singularity or Docker are generally preferred as alternative methods of fetching programs, but they tend to be harder to install

1. Check if conda is installed 
`conda --version`
- If that command gives an error, follow the instructions [here](https://www.anaconda.com/docs/getting-started/miniconda/install/overview) to install Miniconda3 and run the below commands after `conda --version` can be executed without error
- These `conda tos accept` commands ensure the programs can be downloaded from where they are hosted (channels)

```
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
```


### Create Conda Environments
<!-- These will be switch from local ymls to refer to the GitHub repos later -->

Using multiple environments ensures each program is able to be installed properly with all needed dependencies.

Essentially, it's the equivalent of installing different Microsoft programs thru a single installer

2. Install environment for downloading raw data
- _Note_: Make sure the `base` environment is active when you install libmamba
```
conda install -y -c conda-forge conda-libmamba-solver=26.3.0
conda config --set solver libmamba

conda env create --name sra-tools -f sra-tools.yml
```

3. Install environment for downloading reference assemblies
`conda env create --name ncbi-datasets -f ncbi-datasets.yml`

4. Install environment for pulling nf-core pipelines
`conda env create --name nf-core -f nf-core.yml`


## Download NF-Core Pipelines

<!--JC note, one of us should really submit an issue for the QUAST versions warning problem -->

5. Download `bacass`
- _Note_: Choose "none" for both downloading container images and compression type
  - Using Docker or Singularity images instead of conda environments when running nf-core pipelines is generally preferred for ensuring everything matches between runs, but this tutorial assumes the user only has conda installed
  - Since we'll be using the pipelines immediately and they're reasonably small, there's not much reason to download in a compressed form

```
conda activate nf-core

nf-core pipelines download bacass -r 2.5.0

# Fix quast versions issue
sed -i 's/2>\&1/\| grep -v WARNING/' nf-core-bacass_2.5.0/2_5_0/modules/nf-core/quast/main.nf 
```

6. Download `genomeqc`
```
nf-core pipelines download genomeqc -r 787a0e6

conda deactivate
```


## Assemble and Annotate Data

### Download test data

7. Download raw _Haemophilus influenzae_ sequencing data to a `raw_data` subfolder
-_Note_: The total size of the downloaded raw data files is around 58 MB and may take a minute or two to download

Move into the folder for bacass
```
# Move into the folder for bacass
cd nf-core-bacass_2.5.0/2_5_0

```

Download fastq files
```
conda activate sra-tools

mkdir raw_data

fastq-dump --split-files --origfmt --gzip SRR37975260 --outdir raw_data

conda deactivate
```

8. Download _H. influenzae_ reference genome and decompress the resulting zip
-_Note_: Don't forget to deactivate the `sra-tools` environment before proceeding with the next step
  - Generally, you don't actually need to deactive an environment before activating another, but doing so prevents weird edge-cases where paths or dependencies could conflict
```
conda activate ncbi-datasets

datasets download genome accession GCF_020736045.1 --include genome,gff3

unzip ncbi_dataset.zip -d h_influenzae_reference
```

9. Download Kraken database for tutorial
<!--JC note, url is placeholder. UPDATE, once it's on main -->
```
wget https://github.com/jcbioinformatics/SomeAssemblyRequired/blob/dev/TUTORIAL_dbs/TUTORIAL_k2_db.tar.gz
```


### Expected 2_5_0 Directory Structure

<img width="214" height="475" alt="image" src="https://github.com/user-attachments/assets/924c682e-9e7b-4b45-a8db-f47bc4707436" />


### Contents of raw_data

<img width="208" height="46" alt="image" src="https://github.com/user-attachments/assets/fb7ed016-5128-4ddd-bce3-affa4c9d16f4" />


### Contents of h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1

<img width="371" height="41" alt="image" src="https://github.com/user-attachments/assets/08935ce3-921a-4c3e-88a5-f785a7856c38" />


### Run

9. Run `bacass`

_Note_ The first run will take a while due to the conda environments needing to be created

<!--JC note, Sample sheet will be switch to a GitHub url too, but for now, it should be in the 2_5_0 folder too -->
<!--JC note, Need to make a note of lowering request resources in conf/base.config -->
<!--JC note, Need make note about running export command before each nextflow run -->

```
conda activate nf-core

# Set folder path to use for conda envs
# Prevents them from being redownloaded
export NXF_CONDA_CACHEDIR=~/conda_nf

nextflow run main.nf \
  -profile conda \
  --input sample_sheet_bacass_tutorial.txt \
  --assembly_type 'short' \
  --kraken2db $PWD/TUTORIAL_k2_db.tar.gz \
  --reference_fasta $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/GCF_020736045.1_ASM2073604v1_genomic.fna \
  --reference_gff $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/genomic.gff \
  --skip_kmerfinder \
  --outdir results_bacass_TUTORIAL 
```

### CLI Parameter Descriptions

All config descriptions and their help text can be viewed [here](https://github.com/nf-core/bacass/blob/master/nextflow_schema.json)

* -profile - Refers to a group of predefined options in `nextflow.config`.  
* --input - Path to a sample sheet giving locations of input data. See [usage.md](https://github.com/nf-core/bacass/blob/master/docs/usage.md#samplesheet)
* --assembly-type - Type of sequence data
* --kraken2db - Path to Kraken2 database to assess sample purity
* --reference_fasta - If desired, you can pass a path to a reference genome in fasta format to compare your resulting assembly against
* --reference_gff - If desired, you can pass a path to a gff file containing annotations for a reference genome for comparison
* --skip_kmerfinder - Skip kmerfinder purity assessment
* --outdir - Path to folder to receive all outputs from the pipeline


### Key Outputs

See bacass's documentation [here](https://github.com/nf-core/bacass/blob/master/docs/output.md) for more details

- results_bacass_TUTORIAL/FastQC/raw/H_influenzae_*_fastqc.html - Raw data quality
  - [More Info](https://mugenomicscore.missouri.edu/PDF/FastQC_Manual.pdf)
- results_bacass_TUTORIAL/multiqc/multiqc_report.html - Pipeline summary
  - Program report outputs
  - All program versions (`Software Versions`)
  - Parameters that differ from the defaults (`nf-core/bacass Workflow Summary`)
  - [Additional MultiQC Info](https://github.com/MultiQC/MultiQC)
- results_bacass_TUTORIAL/Prokka/H_influenzae/H_influenzae.tsv - Assembly feature annotations
  - [More Info](https://github.com/tseemann/prokka#output-files)
- results_bacass_TUTORIAL/QUAST/report/report.html - Assembly QC
  - [More Info](https://quast.sourceforge.net/docs/manual.html#sec3)
- results_bacass_TUTORIAL/Unicycler/H_influenzae.scaffolds.fa.gz - Assembly sequences
  - [More Info](https://github.com/rrwick/unicycler#output-files)
  - [Terminology Info](https://mycocosm.jgi.doe.gov/help/scaffolds.jsf)


## Decontaminate and Evaluate Assembly

10. Move into the `nf-core-genomeqc_787a0e6/787a0e6` folder

If you're command line is currently in the `2_5_0` subfolder, you can use the below command

`../../nf-core-genomeqc_787a0e6/787a0e6`

<!--JC note, strike this download if test manifest works -->

11. Download the FCS-GX test database

FCS-GX is used to identify _and_ remove contaminants from the assembly

`curl -LO https://zenodo.org/records/10932013/files/FCS_combo_test.fa`

<!--JC note, the samplesheet will point to a GitHub url once this repos is public -->

12. Run genomeqc

You may need to lower the requested RAM and cpus in `conf/base.config`

<!--JC note, Need to make a branch with my edits to nextflow.config, nextflow.schema, and subworkflows/decontamination.nf -->

```
# Set folder path to use for conda envs
# Prevents them from being redownloaded
export NXF_CONDA_CACHEDIR=~/conda_nf

nextflow run main.nf \
  -profile conda \
  --input $PWD/sample_sheet_genomeqc_tutorial.csv \
  --gxdb_manifiest https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/database/test-only/test-only.manifest \
  --skip_fcs_adaptor \
  --outdir results_genomeqc_TUTORIAL


```

# Comprehension Exercises

* How does nf-core address some common pitfalls of reproducibility? 
- _Hint_: Check the `multiqc` subfolder within the output folder

* Why do we use yml files for creating conda environments?
- _Hint_: Think about what they specify

* Find the SRA run that we downloaded to use at test data
- _Hint_: Go to https://www.ncbi.nlm.nih.gov/search/

* Find the genome we used as the reference
- _Hint_: Go to https://www.ncbi.nlm.nih.gov/datasets/

* Is there any overlap between `bacass` and `genomeqc`? 
- What programs do both run? 
- Why would you still want to run `genomeqc`
- _Hint_: Look at the workflow diagrams on their GitHubs and think back to what database we downloaded for testing
  * [bacass](https://github.com/nf-core/bacass)
  * [genomeqc](https://github.com/nf-core/genomeqc/tree/dev)
