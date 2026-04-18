#!/bin/bash

#SBATCH --cpus-per-task=8
#SBATCH -J k2Test
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=batch-high,batch-medium,batch-low


#======================================================================#
#  Imports raw fastq reads into a QIIME2 artifact.
# 
#  June 29, 2018				
#======================================================================#

# Set your working directory to your main data folder 
workdir=/home/see/Wright_Labs/2026/April/PSU/redo_Kraken2
cd $workdir


source ~/.bashrc

# Create Kraken2 DB for tutorial
# Make Kraken2 environment if necessary
#conda env create --name kraken2 -f kraken2.yml

conda activate kraken2

# Download test database for FCS-GX
# https://github.com/ncbi/fcs-gx?tab=readme-ov-file#verify-functionality-by-using-a-small-test-only-database
curl -L https://zenodo.org/records/10932013/files/FCS_combo_test.fa -o TUTORIAL_fcs-gx_db.fa

# We wanted to create smaller dbs for Kraken2 and kmerfinder for use with this tutorial
# To make these databases slightly more realistic, we included top contaminants 
# Identified by: https://pubmed.ncbi.nlm.nih.gov/32398145/ (Conterminator paper)
# Saccharomyces cerevisiae, Stenotrophomonas maltophilia, Serratia marcescens

# Create Kraken2 DB for tutorial
# Make Kraken2 environment if necessary
#conda env create --name kraken2 -f kraken2.yml


# Make folder to house Kraken2 database
mkdir TUTORIAL_k2_db

# Download NCBI taxonomy
k2 download-taxonomy --db TUTORIAL_k2_db


# Download only desired bacteria genomes
# Switch to ncbi-datasets env
conda deactivate

conda activate ncbi-datasets

# Download genomes
# Specify ids for current reference genomes
datasets download genome accession \
    GCF_000146045.2 GCF_020641395.2 GCF_020736045.1 GCF_030291735.1 \
    --include genome \
    --filename ref_genomes.zip

# Decompress downloaded genomes
unzip ref_genomes.zip

# Make "added" subfolder to include these genomes in Kraken2 db
mkdir TUTORIAL_k2_db/library/added -p

# Move into data folder
cd ncbi_dataset/data/

# Add taxids to headers
taxids_list=(
    "S_cere,GCF_000146045.2,4932"
    "S_malto,GCF_020641395.2,40324"
    "H_influenzae,GCF_020736045.1,727"
    "S_marcescens,GCF_030291735.1,615"
)

for tax_info in "${taxids_list[@]}"
do
    genome=`echo $tax_info | cut -f 2 -d ,`
    id=`echo $tax_info | cut -f 3 -d ,`

    cd $genome

    find . -name *.fna -type f -exec sed "s/^>/>kraken:taxid\|$id /g" {} + >> ../../../TUTORIAL_k2_db/library/added/library.fna

    cd ..
done

cd ../..

# Remove spaces from seq headers
sed -i 's/ /_/g' TUTORIAL_k2_db/library/added/library.fna

# Make taxmap file for Kraken2
# First, get all seq headers
grep "^>" TUTORIAL_k2_db/library/added/library.fna | sed 's/^>//g' > seq_headers.txt

# Next extract tax ids
cat seq_headers.txt | cut -f 2 -d '|' | cut -f 1 -d '_' > taxids.txt

# Then paste them together
paste seq_headers.txt taxids.txt > TUTORIAL_k2_db/seqid2taxid.map

# Switch back to kraken2 env
conda deactivate

conda activate kraken2

# Build database
k2 build --db TUTORIAL_k2_db --threads 8

# Confirm database contains the expected taxa
k2 inspect --db TUTORIAL_k2_db  --use-mpa-style --output TUTORIAL_K2_db_list.txt

# Move dbs into same folder
mkdir TUTORIAL_dbs

mv TUTORIAL_fcs-gx_db.fa TUTORIAL_dbs

mv TUTORIAL_k2_db TUTORIAL_dbs
mv TUTORIAL_K2_db_list.txt TUTORIAL_dbs/TUTORIAL_k2_db

# Delete unneeded Kraken2 db folders
rm -rf TUTORIAL_dbs/TUTORIAL_k2_db/library
rm -rf TUTORIAL_dbs/TUTORIAL_k2_db/taxonomy

# Compress Kraken2 folder
cd TUTORIAL_dbs

tar -czvf TUTORIAL_k2_db.tar.gz TUTORIAL_k2_db
