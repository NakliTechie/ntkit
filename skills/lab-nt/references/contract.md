# Phases 0 and 0.5: the contract, isolation and instruments

## Phase 0 — The research contract (interactive)

Work the idea with the user until it passes five gates, then write `plan/lab/<slug>/contract.md`. Never launch on a mushy goal; unfalsifiable goals are where infinite runs come from.

1. **Question** — one sentence: "can X do Y under constraint Z", not "explore X".
2. **Metric** — one scalar, chosen before the loop, fair across interventions, and read from the run's output, never the loop's prose. State the direction (higher or lower is better) and the **goal threshold** (GOAL-MET when crossed), or declare the campaign open-ended so the user picks that knowingly.
3. **Scope fence** — the paths the loop may change, as globs, plus explicit non-goals. A small surface keeps diffs reviewable, and "nothing left to try" only means something inside a fence.
4. **Budget ladder** — per-experiment cap (one build+bench cycle, N minutes of training); per-leg experiments and hours; per-campaign odometer; usd cap when the user allows paid model calls. Defaults are in `SKILL.md`.
5. **Noise floor** — measured in Phase 0.5, before the first experiment, and written into the contract. When the metric is computed over a dataset, also split off a **confirmation set** the loop never reads; it joins the lockbox.

Also record: the **gates** (commands that must pass on the same commit before its metric counts, such as an accuracy batch), **device** (`shared` when experiments compete for one GPU or one benchmark box), **forks** and **merge** if they differ from the defaults. Record a `merge: auto` grant only when the user gives it for this campaign.

Run the **prior-art check** before any experiment: the vault first (`/ask-nt`, when scholia is installed), then the repo and its `plan/`, then the web. A question already answered ends the campaign at leg zero, GOAL-MET by citation. When the question is a measured slow or costly spot, `/panel-nt --mine` (scholia, when installed) turns it into named techniques with checked citations and a benchmark spec, which become the first hypotheses; the spec's win condition is fixed before any run.

## Phase 0.5 — Isolate and instrument

- **Worktree:** `git worktree add .worktrees/lab-<slug> -b lab/<slug>` (ignore `.worktrees/` via `.git/info/exclude`), `plan/` symlinked from the main checkout, rebuild what doesn't travel. All experiment commits land on `lab/<slug>`; the user's checkout is never touched.
- **Noise floor:** re-measure the unchanged baseline at least three times and run `python3 $SKILL/bin/lab.py noise <v1> <v2> <v3>`. Write the spread into the contract. A gain inside the spread is noise: a +0.6 point move with a ±6 point interval is no result.
- **Lockbox:** the runner, metric extraction, gates and confirmation set live outside the fence. With the contract complete, hash them and write the sealed state file from the worktree root:
  `python3 $SKILL/bin/lab.py init plan/lab/<slug> --fence '<glob>' ... --lock '<glob>' ... --experiments <n> [--max-legs 5] [--lower-is-better] [--merge auto] [--surprise <threshold>]`
  It refuses an existing campaign, an empty lockbox, or a locked file inside the fence, and records the leg's start commit and the contract's hash. A change may never modify what measures it. (Sakana's AI Scientist once raised its own timeout instead of speeding up its code.) A wrong harness is PARKED for the human, not edited.
- **Shared-device rules** (when `device: shared`): the harness reads a canary, a metric with a known quiet value (for an inference engine, a reference engine's speed on a fixed row). A reading taken while the canary is off by more than the noise floor is discarded and re-taken, never used. Candidate and best-so-far are measured interleaved (A B A B), never one after the other. Time many repetitions per launch so launch cost does not swamp the kernel. Announce the run to other sessions that use the device.
- **Surprise threshold:** a result is HIGH surprise when |actual − predicted| exceeds it. Write it into the contract in metric units and pass it to `init` as `--surprise`; a sensible value is twice the noise floor, so a surprise inside noise never counts. Without it, the default is 10% of each experiment's prediction.
- **Journal:** `plan/lab/<slug>/journal.md`, append-only, one row per experiment: `id · proposer · hypothesis · predicted · what ran · result (harness number, verbatim) · surprise · gate · keep/revert · what it opened up`. Fork rows carry `f<i>`, child rows `c<n>`. The machine copy of proposer, prediction, result and surprise lives in the sealed `lab.json` (`lab.py summary` prints it). Rows written before this format have no proposer, prediction or surprise; leave them as they are, because past rows are never rewritten, and read the missing fields as absent.
