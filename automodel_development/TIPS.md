# automodel — optional tips

Optional practices; adopt them where they fit the problem.

---

## Attach uncertainty to metrics

The meta-agent selects the "best" model from point estimates, but a validation-metric gap of, say, 0.102 vs. 0.105 may be pure optimizer/sampling noise. Before committing to one structure over another:

- Report an error bar on the validation metric — via bootstrap resampling of the validation set, or the spread across cross-validation folds.
- Or run a paired test on per-example residuals between the candidate and the best-so-far, so a change is kept only when the improvement is robust rather than within noise.

Keep the sources of variation apart: fitting, sampling and adaptive selection. Paired resampling for fixed
candidates measures conditional uncertainty; it does not repeat the search or remove its selection optimism (which
can also overfit cross-validation). Respect groups and time order when resampling. When a claim needs that evidence,
use an untouched check or repeat the whole selection inside an outer evaluation.

This is the cheapest guard against the search chasing noise. The right method is domain-specific (a Poisson-count likelihood, a classification metric, and an ODE misfit each call for different tests), which is why it is not prescribed in the core.

## Leaderboard

The shared attempt harness (Phase 2) already appends one fixed-schema record per fit. Building an append-only
`leaderboard.csv` across meta-iterations from it makes selection and plotting mechanical; its columns are
domain-specific (regression, PDE terms and neural architectures need different ones).

## Record trivial baselines

Where it makes sense for the problem (it may not for, say, a PDE), also record simple reference points — predict-the-mean, a linear regression, or the incumbent domain-standard model. If the discovered model barely beats the mean, that is critical to surface, and it contextualizes every later improvement.
