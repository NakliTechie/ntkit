# Phase 1: the leg loop

## One experiment

1. **Pick** the smallest experiment that could move the metric, after re-reading contract and journal.
2. **Dedup** against the journal, including fork and child rows. Two consecutive rejections with nothing new inside the fence ⇒ **DRY-WELL**.
3. **Count** it: `lab.py spend plan/lab/<slug>`. Exit 3 means the budget is gone ⇒ **BUDGET**.
4. **Run** inside the per-experiment cap. A blown cap is a failed experiment, never extended or retried with more time.
5. **Check scope**: `lab.py check plan/lab/<slug> --base <best-so-far SHA>`. A violation reverts the experiment and is journaled as such.
6. **Gate, then measure.** Run every contract gate on this commit. A failed gate is a failed experiment: its metric does not count. Then read the harness number (interleaved with best-so-far on a shared device) and put it in the journal verbatim.
7. **Keep or revert** by `lab.py keep plan/lab/<slug> --noise <floor> --gate pass|fail --base <best readings> --cand <candidate readings>`, or `--paired <per-item gains>` for a dataset metric (keep only when the paired 95% interval excludes zero). KEEP commits `lab <id>: <what> — <old → new>`. A kept speed or cost gain names its limiter and rules out cached, skipped or failed work (`SUBSTANCE.md` §6.16). Anything else reverts clean. The branch tip is always the best-known state. A kept experiment adds no comment that explains a workaround; if the change needs one, fix the cause or leave the experiment reverted (`SUBSTANCE.md` §6.15).
8. **Journal** the row and go on. Budgets and thresholds are the exits.

Run from contract, journal and branch tip, not from recall of earlier experiments. Negative results are data: a reverted idea stays in the journal so no fork, child or later leg repeats it.

## Critic on cadence

At each critic point a fresh subagent sees only the contract and the journal and answers four questions: circling? drifting off-contract? gaming the metric? diminishing returns? Its verdict is a journal row. Two consecutive "diminishing" verdicts end the leg STAGNANT. One critic pass per point. Before it, confirm the journal is current enough to resume the leg from files alone, then fold finished-experiment detail out of context.

## Fork-and-flush (downward recursion, breadth)

Independent runs of one agent settle in different "idea basins" and more compute on one run does not leave its basin; forking the workspace with an empty conversation does (Fork-and-Flush, arXiv:2610.07447: 0.78 against 0.47 for one run at equal compute, 12 of 13 tasks).

- **When:** at the experiment numbers `lab.py forks plan/lab/<slug>` prints (one third and two thirds of a leg of 12 or more experiments), unless the contract says `forks: off`.
- **How:** from the branch tip, create K worktrees `.worktrees/lab-<slug>-f<i>` on branches `lab/<slug>-f<i>`. Launch K fresh subagents with no conversation history. Each brief holds only: the contract, the journal, its fork id, its experiment allowance, and the loop rules above. Each experiment a fork runs is counted with `lab.py spend`. On `device: shared`, forks run one after another, never in parallel, because parallel runs corrupt each other's measurements.
- **Select:** re-measure each fork tip against the current tip with the harness (gate first, interleaved on a shared device), then `lab.py check`. The best fork that `lab.py keep` accepts becomes the new tip; if none does, the tip stays. Remove the fork worktrees and branches; their journal rows stay.
- **Flush the coordinator too:** after selection, fold the loop's own context to contract + journal + tip before the next experiment.

## Child campaigns (downward recursion, depth)

Use a child when an experiment exposes a sub-question with its own scalar metric that a short campaign can settle, such as "the best tile size for this kernel shape" inside "make this kernel faster".

1. **Open:** `lab.py child plan/lab/<slug> plan/lab/<slug>/child-<n> --experiments <m> [--fence '<narrower glob>']`. It refuses beyond max depth (default 2), more than half of the parent's remaining experiments, or a fence outside the parent's; the child inherits every parent lock. Write `child-<n>/contract.md`: question, metric (read by a locked harness), threshold, fence, budget, and its own noise floor.
2. **Run:** one fresh subagent with the child contract, on branch `lab/<slug>/c<n>` from the parent tip, in its own worktree, under these same loop rules. It may open its own child if depth allows. One leg only; it never re-arms. On `device: shared` the parent waits while the child measures.
3. **Return:** the child writes its leg report in its own directory. The parent journals one row: `c<n> · question · end state · best metric · SHA`. Merging the child's tip into the parent is then an ordinary parent experiment: gate, measure with the parent harness, `lab.py check`, keep or revert.
