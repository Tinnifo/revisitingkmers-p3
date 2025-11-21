````markdown
# Revisiting K-mers — Sweep Workflow (AAU AI-Lab)

This guide explains only how to run sweeps on AAU AI-Lab using the built-in scripts:

- clone the repo  
- configure optional W&B tracking  
- run a sweep over hyperparameters  
- override all hyperparameter lists  
- monitor jobs and view outputs  

You do not edit the Python code or `.sh` scripts.  
You only change:

- your AAU username  
- your AAU email  
- optional W&B settings  
- optional hyperparameter ranges when launching a sweep  

IMPORTANT! You do not need to upload the datasets to AI Lab. They have been uploaded in the AI Lab project folder under /ceph/project/p3-kmer/dataset
---

## 1. Clone the Repository on AI-Lab

SSH to AI-Lab:

```bash
ssh YOUR_USERNAME@student.aau.dk@ailab-fe01.srv.aau.dk
````

Clone the repo:

```bash
cd /ceph/home/student.aau.dk/YOUR_USERNAME
git clone https://github.com/Tinnifo/revisitingkmers-p3.git
cd revisitingkmers-p3
```

Replace `YOUR_USERNAME` with your AAU username.

---

## 2. Required Edits (Once)

Both sweep-dependent scripts send email notifications.
Update this line in:

* `sh/run_nonlinear.sh`
* `sh/evaluate_nonlinear.sh`

```bash
#SBATCH --mail-user=YOUR_EMAIL@student.aau.dk
```

Replace with your AAU email.

---

## 3. Enable Weights & Biases 

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

Install `wandb` inside the container environment:

```bash
srun --mem=8G --time=00:05:00 \
  singularity exec --nv /ceph/container/pytorch/pytorch_24.09.sif \
  pip install --user wandb
```

---

## 5. Override Hyperparameters

You can override any parameter list directly when launching the sweep.

**Example overriding all lists:**

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

The script will:

* iterate through all combinations
* assign a unique `WANDB_RUN_ID`
* submit one training job per combo
* submit a matching evaluation job with `--dependency=afterok`

---

## 6. Minimal Custom Sweep Examples

**Small sweep**

```bash
K_LIST="4 5" \
DIM_LIST="64 128" \
sh sh/sweep_nonlinear.sh
```

**Sweep with W&B enabled**

```bash
USE_WANDB=1 \
WANDB_PROJECT="p3-experiments" \
WANDB_ENTITY="myname" \
K_LIST="4 8" \
DIM_LIST="128 256" \
sh sh/sweep_nonlinear.sh
```

**Single experiment via sweep script**

```bash
K_LIST="4" \
DIM_LIST="256" \
LR_LIST="0.001" \
USE_WANDB=1 \
sh sh/sweep_nonlinear.sh
```

---

## 7. Monitoring Jobs

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

## 8. Outputs

**Models**

```bash
models/
```

**Evaluation results**

```bash
results/<species>/
```

**W&B dashboard**
Check your online W&B project for experiment logs and metrics.
