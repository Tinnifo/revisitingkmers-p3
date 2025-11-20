#!/usr/bin/bash -l
#SBATCH --job-name=MODEL
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=0-01:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tolaso24@student.aau.dk

PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
BASEFOLDER=/ceph/home/student.aau.dk/db56hw/revisitingkmers-p3
DATA_DIR=/ceph/project/p3-kmer/dataset
SCRIPT_PATH=$BASEFOLDER/src/nonlinear.py
MODELNAME=nonlinear

# Hyperparameters (overridable from the command line)
K=${K:-4}
DIM=${DIM:-256}
EPOCHNUM=${EPOCHNUM:-300}
LR=${LR:-0.001}
NEGSAMPLEPERPOS=${NEGSAMPLEPERPOS:-200}
BATCH_SIZE=${BATCH_SIZE:-10000}
MAXREADNUM=${MAXREADNUM:-100000}
SEED=${SEED:-26042024}
CHECKPOINT=${CHECKPOINT:-0}
LOSS_NAME=${LOSS_NAME:-"bern"}
WORKERS_NUM=${WORKERS_NUM:-1}
DEVICE=${DEVICE:-"cuda"}
POSTFIX=${POSTFIX:-""}

mkdir -p "$BASEFOLDER/models"

OUTPUT_PATH=$BASEFOLDER/models/${MODELNAME}_train_2m_k=${K}_d=${DIM}_negsampleperpos=${NEGSAMPLEPERPOS}
OUTPUT_PATH=${OUTPUT_PATH}_epoch=${EPOCHNUM}_LR=${LR}_batch=${BATCH_SIZE}_maxread=${MAXREADNUM}_seed=${SEED}${POSTFIX}.model

echo "Running model with:"
echo "  K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE MAXREADNUM=$MAXREADNUM SEED=$SEED"
echo "  Output model: $OUTPUT_PATH"

cd "$BASEFOLDER"


echo "Checking that data file exists inside job..."
ls -l "$DATA_DIR"
if [ ! -f "$DATA_DIR/train_2m.csv" ]; then
    echo "ERROR: $DATA_DIR/train_2m.csv NOT FOUND"
    exit 1
fi


# Run inside the PyTorch container
singularity exec --nv "$PYTORCH_CONTAINER" python3 "$SCRIPT_PATH" \
    --input "$DATA_DIR/train_2m.csv" \
    --k "$K" \
    --dim "$DIM" \
    --neg_sample_per_pos "$NEGSAMPLEPERPOS" \
    --max_read_num "$MAXREADNUM" \
    --epoch "$EPOCHNUM" \
    --lr "$LR" \
    --batch_size "$BATCH_SIZE" \
    --device "$DEVICE" \
    --workers_num "$WORKERS_NUM" \
    --loss_name "$LOSS_NAME" \
    --output "$OUTPUT_PATH" \
    --seed "$SEED" \
    --checkpoint "$CHECKPOINT"
