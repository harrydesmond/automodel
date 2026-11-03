# Checks worth considering

A menu, not a checklist. Applications differ widely: a closed-form fit evaluated in seconds on one public dataset
needs few of these, while a large search on expensive simulated data may need most. For each item, ask what a wrong
result would cost and what the check costs, pick what fits, and record in `CONTEXT.md` what you adopted or skipped and
why. Items marked ★ are cheap and useful in almost every application; "N/A because …" is a valid answer (e.g. no
held-out check in an in-sample MDL search — then say what the criterion does and does not pay for, such as the number of
candidates tried, and let the user decide).

## Setup (Phase 1)
- ★ **Use and claims.** What will the model be used for (input range, extrapolation, derivatives, runtime vs size vs
  interpretability)? Which region will the final claims cover, and do the splits and the external check reach its
  hard parts?
- ★ **Rules as code.** Write the selection score, complexity measure, tie rule and constraints as code. Ask how an
  agent could satisfy them cheaply (rounding constants, tying parameters, moving complexity into "fixed" literals) and
  close the loophole before the search. Define which optimum is scored (a score computed at the fitted optimum, such as a
  curvature-based complexity term, must itself be converged), and apply any canonical rewrite or simplification to
  references and candidates alike. Test the code against the agreed text (e.g. a unit test that each score uses the
  ranges and subsets the design states): a scorer that silently differs from the design misdirects every round.
- **Headroom and stop rule.** Estimate how much improvement is possible before the search (e.g. a flexible model that
  reproduces the incumbent at matched flexibility, cross-validated by group) and fix a stop rule. A round that finds
  nothing means "not found in this pool", not "optimal"; retract such verdicts where they were written.
- ★ **Shared vs group-specific parameters.** If the data come in groups (subjects, sites, datasets, operating
  conditions), decide which structure and coefficients are shared, which are refitted per group, and what the final
  check freezes.
- ★ **External check locked** (if there is one). Make the held-out data unreadable to the search in code, not only in prompts, before any
  evaluation (reference models included), and log every access.
- ★ **Data provenance.** List every dataset available (keep independent ones for replication) and what data every
  inherited parameter and preprocessing statistic (normalisations, calibrated baseline constants) was fitted on;
  anything fitted on validation or test data makes those scores partly in-sample.
- **Score noise.** Estimate how much the selection score varies between data blocks (resampling; rolling origin for time
  series) and set complexity penalties and acceptance thresholds against it: picking the best of many candidates on one
  small validation block over-fits that block.
- **Generated targets.** If a simulator or pipeline produces the data, check it received the inputs requested, sweep
  inputs through limits and thresholds for jumps, and measure its accuracy floor against the target accuracy; pin
  versions and record a data manifest that results refer to.
- **Independent review.** When data or compute are expensive, have a fresh agent review the setup before generating
  data or starting the loop (and, in heavy searches, each meta-iteration's review before the next launch).

## Baseline and evaluator (Phase 2)
- ★ **Reproduce references.** The evaluator should reproduce published or incumbent results (and competing methods
  should be refitted with the same optimizer and budget), so every candidate is comparable with them. Pin each
  reference's exact form and note whether it meets the candidates' constraints.
- ★ **Null check.** A structural modification set to its null value must reproduce the baseline exactly.
- ★ **Where the baseline fails.** Profile the data and the baseline residuals (by region, group, limit or regime)
  before searching; explain residuals in limiting regimes against known behaviour; estimate the share of the error that
  comes from any component that will stay fixed, and let the user decide whether to unfreeze it.
- **Loss shares.** Check which rows or regions dominate the objective, and that a subsample objective transfers to the
  full data.
- **Scorer tests.** Missing or unmeasured ≠ pass; an empty test set ≠ pass; non-finite outputs are rejected; a constant
  penalty for infeasible candidates creates plateaus where optimizers stop and report success; where possible, check
  constraints analytically (singular arguments, bounds) rather than only at sampled points. Exercise every operator or
  feature the search may use before the loop.
- **One record of every fit.** The fitting routine appends every fit (screens included) to one fixed-schema record with
  the data and protocol versions and who proposed the candidate; fronts and summaries are built only from it. Keep the
  agents' prompts and returns in the project: harness transcripts expire.
- **Infrastructure.** The end-to-end test writes every file type the loop needs and exercises remote jobs, timeouts,
  success markers and resumption after an interruption. Parallel agents sharing one machine need core and memory
  budgets.

## Iterate (Phase 3)
- ★ **Convergence before comparison.** Record why each fit stopped; refit the shortlist with more starts and a new
  seed before declaring a winner; hold reference models to the same standard; seed the next round from converged
  values. Start final refits from every recorded optimum, and treat a final refit worse than the search as an error.
  When fits are cheap, fit every candidate robustly: under-converged fits hide winners, not only false ones.
- **Screen cheaply** when full fits are expensive: test candidate changes with quick fits (one component, a subset, train
  only) first; keep validation for scored attempts and reviews.
- **Components.** When models are built from named parts, fit new parts on their own targets first, then jointly; at
  review, merge overlapping parts and swap the best parts between agents.
- **Diagnose failing gates.** Before giving an agent a region, constraint or gate that fails, check what drives the
  failure (e.g. correlate the failures with the full model's error): it may be accuracy elsewhere, not the obvious
  component.
- **Protocol changes.** Version the score and rules; when they change, rescore earlier candidates and references.
- **Identifiability.** Flag parameters at bounds, running away or trading off against each other; report it for
  finalists.

## Finalize (Phase 4)
- ★ **Pre-register.** Before the external check, write down (and commit, if under version control) the models to be
  tested, the decision rule and the claims. Put the baseline through the same final refit and check, and decide on the
  paired gain. If the final refit frees constants or changes structure, validate the result before the check: the model
  tested must be the model selected.
- ★ **Expect shrinkage.** Validation-to-test shrinkage is normal; agreement shows consistency, not absence of
  selection bias.
- **Stress the claims.** Fresh samples, corners and edges of the claimed region, dense grids containing every claimed
  endpoint; tag each claim with what it was checked on.
- **Interpretations are hypotheses** until tested by an intervention; compute every reported number with one script.
- **Independent audit** for high-stakes results: a fresh agent reimplements the evaluation; reproduce its findings
  before applying them, and rerun its checks after fixes.
