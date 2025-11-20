````markdown
# Revisiting K-mers — Sweep Workflow (AAU AI-Lab)

This guide explains only **how to run sweeps** on AAU AI-Lab using the built-in scripts:

- clone the repo  
- configure optional W&B tracking  
- run a sweep over hyperparameters  
- override all hyperparameter lists  
- monitor jobs and view outputs  

You do **not** edit the Python code or `.sh` scripts.  
You only change:

- your AAU **username**
- your AAU **email**
- optional **W&B settings**
- optional hyperparameter ranges when launching a sweep

---

# 1. Clone the Repository on AI-Lab

SSH to AI-Lab:

```bash
ssh YOUR_USERNAME@student.aau.dk@ailab-fe01.srv.aau.dk
````

Clone:

```bash
cd /ceph/home/student.aau.dk/YOUR_USERNAME
git clone https://github.com/Tinnifo/revisitingkmers-p3.git
cd revisitingkmers-p3
```

Replace `YOUR_USERNAME` with your AAU username.

---

# 2. Required Edits (Once)

Both sweep-dependent scripts send email notifications.
Update the following line in each script:

```
sh/run_nonlinear.sh
sh/evaluate_nonlinear.sh
```

Change:

```bash
#SBATCH --mail-user=YOUR_EMAIL@student.aau.dk
```

Replace with your AAU email.

---

# 3. Enable Weights & Biases

Add your API key:

```bash
nano ~/.bashrc
```

Add:

```bash
export WANDB_API_KEY="YOUR_WANDB_API_KEY"
```

Reload:

```bash
source ~/.bashrc
```

Install wandb inside the container environment:

```bash
srun --mem=8G --time=00:05:00 \
  singularity exec --nv /ceph/container/pytorch/pytorch_24.09.sif \
  pip install --user wandb
```

---

# 4. Run the Default Sweep

Inside the repo:

```bash
sh sh/sweep_nonlinear.sh
```

This will:

* loop over the default hyperparameter lists
* create a unique W&B run ID for each combo
* submit a training job
* automatically submit an evaluation job that depends on the training job (afterok)
* log both to the same W&B run (if enabled)

---

# 5. Override Hyperparameters 

You can override **any** parameter list directly when launching the sweep.

Example overriding *all* lists:

```bash
K_LIST="4 6" \
DIM_LIST="64 128 256" \
LR_LIST="0.001 0.0005" \
EPOCH_LIST="1 5" \
NEG_LIST="5 20" \
BATCH_LIST="500 2000" \
MAXREAD_LIST="2000 5000" \
SEED_LIST="42 26042024" \
LOSS_LIST="bern hinge" \
SPECIES_LIST="reference plant marine" \
USE_WANDB=1 \
WANDB_PROJECT="my_kmer_sweep" \
WANDB_ENTITY="my_wandb_user" \
WANDB_TAGS="sweep,kmers" \
sh sh/sweep_nonlinear.sh
```

The sweep script will automatically:

* iterate through all combinations
* assign a unique `WANDB_RUN_ID` for each
* submit training jobs
* submit matching evaluation jobs with `--dependency=afterok`

---

# 6. Minimal Custom Sweep Examples

### Small sweep

```bash
K_LIST="4 5" \
DIM_LIST="64 128" \
sh sh/sweep_nonlinear.sh
```

### Sweep with W&B enabled

```bash
USE_WANDB=1 \
WANDB_PROJECT="p3-experiments" \
WANDB_ENTITY="myname" \
K_LIST="4 8" \
DIM_LIST="128 256" \
sh sh/sweep_nonlinear.sh
```

### Single experiment via sweep script

```bash
K_LIST="4" \
DIM_LIST="256" \
LR_LIST="0.001" \
USE_WANDB=1 \
sh sh/sweep_nonlinear.sh
```

---

# 7. Monitoring Jobs

```bash
squeue -u $(whoami)
```

Logs:

```bash
tail -n 40 MODEL_*.out
tail -n 40 MODEL_*.err

tail -n 40 EVALUATION_*.out
tail -n 40 EVALUATION_*.err
```

---

# 8. Outputs

Models:

```
models/
```

Evaluation results:

```
results/<species>/
```

W&B run dashboard:

```
https://wandb.ai/YOUR_ENTITY/YOUR_PROJECT
```

---

# 9. Sweep Workflow Diagram

A[Start sweep\nsh/sweep_nonlinear.sh] --> B[Loop over hyperparameter sets]

B --> C[Generate WANDB_RUN_ID]
C --> D[Submit TRAIN job\nsbatch sh/run_nonlinear.sh]
D -->E[TRAIN job runs\nnonlinear.py → model saved]

D --> F[Submit EVAL job\nsbatch --dependency=afterok:TRAIN]
F --> G[EVAL job runs\nevaluation/binning.py → metrics saved]

E -->|if W&B enabled| H[wandb.log training]
G -->|if W&B enabled| I[wandb.log evaluation]
```
