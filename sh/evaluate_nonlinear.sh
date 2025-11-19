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

# ---------------- Hyperparameters (overridable by env) ----------------
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
# ----------------------------------------------------------------------

# ---------------- Weights & Biases settings ----------------
USE_WANDB=${USE_WANDB:-1}               # 1 = on, 0 = off
WANDB_PROJECT=${WANDB_PROJECT:-"revisitingkmers"}
WANDB_ENTITY=${WANDB_ENTITY:-""}        # your wandb username or team (optional)
WANDB_MODE=${WANDB_MODE:-"online"}      # online / offline / disabled
WANDB_TAGS=${WANDB_TAGS:-""}            # comma-separated tags, e.g. "sweep,nonlinear"
# Run name: encode hyperparams in a readable way
WANDB_RUN_NAME=${WANDB_RUN_NAME:-"nonlinear_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed${SEED}"}
# -----------------------------------------------------------

mkdir -p "$BASEFOLDER/models"

OUTPUT_PATH=$BASEFOLDER/models/${MODELNAME}_train_2m_k=${K}_d=${DIM}_negsampleperpos=${NEGSAMPLEPERPOS}
OUTPUT_PATH=${OUTPUT_PATH}_epoch=${EPOCHNUM}_LR=${LR}_batch=${BATCH_SIZE}_maxread=${MAXREADNUM}_seed=${SEED}${POSTFIX}.model

echo "Running with:"
echo "  K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE MAXREADNUM=$MAXREADNUM SEED=$SEED"
echo "  Using Weights & Biases: $USE_WANDB (project=$WANDB_PROJECT, run=$WANDB_RUN_NAME)"

singularity exec --nv \
    -B "$VENV":/scratch/venv \
    -B "$DATA_DIR":/scratch/dataset \
    "$CONTAINER" \
    bash -c "
        source /scratch/venv/bin/activate && \
        python $SCRIPT_PATH \
            --input /scratch/dataset/train_2m.csv \
            --k $K \
            --dim $DIM \
            --neg_sample_per_pos $NEGSAMPLEPERPOS \
            --max_read_num $MAXREADNUM \
            --epoch $EPOCHNUM \
            --lr $LR \
            --batch_size $BATCH_SIZE \
            --device $DEVICE \
            --workers_num $WORKERS_NUM \
            --loss_name $LOSS_NAME \
            --output $OUTPUT_PATH \
            --seed $SEED \
            --checkpoint $CHECKPOINT \
            $( [ \"$USE_WANDB\" -eq 1 ] && echo \"--use_wandb --wandb_project $WANDB_PROJECT\" ) \
            $( [ \"$USE_WANDB\" -eq 1 ] && [ -n \"$WANDB_ENTITY\" ] && echo \"--wandb_entity $WANDB_ENTITY\" ) \
            $( [ \"$USE_WANDB\" -eq 1 ] && echo \"--wandb_run_name $WANDB_RUN_NAME\" ) \
            $( [ \"$USE_WANDB\" -eq 1 ] && echo \"--wandb_mode $WANDB_MODE\" ) \
            $( [ \"$USE_WANDB\" -eq 1 ] && [ -n \"$WANDB_TAGS\" ] && echo \"--wandb_tags '$WANDB_TAGS'\" )
    "
