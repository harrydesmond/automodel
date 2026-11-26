# Reaction–diffusion front fits
1D model u_t = D u_xx + f(u) on x in [0, 10] mm, fitted to 40 measured concentration profiles (8 experiments x 5
times each, `data/profiles/exp*_t*.csv`, normalised so the far field is 1). Current f(u) = r u (1 - u) (Fisher–KPP).
Residuals are structured near the front (front too steep at early times, too slow late).
- `model/rd.py`: method-of-lines solver; `solve(params, f_terms, x, t)`.
- `fit/fit_one.py <config.yaml>`: fits D and the f(u) coefficients (multi-start, 16 processes), writes `fit.json`.
- `fit/submit_fit.sh`: sbatch wrapper; one fit = one job, ~20 min on 16 cores.
