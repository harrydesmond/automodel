#!/bin/bash
#SBATCH -p cmb-priority,berg-priority,cbass
#SBATCH -N 1 --ntasks-per-node=16 --mem-per-cpu=2000
#SBATCH -o fit-%j.out
export PATH=/usr/local/shared/python/3.11.4/bin:$PATH
cd "$SLURM_SUBMIT_DIR"
python3 fit/fit_one.py "$1"
