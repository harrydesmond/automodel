# automodel — optional tips

## Uncertainty
Use paired resampling for fixed-candidate comparisons, respecting groups and time order. Keep sampling, fitting and
adaptive-selection uncertainty separate: bootstrap intervals or fold variation do not remove search optimism.
Independent predictive claims may need an untouched check or nested evaluation (`checks.md`).

## References
Where informative and affordable, include simple baselines and a strong alternative from another model family.
Compare on the same domain and target; verify input/output conventions with reference cases. Document differing
training data and budgets. These comparisons contextualise gains; they do not require retraining every reference
with the candidate optimizer.
