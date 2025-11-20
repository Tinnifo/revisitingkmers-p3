#!/usr/bin/bash -l
#SBATCH --job-name=INSTALL_DEPS
#SBATCH --output=install_deps_%j.out
#SBATCH --error=install_deps_%j.err
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --time=00:20:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tolaso24@student.aau.dk

PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
PROJECT_DIR=/ceph/home/student.aau.dk/db56hw/revisitingkmers-p3

echo "Installing Python dependencies with --user..."
singularity exec --nv "$PYTORCH_CONTAINER" \
    bash -lc "cd $PROJECT_DIR && pip install --user --no-cache-dir -r requirements.txt"

echo "Done."
