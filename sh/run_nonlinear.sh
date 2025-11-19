#!/usr/bin/bash -l
#SBATCH --job-name=MODEL
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --partition=batch
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=db56hw@student.aau.dk

MODELNAME=nonlinear
BASEFOLDER=/ceph/home/student.aau.dk/db56hw/revisitingkmers-p3
VENV=$BASEFOLDER/.venv
CONTAINER=/ceph/container/pytorch/pytorch_24.09.sif

SCRIPT_PATH=$BASEFOLDER/src/nonlinear.py
DATA_DIR=/ceph/project/p3-kmer/dataset
INPUT_PATH=$DATA_DIR/train_2m.csv

POSTFIX=""
K=4
DIM=256
EPOCHNUM=300
LR=0.001
NEGSAMPLEPERPOS=200
BATCH_SIZE=10000
MAXREADNUM=100000
SEED=26042024
CHECKPOINT=0

mkdir -p "$BASEFOLDER/models"

OUTPUT_PATH=$BASEFOLDER/models/${MODELNAME}_train_2m_k=${K}_d=${DIM}_negsampleperpos=${NEGSAMPLEPERPOS}
OUTPUT_PATH=${OUTPUT_PATH}_epoch=${EPOCHNUM}_LR=${LR}_batch=${BATCH_SIZE}_maxread=${MAXREADNUM}_seed=${SEED}${POSTFIX}.model

singularity exec --nv \
    -B "$VENV":/scratch/venv \
    -B "$DATA_DIR":/scratch/dataset \
    "$CONTAINER" \
    bash -c "
        source /scratch/venv/bin/activate && \
        python $SCRIPT_PATH \
            --input /scratch/dataset/train_2m.csv \
            --k $K \
            --epoch $EPOCHNUM \
            --lr $LR \
            --neg_sample_per_pos $NEGSAMPLEPERPOS \
            --max_read_num $MAXREADNUM \
            --batch_size $BATCH_SIZE \
            --device cuda \
            --output $OUTPUT_PATH \
            --seed $SEED \
            --checkpoint $CHECKPOINT
    "
