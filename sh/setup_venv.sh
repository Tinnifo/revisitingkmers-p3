#!/usr/bin/bash -l
#SBATCH --job-name=SETUP_VENV
#SBATCH --output=setup_venv_%j.out
#SBATCH --error=setup_venv_%j.err
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --time=00:20:00
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=tolaso24@student.aau.dk

# Choose the existing PyTorch container
PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif

# Your project directory on AI Lab
PROJECT_DIR=/ceph/home/student.aau.dk/db56hw/revisitingkmers-p3
cd "$PROJECT_DIR"

echo "Creating virtual env..."
singularity exec "$PYTORCH_CONTAINER" \
    python -m venv .venv

echo "Installing requirements..."
singularity exec --nv "$PYTORCH_CONTAINER" \
    bash -c "cd $PROJECT_DIR && \
             source .venv/bin/activate && \
             pip install --no-cache-dir -r requirements.txt"

echo "Done."

