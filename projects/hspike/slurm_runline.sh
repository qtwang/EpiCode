#!/bin/bash
#SBATCH --job-name=spyking-circus
#SBATCH --partition=bigmem
#SBATCH --time=99:99:99
#SBATCH --mem=128G
#SBATCH --cpus-per-task=24
#SBATCH --output=/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/slurm/%A-%a-%x-output.txt
#SBATCH --error=/network/lustre/iss01/charpier/analyses/stephen.whitmarsh/slurm/%A-%a-%x-error.txt
#SBATCH --array=1-6,9-10,34-36

eval $(sed -n "$SLURM_ARRAY_TASK_ID"p slurm_job_list.txt)
