````markdown
# Running `revisitingkmers-p3` on AAU AI Lab

This guide explains **exactly** how to:

- Clone and set up the project on **AAU AI Lab**
- Run the **nonlinear model** training
- Run **evaluation**
- (Optionally) track runs with **Weights & Biases**
- Change hyperparameters and run sweeps

The guide assumes:

- You have an AAU AI Lab login
- You have access to the project storage `/ceph/project/p3-kmer`
- You are using the AAU PyTorch container `pytorch_25.10.sif`

> Wherever you see `YOUR_USERNAME`, replace it with your AAU username  
> (for the original author this is `db56hw`).

---

## 1. Project & Data Layout

### 1.1. Clone the repo on AI Lab

SSH to the AI Lab frontend:

```bash
ssh YOUR_USERNAME@student.aau.dk@ailab-fe01.srv.aau.dk
````

Clone the project:

```bash
cd /ceph/home/student.aau.dk/YOUR_USERNAME
git clone https://github.com/Tinnifo/revisitingkmers-p3.git
cd revisitingkmers-p3
```

From now on we’ll call this path:

```bash
BASEFOLDER=/ceph/home/student.aau.dk/YOUR_USERNAME/revisitingkmers-p3
```

---

### 1.2. Dataset location

The project expects data here:

```bash
/ceph/project/p3-kmer/dataset
```

with at least:

```bash
/ceph/project/p3-kmer/dataset/
    train_2m.csv
    val_48k.csv
    debug_train.csv
    marine/
    plant/
    reference/
```

You can verify:

```bash
ls /ceph/project/p3-kmer/dataset
```

---

### 1.3. Container image

We use the PyTorch container:

```bash
PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
```

> You **do not** create a venv and you **do not** install packages.
> All Python runs happen inside this container with its built-in packages.

---

## 2. Training Script: `sh/run_nonlinear.sh`

This script trains the nonlinear model using `src/nonlinear.py` inside the PyTorch container.

It should look like this:

```bash
#!/usr/bin/bash -l
#SBATCH --job-name=MODEL
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --time=0-12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=YOUR_USERNAME@student.aau.dk

PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
BASEFOLDER=/ceph/home/student.aau.dk/YOUR_USERNAME/revisitingkmers-p3
DATA_DIR=/ceph/project/p3-kmer/dataset
SCRIPT_PATH=$BASEFOLDER/src/nonlinear.py
MODELNAME=nonlinear

# Hyperparameters (can be overridden by environment variables)
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

# Optional debug check
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
```

Make sure it’s executable:

```bash
chmod +x sh/run_nonlinear.sh
```

---

## 3. Quick Test Run (fast sanity check)

Before running a big experiment, do a small test:

```bash
cd /ceph/home/student.aau.dk/YOUR_USERNAME/revisitingkmers-p3

K=4 DIM=64 EPOCHNUM=1 \
NEGSAMPLEPERPOS=5 BATCH_SIZE=500 MAXREADNUM=2000 \
WORKERS_NUM=2 POSTFIX="_debug" \
sbatch sh/run_nonlinear.sh
```

### 3.1. Check the job status

```bash
squeue -u $(whoami)
```

When it starts, you’ll see `ST=R` (running).

### 3.2. Check logs

The training job writes:

```bash
MODEL_<jobid>.out
MODEL_<jobid>.err
```

Example:

```bash
tail -n 40 MODEL_123456.out
tail -n 40 MODEL_123456.err
```

You should see:

* A listing of the dataset
* “Training has just started.”
* Epoch + loss logs

The model file should appear in:

```bash
ls models
```

For the debug run, something like:

```text
nonlinear_train_2m_k=4_d=64_negsampleperpos=5_epoch=1_LR=0.001_batch=500_maxread=2000_seed=26042024_debug.model
```

---

## 4. Full Training Run

Once the debug run works, you can run the full configuration.

Example (original hyperparameter set):

```bash
K=4 DIM=256 EPOCHNUM=300 \
NEGSAMPLEPERPOS=200 BATCH_SIZE=10000 MAXREADNUM=100000 \
WORKERS_NUM=4 POSTFIX="" \
sbatch sh/run_nonlinear.sh
```

You can adjust any of these:

* `DIM`
* `EPOCHNUM`
* `LR`
* `NEGSAMPLEPERPOS`
* `BATCH_SIZE`
* `MAXREADNUM`
* `SEED`
* `LOSS_NAME`
* etc.

You do **not** edit the script for each change; just pass new values via environment variables in front of `sbatch`.

---

## 5. Evaluation Script: `sh/evaluate_nonlinear.sh`

This script loads a trained model and evaluates on one or more species datasets.

```bash
#!/usr/bin/bash -l
#SBATCH --job-name=EVALUATION
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=256G
#SBATCH --time=0-12:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=YOUR_USERNAME@student.aau.dk

