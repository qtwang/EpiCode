#!/bin/bash
#SBATCH --job-name=hspike_cluster_template
#SBATCH --partition=bigmem
#SBATCH --time=99:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --chdir=.
#SBATCH --error=/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/slurm/%A_%a_%j-%x_error.txt
#SBATCH --output=/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/slurm/%A_%a_%j-%x_output.txt
#SBATCH --array=1-8

module load MATLAB/R2020b
matlab -nodesktop -softwareopengl -nosplash -nodisplay -r "hspike_cluster_template($SLURM_ARRAY_TASK_ID);"
sleep 5;
