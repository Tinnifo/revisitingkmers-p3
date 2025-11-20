#!/usr/bin/bash -l
#SBATCH --job-name=SETUP_VENV
#SBATCH --output=setup_venv_%j.out
#SBATCH --error=setup_venv_%j.err
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --time=00:20:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tolaso24@student.aau.dk

cd /ceph/home/student.aau.dk/db56hw/revisitingkmers-p3

echo "Creating virtual env..."
singularity exec /ceph/container/pytorch/pytorch_24.09.sif \
    python -m venv --system-site-packages .venv

echo "Installing requirements..."
singularity exec --nv \
    -B .venv:/scratch/venv \
    /ceph/container/pytorch/pytorch_24.09.sif \
    bash -c "source /scratch/venv/bin/activate && \
             pip install --no-cache-dir -r requirements.txt"

echo "Done."