PYTORCH_CONTAINER=/ceph/container/pytorch/pytorch_25.10.sif
BASEFOLDER=/ceph/home/student.aau.dk/YOUR_USERNAME/revisitingkmers-p3
SCRIPT_PATH=$BASEFOLDER/evaluation/binning.py
RESULTS_FOLDER=$BASEFOLDER/results
DATA_DIR=/ceph/project/p3-kmer/dataset

# Hyperparameters must MATCH the TRAINED MODEL filename
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
SPECIES_LIST=("reference")   # later: add "plant" "marine"
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
```

Make it executable:

```bash
chmod +x sh/evaluate_nonlinear.sh
```

### 5.1. Evaluating a specific model

Make sure the hyperparameters you pass match the model filename in `models/`.

Example: to evaluate the **debug model**:

```bash
K=4 DIM=64 EPOCHNUM=1 \
NEGSAMPLEPERPOS=5 BATCH_SIZE=500 MAXREADNUM=2000 \
POSTFIX="_debug" \
sbatch sh/evaluate_nonlinear.sh
```

Results are written to:

```bash
results/reference/<MODELNAME>.txt
```

---

## 6. Hyperparameter Sweeps

You can create a sweep script `sh/sweep_nonlinear.sh` that submits many training jobs with different hyperparameters.

Example:

```bash
#!/usr/bin/bash -l

KS=(4 5)
DIMS=(128 256)
LRS=(0.001 0.0005)
BATCH_SIZES=(10000 20000)

BASE_SEED=26042024

for K in "${KS[@]}"; do
  for DIM in "${DIMS[@]}"; do
    for LR in "${LRS[@]}"; do
      for BATCH_SIZE in "${BATCH_SIZES[@]}"; do

        SEED=$((BASE_SEED + K + DIM))

        POSTFIX="_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed${SEED}"

        echo "Submitting: K=$K DIM=$DIM LR=$LR BATCH_SIZE=$BATCH_SIZE SEED=$SEED"

        sbatch --export=ALL,\
K=$K,DIM=$DIM,LR=$LR,BATCH_SIZE=$BATCH_SIZE,SEED=$SEED,POSTFIX="$POSTFIX" \
            sh/run_nonlinear.sh

      done
    done
  done
done
```

Run:

```bash
chmod +x sh/sweep_nonlinear.sh
sh sh/sweep_nonlinear.sh
```

This submits one `MODEL` job per combination.

---

## 7. Weights & Biases (Optional)

The `src/nonlinear.py` script already supports W&B via flags:

* `--use_wandb`
* `--wandb_project`
* `--wandb_entity`
* `--wandb_run_name`
* `--wandb_mode`
* `--wandb_tags`

To use W&B:

1. **Ensure `wandb` is installed** inside the container environment
   (You may need to coordinate with admins or install into a location with enough quota.)

2. Log in once (inside the container):

   ```bash
   singularity exec /ceph/container/pytorch/pytorch_25.10.sif \
       wandb login
   ```

3. Extend `run_nonlinear.sh` to add e.g.:

   ```bash
   WANDB_PROJECT=${WANDB_PROJECT:-"P3-Run1"}
   WANDB_ENTITY=${WANDB_ENTITY:-"tinnifo"}
   WANDB_MODE=${WANDB_MODE:-"online"}
   WANDB_RUN_NAME=${WANDB_RUN_NAME:-"nonlinear_k${K}_d${DIM}_lr${LR}_bs${BATCH_SIZE}_seed${SEED}"}
   WANDB_TAGS=${WANDB_TAGS:-"sweep,nonlinear"}

   singularity exec --nv "$PYTORCH_CONTAINER" python3 "$SCRIPT_PATH" \
       ...existing args... \
       --use_wandb \
       --wandb_project "$WANDB_PROJECT" \
       --wandb_entity "$WANDB_ENTITY" \
       --wandb_run_name "$WANDB_RUN_NAME" \
       --wandb_mode "$WANDB_MODE" \
       --wandb_tags "$WANDB_TAGS"
   ```

4. Then runs appear under `https://wandb.ai/<entity>/<project>`.

> If `import wandb` fails inside the container and you can’t install it due to storage limits, just run without `--use_wandb`.

---

## 8. Typical Workflow Summary

1. **Clone** the repo into
   `/ceph/home/student.aau.dk/YOUR_USERNAME/revisitingkmers-p3`
2. Verify **data** under
   `/ceph/project/p3-kmer/dataset`
3. Make sure `sh/run_nonlinear.sh` and `sh/evaluate_nonlinear.sh` are executable and paths use **YOUR_USERNAME**.
4. Run a **small debug training job** with 1 epoch and smaller batch.
5. Inspect logs (`MODEL_<jobid>.out/err`), verify a model file was written.
6. Run **evaluation** on that model with matching hyperparameters/POSTFIX.
7. Launch a **sweep** using `sh/sweep_nonlinear.sh` if desired.
8. (Optional) Enable **Weights & Biases** when `wandb` is available.


