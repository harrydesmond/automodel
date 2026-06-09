---
name: setup
entry: No `CONTEXT.md` artifact in project root folder
exit: Set up completed and documented in CONTEXT.md.
description: First phase. Confirm goal and terminology, prepare data splits, define loss/metrics, and set up parameter optimization.
---

# Phase 1 — Setup

---

## Steps

### 0. Feasibility
- Confirm that subagents can be spawned and read, write, and execute files in the project directory (and subdirectories)
- Confirm with the user their intended language/runtime and that required libraries are available

### 1. Goal
Confirm with the user:
- Check for any useful info in the skill's `references` folder
- Context, intended goal, and scope of the model
- Domain lingo to use throughout (e.g. *loss function* vs. *cost function* / *features* vs. *covariates* / *training* vs. *calibration*)
- Whether the model needs to meet certain properties (e.g. differentiability, positivity, boundedness, some equivariance, adhere to some physical constraints, etc.)

### 2. Existing code
If code already exists, review it with the user and decide whether to reuse or rewrite. Use these skip signals: if train/val/test split files exist, skip to Metrics; if an optimization routine exists, skip to the context dump.

### 3. Data
Identify and confirm:
- Where the data lives and which files/tables are relevant
- Intended input and output variables
- Whether data is present, sufficient, and clean; flag any cleaning needs
- A split strategy that produces `train.X`, `validation.X`, and `test.X` (e.g. `.csv`, `.mat`, `.rdata`) stored in a consistent location

### 4. Metrics
Define and confirm with the user:
- Objective/loss function for training/calibration
- Evaluation metrics for the validation and test sets
- *Always include run-time and memory usage as metrics* — these gate the feasibility of the iterative loop

### 5. Optimization routine
Implement a parameter optimization routine, or confirm an existing one, e.g. gradient descent or a black-box method (PSO, Nelder-Mead). Prefer libraries over from-scratch implementations.

---

## Context dump (end of phase)

Create `CONTEXT.md` in the project root using `assets/CONTEXT.md` as a starting point. Fill in the Phase 1 sections:
- Goal and scope
- Language/runtime and key libraries
- Data location, variable names, split strategy
- Chosen loss/cost/objective function and evaluation metrics
- Brief description of the optimization routine

Then **compact your conversation history** before proceeding to Phase 2 — Baseline Model (if auto-compact is not enabled, ask the user to trigger it).
