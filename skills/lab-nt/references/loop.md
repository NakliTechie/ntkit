# Phase 1: the leg loop

`$LAB` below is `python3 $SKILL/bin/lab.py`, run from the campaign worktree's root; `<dir>` is `plan/lab/<slug>` (or a child's or fork's directory under it). Its exit codes: 0 ok or KEEP, 1 refused, 2 usage, 3 budget, 4 REVERT.

## One experiment

1. **Pick** the smallest experiment that could move the metric, after re-reading contract and journal.
2. **Dedup** against the journal, including fork and child rows. Two consecutive rejections with nothing new inside the fence ⇒ **DRY-WELL**.
3. **Predict** before anything runs: `$LAB predict <dir> <id> --proposer <who> --predicted <metric value>`. The proposer is the provider and model that proposed the idea (`opencode/<model>`, `claude-opus-5-5`), or the vault note path it came from; the prediction is the harness number the proposer expects. `keep` and `record` refuse an id with no prediction, and the sealed state file keeps the prediction from changing once the result is known.
4. **Book** it: `$LAB spend <dir>`. Exit 3 books nothing and means the budget is gone ⇒ **BUDGET**.
5. **Run** inside the per-experiment cap. A blown cap is a failed experiment, never extended or retried with more time: `$LAB record <dir> <id> --outcome fail`.
6. **Check scope**: `$LAB check <dir> --base <best-so-far SHA>`; `keep` also runs this check against the start commit and reverts on a violation. A violation reverts the experiment and is journaled as such (`$LAB record <dir> <id> --outcome fail`, with `--actual` when a number was read).
7. **Measure, then gate.** Read the harness number, alternating candidate and best-so-far runs on every timed metric, and put it in the journal verbatim. When the gain beats the noise floor (the rule `$LAB keep` applies), run every contract gate on the same commit; a candidate that would revert anyway skips the gates, because slow gates are where a leg's hours go. A failed gate is a failed experiment: its metric does not count, unless every failure is on the start commit's baseline (`--gate known`).
8. **Keep or revert** by `$LAB keep <dir> --id <id> --gate pass|fail|known [--failures <id> ...] --noise <floor> --base <best readings> --cand <candidate readings>`, or `--paired <per-item gains> --paired-cand <candidate's per-item scores>` (at least 10 items, same order) for a dataset metric that is the mean of its item scores. Call it once per experiment, after the gates, because it records the result: the outcome, the actual metric (the mean of `--cand` or `--paired-cand`; `keep` refuses `--actual`) and the surprise. Exit 0 KEEP commits `lab <id>: <what> — <old → new>`; exit 4 REVERT resets to the tip. A kept speed or cost gain names its limiter and rules out cached, skipped or failed work (`SUBSTANCE.md` §6.16). A passing gate counts only for the paths it executed: before a keep, show that the gate run reached every path the change touched (a dispatch log, coverage counter or trace from that run), and that it compared correctness with a reference outside the work, never with best-so-far, which may carry the same fault (`SUBSTANCE.md` §6.17). A touched path the gate never reached is a failed gate until the contract's gates are widened. The branch tip is always the best-known state. A kept experiment adds no comment that explains a workaround; if the change needs one, fix the cause or leave the experiment reverted (`SUBSTANCE.md` §6.15).
   **Simple-fix control.** When a candidate adds a new mechanism (not a parameter tweak), first apply the cheapest standard fix aimed at the same symptom to best-so-far (clipping, a learning-rate or warm-up change, a bigger cache, a known flag) and measure it like a candidate; pass its readings as `--control`, and `keep` reverts unless the candidate also beats the control by more than the noise. Name the control in the journal row.
   **A HIGH-surprise win is re-measured.** When `keep` would keep a HIGH-surprise result, it refuses until you pass `--confirm-base <readings> --confirm <readings>` (or `--confirm-paired <gains>`): fresh readings of best-so-far and the candidate, at least 3 each, taken alternately after the first reading. The win counts only if the gain between them beats the noise, because over many experiments the biggest win is partly luck.
   **Save every revert.** Before reverting, write the experiment's diff to `<dir>/reverted/<id>.patch` (`git diff <best-so-far SHA> > <dir>/reverted/<id>.patch`) and name it in the journal row with its readings and verdict, so near misses can be combined later.
9. **Journal** the row, copying proposer, prediction and the surprise line from `$LAB`'s output, and go on. Budgets and thresholds are the exits.

## Blockers are work

Whatever stops the loop is the next problem to solve, with the same discipline as an experiment: a hypothesis, one
diagnostic batch, a journal row. A gate failing for a reason the candidate did not cause, a harness or device fault,
and a decision outside the contract are all blockers. The loop explores them as it explores a surprise.

**Stalls and repeated calls are blockers too** (`SUBSTANCE.md` §6.18 and §6.19): four checks in a row on one target with the same result, or one call repeated a third time with the same arguments and nothing changed between. Write two to four hypotheses as journal rows and test the cheapest with a minimal reproduction before the next edit.

1. **Classify at the first repeat.** A failure seen twice for one cause is diagnosed before anything reruns it.
   Run the failing check on the start commit: the same failure there goes on the baseline (`$LAB baseline`) and the
   loop goes on; a candidate-caused failure is fixed or reverted; a harness or device fault is fixed when the fix
   lies outside the lockbox (environment, device, scripts the contract does not lock).
2. **Fix within authority without asking:** anything inside the fence, the environment, the device, or a child
   campaign for a sub-question the blocker exposes.
3. **Only the owner can change a locked file, the contract, or spend.** Write one question with the evidence, the
   options, a recommendation and a default, then keep going on `lab/<slug>-prov`: each provisional experiment is
   measured against the previous provisional tip, its journal row is marked provisional, and nothing is kept. When the
   answer arrives, the provisional chain becomes one experiment measured against the real tip; an approved change to
   a locked file seals a successor campaign whose contract names its predecessor and carries its noise floor when the
   timed path is unchanged.
4. **PARKED** only when no path within authority remains and no provisional work makes sense.

**Surprise is a result.** Surprise is actual minus predicted, sign kept; `$LAB` also prints its absolute value and marks it HIGH above the contract's threshold (default: 10% of the prediction). A HIGH-surprise experiment stays in the journal as a finding even when it reverts: write what the proposer expected, what happened instead, and what that suggests. A failure in a direction nobody predicted is worth more to the next idea than a near-miss that matched its prediction.

Run from contract, journal and branch tip, not from recall of earlier experiments. Negative results are data: a reverted idea stays in the journal so no fork, child or later leg repeats it. Never edit `lab.json` by hand: it is sealed, and every `$LAB` call refuses a state file that no longer matches its seal.

## Critic on cadence

At each critic point a fresh subagent sees only the contract and the journal and answers four questions: circling? drifting off-contract? gaming the metric? diminishing returns? Its verdict is a journal row. Two consecutive "diminishing" verdicts end the leg STAGNANT. One critic pass per point. Before it, confirm the journal is current enough to resume the leg from files alone, then fold finished-experiment detail out of context.

## Forks and children

At a fork point `$LAB forks <dir>` prints, or when an experiment exposes a sub-question with its own scalar metric, read `references/recursion.md` and follow it.
