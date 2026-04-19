# Overview

The purpose of this repos is to give an example of using [nf-core](https://nf-co.re/) pipelines to easily conduct reproducible analysis rather than to discuss that analysis and the rationale behind it. 

Still, this can also serve as a genome assembly tutorial.

And, I'd strongly encourage anyone who uses this repos to check out the repositories for the two pipelines used in it
* [bacass](https://github.com/nf-core/bacass)
* [genomeqc](https://github.com/nf-core/genomeqc/tree/dev)

__Important__ This tutorial assumes you are running a Unix operating system, like any MacOS, any Linux OS, or WSL
- It _should_ mostly be identical on a Windows device with command prompt, but `$PWD` for running the pipelines should be `%CD%`


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
  --input sample_sheet_tutorial.txt \
  --assembly_type 'short' \
  --kraken2db $PWD/TUTORIAL_k2_db.tar.gz \
  --reference_fasta $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/GCF_020736045.1_ASM2073604v1_genomic.fna \
  --reference_gff $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/genomic.gff \
  --skip_kmerfinder \
  --outdir results_TUTORIAL 
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
