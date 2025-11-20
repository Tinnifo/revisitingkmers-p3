```markdown
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

---

# 1. Clone the Repository on AI-Lab

SSH to AI-Lab:

```bash
ssh YOUR_USERNAME@student.aau.dk@ailab-fe01.srv.aau.dk
Clone the repo:

bash
Copy code
cd /ceph/home/student.aau.dk/YOUR_USERNAME
git clone https://github.com/Tinnifo/revisitingkmers-p3.git
cd revisitingkmers-p3
Replace YOUR_USERNAME with your AAU username.

2. Required Edits (Once)
Both sweep-dependent scripts send email notifications.
Update this line in:

sh/run_nonlinear.sh

sh/evaluate_nonlinear.sh

bash
Copy code
#SBATCH --mail-user=YOUR_EMAIL@student.aau.dk
Replace with your AAU email.

3. Enable Weights & Biases (Optional)
Add your API key:

bash
Copy code
nano ~/.bashrc
Add:

bash
Copy code
export WANDB_API_KEY="YOUR_WANDB_API_KEY"
Reload:

bash
Copy code
source ~/.bashrc
Install wandb inside the container environment:

bash
Copy code
srun --mem=8G --time=00:05:00 \
  singularity exec --nv /ceph/container/pytorch/pytorch_24.09.sif \
  pip install --user wandb
4. Run the Default Sweep
Inside the repo:

bash
Copy code
sh sh/sweep_nonlinear.sh
This will:

loop over default hyperparameter lists

create a unique W&B run ID for each combo

submit a training job

automatically submit a dependent evaluation job

log both phases to the same W&B run (if enabled)

5. Override Hyperparameters
You can override any parameter list directly when launching the sweep.

Example overriding all lists:

bash
Copy code
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
The script will:

iterate through all combinations

assign a unique WANDB_RUN_ID

submit one training job per combo

submit a matching evaluation job with --dependency=afterok

6. Minimal Custom Sweep Examples
Small sweep
bash
Copy code
K_LIST="4 5" \
DIM_LIST="64 128" \
sh sh/sweep_nonlinear.sh
Sweep with W&B enabled
bash
Copy code
USE_WANDB=1 \
WANDB_PROJECT="p3-experiments" \
WANDB_ENTITY="myname" \
K_LIST="4 8" \
DIM_LIST="128 256" \
sh sh/sweep_nonlinear.sh
Single experiment via sweep script
bash
Copy code
K_LIST="4" \
DIM_LIST="256" \
LR_LIST="0.001" \
USE_WANDB=1 \
sh sh/sweep_nonlinear.sh
7. Monitoring Jobs
bash
Copy code
squeue -u $(whoami)
Logs:

bash
Copy code
tail -n 40 MODEL_*.out
tail -n 40 MODEL_*.err

tail -n 40 EVALUATION_*.out
tail -n 40 EVALUATION_*.err
8. Outputs
Models:

Copy code
models/
Evaluation results:

php-template
Copy code
results/<species>/
W&B dashboard:

arduino
Copy code
https://wandb.ai/YOUR_ENTITY/YOUR_PROJECT
