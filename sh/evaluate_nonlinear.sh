#!/usr/bin/bash -l
#SBATCH --job-name=EVALUATION
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=256G
#SBATCH --time=0-12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=tolaso24@student.aau.dk

PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
BASEFOLDER=/ceph/home/student.aau.dk/db56hw/revisitingkmers-p3
SCRIPT_PATH=$BASEFOLDER/evaluation/binning.py
RESULTS_FOLDER=$BASEFOLDER/results
DATA_DIR=/ceph/project/p3-kmer/dataset

# Hyperparameters must match the TRAINED MODEL you want to evaluate
K=${K:-4}
DIM=${DIM:-256}
EPOCHNUM=${EPOCHNUM:-300}
LR=${LR:-0.001}
NEGSAMPLEPERPOS=${NEGSAMPLEPERPOS:-200}
BATCH_SIZE=${BATCH_SIZE:-10000}
MAXREADNUM=${MAXREADNUM:-100000}
POSTFIX=${POSTFIX:-""}
MODELNAME="nonlinear"

MODELNAME=${MODELNAME}_train_2m_k=${K}_d=${DIM}_negsampleperpos=${NEGSAMPLEPERPOS}
MODELNAME=${MODELNAME}_epoch=${EPOCHNUM}_LR=${LR}_batch=${BATCH_SIZE}_maxread=${MAXREADNUM}${POSTFIX}

MODEL_PATH=$BASEFOLDER/models/${MODELNAME}.model

# Species list (comma separated env override)
SPECIES_TARGETS=${SPECIES_LIST:-"reference"}
IFS=',' read -r -a SPECIES_LIST <<< "$SPECIES_TARGETS"
MODELLIST=nonlinear
SAMPLES=${SAMPLES:-"5,6"}

mkdir -p "${RESULTS_FOLDER}/reference" "${RESULTS_FOLDER}/marine" "${RESULTS_FOLDER}/plant"

export PYTHONPATH=${PYTHONPATH}:${BASEFOLDER}

USE_WANDB=${USE_WANDB:-0}
WANDB_PROJECT=${WANDB_PROJECT:-""}
WANDB_ENTITY=${WANDB_ENTITY:-""}
WANDB_MODE=${WANDB_MODE:-"online"}
WANDB_TAGS=${WANDB_TAGS:-""}
WANDB_RUN_NAME=${WANDB_RUN_NAME:-"nonlinear_eval_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed${SEED}"}
WANDB_RUN_ID=${WANDB_RUN_ID:-""}
WANDB_RESUME=${WANDB_RESUME:-"allow"}

if [ "$USE_WANDB" -eq 1 ] && [ -z "$WANDB_RUN_ID" ]; then
    WANDB_RUN_ID=$(uuidgen)
fi

if [ "$USE_WANDB" -eq 1 ]; then
    export WANDB_RUN_ID
    export WANDB_RESUME
    export WANDB_MODE
fi

cd "$BASEFOLDER"

for SPECIES in "${SPECIES_LIST[@]}"; do
    OUTPUT_PATH=${RESULTS_FOLDER}/${SPECIES}/${MODELNAME}.txt
    CMD=(
        python "$SCRIPT_PATH"
        --data_dir "$DATA_DIR"
        --model_list "$MODELLIST"
        --species "$SPECIES"
        --test_model_dir "$MODEL_PATH"
        --output "$OUTPUT_PATH"
        --samples "$SAMPLES"
    )
    if [ "$USE_WANDB" -eq 1 ]; then
        CMD+=(
            --use_wandb
            --wandb_project "$WANDB_PROJECT"
            --wandb_entity "$WANDB_ENTITY"
            --wandb_run_name "$WANDB_RUN_NAME"
            --wandb_run_id "$WANDB_RUN_ID"
            --wandb_mode "$WANDB_MODE"
            --wandb_resume "$WANDB_RESUME"
        )
        if [ -n "$WANDB_TAGS" ]; then
            CMD+=(--wandb_tags "$WANDB_TAGS")
        fi
    fi

    singularity exec --nv \
        -B /ceph/project:/ceph/project \
        "$PYTORCH_CONTAINER" \
        "${CMD[@]}"
done
