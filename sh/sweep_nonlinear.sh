#!/usr/bin/bash -l
set -euo pipefail

# Hyperparameter grids
KS=(4 5)
DIMS=(128 256)
LRS=(0.001 0.0005)
BATCH_SIZES=(10000 20000)

BASE_SEED=26042024

# Default WandB settings for all runs in this sweep (can be overridden via env)
WANDB_PROJECT=${WANDB_PROJECT:-"P3-Run1"}
WANDB_ENTITY=${WANDB_ENTITY:-"tinnifo"}
WANDB_MODE=${WANDB_MODE:-"online"}
WANDB_RESUME=${WANDB_RESUME:-"allow"}
SPECIES_LIST=${SPECIES_LIST:-"reference"}
SAMPLES=${SAMPLES:-"5,6"}

submit_train_and_eval () {
    local K=$1
    local DIM=$2
    local LR=$3
    local BATCH_SIZE=$4
    local SEED=$5

    local WANDB_TAGS="sweep,nonlinear,k=${K},dim=${DIM},lr=${LR},bs=${BATCH_SIZE}"
    local TRAIN_RUN_NAME="nonlinear_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed=${SEED}"
    local EVAL_RUN_NAME="${TRAIN_RUN_NAME}_eval"
    local RUN_ID
    RUN_ID=$(uuidgen)

    echo "Submitting training job for K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE SEED=$SEED (run_id=$RUN_ID)"

    local TRAIN_JOB_ID
    TRAIN_JOB_ID=$(K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE SEED=$SEED \
        USE_WANDB=1 WANDB_PROJECT="$WANDB_PROJECT" WANDB_ENTITY="$WANDB_ENTITY" \
        WANDB_MODE="$WANDB_MODE" WANDB_TAGS="$WANDB_TAGS" WANDB_RUN_NAME="$TRAIN_RUN_NAME" \
        WANDB_RUN_ID="$RUN_ID" WANDB_RESUME="$WANDB_RESUME" \
        sbatch --parsable sh/run_nonlinear.sh)

    echo " -> Training job id: $TRAIN_JOB_ID"
    echo "Submitting evaluation job (depends on $TRAIN_JOB_ID)"

    local EVAL_JOB_ID
    EVAL_JOB_ID=$(K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE SEED=$SEED \
        USE_WANDB=1 WANDB_PROJECT="$WANDB_PROJECT" WANDB_ENTITY="$WANDB_ENTITY" \
        WANDB_MODE="$WANDB_MODE" WANDB_TAGS="$WANDB_TAGS" WANDB_RUN_NAME="$EVAL_RUN_NAME" \
        WANDB_RUN_ID="$RUN_ID" WANDB_RESUME="$WANDB_RESUME" \
        SPECIES_LIST="$SPECIES_LIST" SAMPLES="$SAMPLES" \
        sbatch --parsable --dependency=afterok:${TRAIN_JOB_ID} sh/evaluate_nonlinear.sh)

    echo " -> Evaluation job id: $EVAL_JOB_ID"
}

for K in "${KS[@]}"; do
  for DIM in "${DIMS[@]}"; do
    for LR in "${LRS[@]}"; do
      for BATCH_SIZE in "${BATCH_SIZES[@]}"; do
        SEED=$((BASE_SEED + K + DIM))
        submit_train_and_eval "$K" "$DIM" "$LR" "$BATCH_SIZE" "$SEED"
      done
    done
  done
done
