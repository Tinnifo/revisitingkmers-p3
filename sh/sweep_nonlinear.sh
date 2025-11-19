#!/usr/bin/bash -l

# Hyperparameter grids
KS=(4 5)
DIMS=(128 256)
LRS=(0.001 0.0005)
BATCH_SIZES=(10000 20000)

BASE_SEED=26042024

# WandB settings for all runs
export USE_WANDB=1
export WANDB_PROJECT="revisitingkmers"
export WANDB_ENTITY=""          # set to your wandb username/team if needed
export WANDB_MODE="online"      # or "offline"/"disabled"

for K in "${KS[@]}"; do
  for DIM in "${DIMS[@]}"; do
    for LR in "${LRS[@]}"; do
      for BATCH_SIZE in "${BATCH_SIZES[@]}"; do

        SEED=$((BASE_SEED + K + DIM))

        # Tags for this particular run
        WANDB_TAGS="sweep,nonlinear,k=${K},dim=${DIM},lr=${LR},bs=${BATCH_SIZE}"
        WANDB_RUN_NAME="nonlinear_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed${SEED}"

        echo "Submitting: K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE SEED=$SEED"

        sbatch --export=ALL,\
K=$K,DIM=$DIM,LR=$LR,BATCH_SIZE=$BATCH_SIZE,SEED=$SEED,\
WANDB_TAGS="$WANDB_TAGS",WANDB_RUN_NAME="$WANDB_RUN_NAME" \
            sh/run_nonlinear.sh

      done
    done
  done
done
