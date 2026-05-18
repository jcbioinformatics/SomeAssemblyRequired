#!/bin/bash

#SBATCH --cpus-per-task=1
#SBATCH -J $NAME
#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err
#SBATCH --partition=batch-high,batch-medium,batch-low


#======================================================================#
#  $DESCRIPTION
# 
#  $DATE		
#======================================================================#

# Give either the absolute path to either the 2_5_0 subfolder 
# OR the 1947a80 subfolder
# For bacass or genomeqc, respectively
workdir=$PATHTOFOLDER
cd $workdir

###################CODE###################

