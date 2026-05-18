# Example Run Without Reference


## Downloaded Databases

Databasess
- [FCS-GX](https://github.com/ncbi/fcs/wiki/FCS-GX-quickstart) - decontamination w/ genomeqc
- [Kraken2](https://github.com/DerrickWood/kraken2/wiki/Manual) - genome purity assessment w/ bacass
```
conda activate fcs-gx

sync_files.py get \
    --mft=https://ftp.ncbi.nlm.nih.gov/genomes/TOOLS/FCS/database/latest/all.manifest \
    --dir=/home/see/databases/FCS-GX

mkdir k2_standard_16_GB_20260226
cd k2_standard_16_GB_20260226
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_16_GB_20260226.tar.gz
cd ..
```

## Acquire Raw Data

__Important__ Move into the `nf-core-bacass_2.6.0/2_6_0` folder you downloaded from the tutorial
- The sample sheet on GitHub assumes the raw_data folder is within wherever you launch the main.nf file from
- And, these instructions assume you are in the same folder as the main.nf file

Now, we'll use the full raw data for the Haemophilus influenzae genome and see how closely we can match the reference

```
# IMPORTANT!
# Move into the nf-core-bacass_2.6.0/2_6_0 folder you downloaded from the tutorial

conda activate sra-tools

# Prevent download from overriding data from the tutorial
mkdir -p raw_data_example

fastq-dump --split-files --origfmt --gzip SRR17117372 --outdir raw_data_example
```

## Assemble and Annotate the Data

Run `bacass` for all available _Haemophilus influenzae_ raw sequences associated with its reference

<!--JC note, change to GitHub links -->

```


conda activate nf-core

nextflow run main.nf \
    -c nextflow.config \
    -c juniata_cluster.config \
    -profile singularity,slurm_jc \
    --assembly_type 'short' \
    --assembler 'unicycler' \
    --input sample_sheet_bacass_example.txt \
    --kraken2db /home/see/databases/k2_standard_16_GB_20260226/k2_standard_16_GB_20260226.tar.gz \
    --skip_kmerfinder \
    --reference_fasta $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/GCF_020736045.1_ASM2073604v1_genomic.fna \
    --reference_gff $PWD/h_influenzae_reference/ncbi_dataset/data/GCF_020736045.1/genomic.gff \
    --partition batch-high \
    --outdir results_bacass_EXAMPLE

```

## Make Example Phylogenetic Tree

Move into genomeqc folder from tutorial

`cd ../../nf-core-genomeqc_787a0e6/787a0e6`

Download additional reference genomes

- GCF_016127215.1: _Haemophilus parainfluenzae_
- GCF_055382465.1: _Halomonas garicola_
- GCF_001565895.1: _Paraglaciecola hydrolytica_
- GCF_040012415.1: _Sanguibacter sp. 25GB23B1_
- GCF_038593655.1: _Vreelandella neptunia_

```
conda activate ncbi-datasets

datasets download genome accession GCF_055382465.1 GCF_001565895.1 GCF_040012415.1 GCF_038593655.1 GCF_016127215.1 --include genome,gff3 --filename extra_ncbi_dataset.zip

unzip extra_ncbi_dataset.zip -d extra_genome_references

```

Run genomeqc
- Change line 174 in workflows/genomqc.nf to `params.gxdb_manifiest ?: []` from `file(params.gxdb_manifiest) ?: []`
- To avoid error with passing a null value to file (not using manifest since FCS-GX db is available locally)

```
nextflow run main.nf \
    -c nextflow.config \
    -c juniata_cluster.config \
    -profile singularity,slurm_jc \
    --input $PWD/sample_sheet_genomeqc_example_run.csv \
    --gxdb /home/see/databases/FCS-GX \
    --partition batch-high \
    --outdir results_genomeqc_EXAMPLE

```
