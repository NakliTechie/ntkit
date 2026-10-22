# Phase 1: the leg loop

`$LAB` below is `python3 $SKILL/bin/lab.py`, run from the campaign worktree's root; `<dir>` is `plan/lab/<slug>` (or a child's or fork's directory under it). Its exit codes: 0 ok or KEEP, 1 refused, 2 usage, 3 budget, 4 REVERT.

## One experiment

1. **Pick** the smallest experiment that could move the metric, after re-reading contract and journal.
2. **Dedup** against the journal, including fork and child rows. Two consecutive rejections with nothing new inside the fence ⇒ **DRY-WELL**.
3. **Book** it: `$LAB spend <dir>`. Exit 3 books nothing and means the budget is gone ⇒ **BUDGET**.
4. **Run** inside the per-experiment cap. A blown cap is a failed experiment, never extended or retried with more time.
5. **Check scope**: `$LAB check <dir> --base <best-so-far SHA>`. A violation reverts the experiment and is journaled as such.
6. **Measure, then gate.** Read the harness number (interleaved with best-so-far on a shared device) and put it in the journal verbatim. When `$LAB keep` would return KEEP on that reading, run every contract gate on the same commit; a candidate that would revert anyway skips the gates, because slow gates are where a leg's hours go. A failed gate is a failed experiment: its metric does not count.
7. **Keep or revert** by `$LAB keep <dir> --gate pass|fail --noise <floor> --base <best readings> --cand <candidate readings>`, or `--paired <per-item gains>` (at least 10 items) for a dataset metric. Exit 0 KEEP commits `lab <id>: <what> — <old → new>`; exit 4 REVERT resets to the tip. A kept speed or cost gain names its limiter and rules out cached, skipped or failed work (`SUBSTANCE.md` §6.16). The branch tip is always the best-known state. A kept experiment adds no comment that explains a workaround; if the change needs one, fix the cause or leave the experiment reverted (`SUBSTANCE.md` §6.15).
8. **Journal** the row and go on. Budgets and thresholds are the exits.

Run from contract, journal and branch tip, not from recall of earlier experiments. Negative results are data: a reverted idea stays in the journal so no fork, child or later leg repeats it. Never edit `lab.json` by hand: it is sealed, and every `$LAB` call refuses a state file that no longer matches its seal.

## Critic on cadence

At each critic point a fresh subagent sees only the contract and the journal and answers four questions: circling? drifting off-contract? gaming the metric? diminishing returns? Its verdict is a journal row. Two consecutive "diminishing" verdicts end the leg STAGNANT. One critic pass per point. Before it, confirm the journal is current enough to resume the leg from files alone, then fold finished-experiment detail out of context.

## Fork-and-flush (downward recursion, breadth)

Independent runs of one agent settle in different "idea basins" and more compute on one run does not leave its basin; forking the workspace with an empty conversation does (Fork-and-Flush, arXiv:2610.07447: 0.78 against 0.47 for one run at equal compute, 12 of 13 tasks).

- **When:** at the experiment numbers `$LAB forks <dir>` prints (one third and two thirds of a leg of 12 or more experiments), unless the contract says `forks: off`.
- **Carve:** for each fork, `$LAB fork <dir> <dir>/f<p>-<i> --experiments <e>` (fork point p, fork i). Each fork gets its own sealed state with its share of the budget, so parallel forks never write the same file and none can spend another's experiments. A fork does not fork again.
- **Run:** from the branch tip, create K worktrees `.worktrees/lab-<slug>-f<p>-<i>` on branches `lab/<slug>-f<p>-<i>`. Launch K fresh subagents with no conversation history. Each brief holds only: the contract, the journal, its fork directory, and the loop rules above; it books with `$LAB spend <its fork dir>`. On `device: shared`, forks run one after another, never in parallel, because parallel runs corrupt each other's measurements.
- **Select:** re-measure each fork tip against the current tip with the harness (interleaved on a shared device), run the gates on the leading fork, then `$LAB check <dir> --base <current tip>` in the leading fork's worktree. The best fork that `$LAB keep` accepts becomes the new tip; if none does, the tip stays. Remove the fork worktrees and branches; their journal rows stay.
- **Flush the coordinator too:** after selection, fold the loop's own context to contract + journal + tip before the next experiment.

## Child campaigns (downward recursion, depth)

Use a child when an experiment exposes a sub-question with its own scalar metric that a short campaign can settle, such as "the best tile size for this kernel shape" inside "make this kernel faster".

1. **Write** `<dir>/child-<n>/contract.md`: question, metric (read by a locked harness), threshold, fence, budget, and its own noise floor.
2. **Open:** `$LAB child <dir> <dir>/child-<n> --experiments <m> [--fence '<narrower glob>']`. It refuses beyond max depth (default 2), more than half of the parent's remaining experiments, or a fence outside the parent's; the child inherits every parent lock, and its `check` applies the fence of every ancestor.
3. **Run:** one fresh subagent with the child contract, on branch `lab/<slug>/c<n>` from the parent tip, in its own worktree, under these same loop rules. It may open its own child if depth allows. One leg only: `$LAB leg` refuses a child. On `device: shared` the parent waits while the child measures.
4. **Return:** the child records its end with `$LAB end`, writes its leg report in its own directory, and the parent journals one row: `c<n> · question · end state · best metric · SHA`. Merging the child's tip into the parent is then an ordinary parent experiment: measure with the parent harness, gates, `$LAB check`, keep or revert.
