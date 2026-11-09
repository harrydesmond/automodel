# Checks

## Required in every search
- **Decision rule read back** and shown on a known reference (Phase 1); rule changes are new protocol versions, and
  earlier comparable candidates and references are rescored.
- **Evaluator tests** (Phase 2) also cover later acceptance and reporting code: known passes/failures, expected
  coverage, finite values, named populations and denominators. Test scoring, ties and complexity against the plan;
  references and candidates use the same implementation. Test rounding, tying and fixed literals against the agreed complexity accounting;
  apply canonical rewrites consistently.
- **One record per fit** (Phase 2), screens and failures included; tables and fronts are built only from the records.
- **Budget enforced** by the harness.
- **Convergence for finalists and references:** record each fit's stop reason against an agreed numerical or budget
  criterion; refit from the recorded optima plus new starts; compare the variation of the selection score itself with
  the claimed gain. A worse result on the same fitting objective never overwrites a better valid fit. Repeated starts
  show stability, not a global optimum. When fits are cheap, fit every candidate this way: under-converged fits hide
  winners as well as producing false ones. Keep the score's definition (e.g. a score evaluated at the likelihood
  optimum) rather than optimising a different combined objective.
- **External evidence** (if any): locked before any scoring, exposure recorded, pre-registration before use (Phases 1
  and 4).

## Conditional menu
Choose by the cost of a wrong result versus the cost of the check; record what you adopted and "N/A because …".

**Setup**
- *Shared vs group-specific parameters* when data come in groups: what is shared, what is refitted per group, what
  the final check freezes.
- *Data provenance:* what data each inherited parameter or preprocessing statistic was fitted on; anything fitted on
  validation or test data makes those scores partly in-sample.
- *Score noise:* how much the score varies between data blocks (resampling; rolling origin for time series); set
  hybrid penalties, tie tolerances and statistical thresholds against it on development data, matching the planned
  size and composition of new evidence before it is opened.
- *Headroom and stop rule:* where cheap, estimate headroom from a credible reference or flexible fit that can recover
  the incumbent. A null search reports only what was not found under its budget.
- *Generated targets:* check requested inputs and returned metadata, units and conventions; check thresholds and
  tighten numerical controls on representative and difficult cases; verify loaded implementation/version and record data identity. Distinguish
  numerical stability, disagreement between reference models, observation noise and fixed-template residuals; none
  alone certifies an accuracy floor.
- *Independent review of the setup* before expensive data generation or a large search.

**Baseline**
- *Reproduce references* with their declared settings; use matched fitting budgets for structural comparisons where applicable.
- *Where the baseline fails:* residuals by region, group, limit or regime, and the error share of components that stay
  fixed. Test fixed components independently: learned parts can compensate for their errors. Unfreezing needs approval.
- *Loss shares:* which rows dominate the objective; does a subsample objective transfer to the full data.
- *Constraints analytically* (singular arguments, bounds) where sampled checks can miss them; a constant penalty for
  infeasible candidates creates plateaus where optimizers stop and report success.
- *Operators and interfaces* tested when introduced (not an enumeration of an open search space).
- *Infrastructure:* the pilot exercises remote jobs, timeouts, validators and resumption; parallel agents on one
  machine need core and memory budgets.

**Iterate**
- *Screen cheaply* only when full fits are expensive (one component, a subset, training data only); spend a small
  declared sample of refits on rejected candidates to check for false eliminations.
- *Components:* fit new parts on their own targets first, then jointly; merge overlapping parts and swap the best
  between agents. Before importing another agent's helper or fitted component, check its inputs, units, conventions
  and known or null cases against the shared evaluator; record side calibration data and check alternative sources.
- *Gates as well as the score:* report each leader's search-gate values and eligibility. A candidate failing a hard
  search gate cannot become the incumbent; keep it only as a labelled exploratory alternative. Keep deferred acceptance
  checks unevaluated until their authorised phase. Carry agreed runtime or size ceilings into every direction.
- *Runtime gates:* specify hardware, workload and warm/cold state; report repeats and spread. Interleave reference
  comparisons where appropriate; measure compilation separately. Speed-ups need not transfer between machines.
- *Surroundings:* test every finalist, refits and add-on corrections included, on the agreed surrounding domain and
  limits: regularised or flexible parts can blow up just outside the fitted domain. Loss, regularisation or taper
  changes that alter the objective or requirements need approval.
- *Identifiability:* flag parameters at bounds, running away or trading off; report it for finalists.

**Finalize**
- *Stress the claims* with a budgeted fresh sample and targeted boundary, endpoint and singularity checks; label
  sampled accuracy as such (a region-wide guarantee needs analytic bounds or a certified search).
- *Interpretations are hypotheses* until tested by an intervention.
- *Number audit:* check reported quantities against identified records, units, populations and rounding; fail on
  mismatches and state coverage. Finding the number elsewhere in a document is insufficient.
- *Independent audit* for high-stakes results: a fresh agent reimplements the evaluation; reproduce its findings
  before applying them, and audit the repairs too.
