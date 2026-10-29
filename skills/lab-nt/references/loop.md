# Phase 1: the leg loop

`$LAB` below is `python3 $SKILL/bin/lab.py`, run from the campaign worktree's root; `<dir>` is `plan/lab/<slug>` (or a child's or fork's directory under it). Its exit codes: 0 ok or KEEP, 1 refused, 2 usage, 3 budget, 4 REVERT.

## One experiment

1. **Pick** the smallest experiment that could move the metric, after re-reading contract and journal.
2. **Dedup** against the journal, including fork and child rows. Two consecutive rejections with nothing new inside the fence ⇒ **DRY-WELL**.
3. **Predict** before anything runs: `$LAB predict <dir> <id> --proposer <who> --predicted <metric value>`. The proposer is the provider and model that proposed the idea (`opencode/<model>`, `claude-opus-5-5`), or the vault note path it came from; the prediction is the harness number the proposer expects. `keep` and `record` refuse an id with no prediction, and the sealed state file keeps the prediction from changing once the result is known.
4. **Book** it: `$LAB spend <dir>`. Exit 3 books nothing and means the budget is gone ⇒ **BUDGET**.
5. **Run** inside the per-experiment cap. A blown cap is a failed experiment, never extended or retried with more time: `$LAB record <dir> <id> --outcome fail`.
6. **Check scope**: `$LAB check <dir> --base <best-so-far SHA>`. A violation reverts the experiment and is journaled as such (`$LAB record <dir> <id> --outcome fail`, with `--actual` when a number was read).
7. **Measure, then gate.** Read the harness number (interleaved with best-so-far on a shared device) and put it in the journal verbatim. When the gain beats the noise floor (the rule `$LAB keep` applies), run every contract gate on the same commit; a candidate that would revert anyway skips the gates, because slow gates are where a leg's hours go. A failed gate is a failed experiment: its metric does not count, unless every failure is on the start commit's baseline (`--gate known`).
8. **Keep or revert** by `$LAB keep <dir> --id <id> --gate pass|fail|known [--failures <id> ...] --noise <floor> --base <best readings> --cand <candidate readings>`, or `--paired <per-item gains> --actual <candidate metric>` (at least 10 items) for a dataset metric. Call it once per experiment, after the gates, because it records the result: the outcome, the actual metric (the mean of `--cand` unless `--actual` is given) and the surprise. Exit 0 KEEP commits `lab <id>: <what> — <old → new>`; exit 4 REVERT resets to the tip. A kept speed or cost gain names its limiter and rules out cached, skipped or failed work (`SUBSTANCE.md` §6.16). A passing gate counts only for the paths it executed: before a keep, show that the gate run reached every path the change touched (a dispatch log, coverage counter or trace from that run), and that it compared correctness with a reference outside the work, never with best-so-far, which may carry the same fault (`SUBSTANCE.md` §6.17). A touched path the gate never reached is a failed gate until the contract's gates are widened. The branch tip is always the best-known state. A kept experiment adds no comment that explains a workaround; if the change needs one, fix the cause or leave the experiment reverted (`SUBSTANCE.md` §6.15).
   **Simple-fix control.** When a candidate adds a new mechanism (not a parameter tweak), first apply the cheapest standard fix aimed at the same symptom to best-so-far (clipping, a learning-rate or warm-up change, a bigger cache, a known flag) and measure it like a candidate; pass its readings as `--control`, and `keep` reverts unless the candidate also beats the control by more than the noise. Name the control in the journal row. Why: an independent replication of TreeOPSD (arXiv:2610.23181) found its +4.97-point lead over GRPO fell to +0.08 once the comparison baseline got standard ratio clipping; the bound, not the new credit, carried the gain.
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

## Fork-and-flush (downward recursion, breadth)

Independent runs of one agent settle in different "idea basins" and more compute on one run does not leave its basin; forking the workspace with an empty conversation does (Fork-and-Flush, arXiv:2610.07447: 0.78 against 0.47 for one run at equal compute, 12 of 13 tasks).

- **When:** at the experiment numbers `$LAB forks <dir>` prints (one third and two thirds of a leg of 12 or more experiments), unless the contract says `forks: off`.
- **Carve:** for each fork, `$LAB fork <dir> <dir>/f<p>-<i> --experiments <e>` (fork point p, fork i). Each fork gets its own sealed state with its share of the budget, so parallel forks never write the same file and none can spend another's experiments. A fork does not fork again.
- **Run:** from the branch tip, create K worktrees `.worktrees/lab-<slug>-f<p>-<i>` on branches `lab/<slug>-f<p>-<i>`. Launch K fresh subagents with no conversation history. Each brief holds only: the contract, the journal, its fork directory, and the loop rules above; it books with `$LAB spend <its fork dir>`. On `device: shared`, forks run one after another, never in parallel, because parallel runs corrupt each other's measurements.
- **Select:** before re-measuring, predict each fork tip in the parent (`$LAB predict <dir> f<p>-<i> --proposer <the fork's proposer> --predicted <the fork's own best reading>`). Re-measure each fork tip against the current tip with the harness (interleaved on a shared device), run the gates on the leading fork, then `$LAB check <dir> --base <current tip>` in the leading fork's worktree. The best fork that `$LAB keep --id f<p>-<i>` accepts becomes the new tip; if none does, the tip stays. Remove the fork worktrees and branches; their journal rows stay.
- **Flush the coordinator too:** after selection, fold the loop's own context to contract + journal + tip before the next experiment.

## Child campaigns (downward recursion, depth)

Use a child when an experiment exposes a sub-question with its own scalar metric that a short campaign can settle, such as "the best tile size for this kernel shape" inside "make this kernel faster".

1. **Write** `<dir>/child-<n>/contract.md`: question, metric (read by a locked harness), threshold, fence, budget, and its own noise floor.
2. **Open:** `$LAB child <dir> <dir>/child-<n> --experiments <m> [--fence '<narrower glob>']`. It refuses beyond max depth (default 2), more than half of the parent's remaining experiments, or a fence outside the parent's; the child inherits every parent lock, and its `check` applies the fence of every ancestor.
3. **Run:** one fresh subagent with the child contract, on branch `lab/<slug>/c<n>` from the parent tip, in its own worktree, under these same loop rules. It may open its own child if depth allows. One leg only: `$LAB leg` refuses a child. On `device: shared` the parent waits while the child measures.
4. **Return:** the child records its end with `$LAB end`, writes its leg report in its own directory, and the parent journals one row: `c<n> · question · end state · best metric · SHA`. Merging the child's tip into the parent is then an ordinary parent experiment: predict it (the child's best reading is the prediction), measure with the parent harness, gates, `$LAB check`, keep or revert.
