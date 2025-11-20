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

POSTFIX=""
K=4
DIM=256
EPOCHNUM=300
LR=0.001
NEGSAMPLEPERPOS=200
BATCH_SIZE=10000
MAXREADNUM=100000
MODELNAME="nonlinear"

MODELNAME=${MODELNAME}_train_2m_k=${K}_d=${DIM}_negsampleperpos=${NEGSAMPLEPERPOS}
MODELNAME=${MODELNAME}_epoch=${EPOCHNUM}_LR=${LR}_batch=${BATCH_SIZE}_maxread=${MAXREADNUM}${POSTFIX}

MODEL_PATH=$BASEFOLDER/models/${MODELNAME}.model
SPECIES_LIST=("reference")   # later: "plant" "marine"
MODELLIST=nonlinear

mkdir -p "${RESULTS_FOLDER}/reference" "${RESULTS_FOLDER}/marine" "${RESULTS_FOLDER}/plant"

export PYTHONPATH=${PYTHONPATH}:${BASEFOLDER}

singularity exec --nv "$PYTORCH_CONTAINER" \
    bash -lc "
        cd $BASEFOLDER && \
        for SPECIES in ${SPECIES_LIST[@]}; do
            OUTPUT_PATH=${RESULTS_FOLDER}/\${SPECIES}/${MODELNAME}.txt
            python $SCRIPT_PATH \
                --data_dir $DATA_DIR \
                --model_list $MODELLIST \
                --species \${SPECIES} \
                --test_model_dir $MODEL_PATH \
                --output \${OUTPUT_PATH}
        done
    "
