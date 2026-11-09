# Forks and child campaigns

Read this when `$LAB forks` reaches a fork point, or when an experiment exposes a sub-question for a child campaign.

## Fork-and-flush (downward recursion, breadth)

One run of an agent settles into one line of ideas, and more compute on that run does not leave it; forking the workspace with an empty conversation does.

- **When:** at the experiment numbers `$LAB forks <dir>` prints (one third and two thirds of a leg of 12 or more experiments), unless the contract says `forks: off`.
- **Carve:** for each fork, `$LAB fork <dir> <dir>/f<p>-<i> --experiments <e>` (fork point p, fork i). Each fork gets its own sealed state with its share of the budget, so parallel forks never write the same file and none can spend another's experiments. A fork does not fork again.
- **Run:** from the branch tip, create K worktrees `.worktrees/lab-<slug>-f<p>-<i>` on branches `lab/<slug>-f<p>-<i>`. Launch K fresh subagents with no conversation history. Each brief holds only: the contract, the journal, its fork directory, and the loop rules in `references/loop.md`; it books with `$LAB spend <its fork dir>`. On `device: shared`, forks run one after another, never in parallel, because parallel runs corrupt each other's measurements.
- **Select:** before re-measuring, predict each fork tip in the parent (`$LAB predict <dir> f<p>-<i> --proposer <the fork's proposer> --predicted <the fork's own best reading>`). Re-measure each fork tip against the current tip with the harness (interleaved on a shared device), run the gates on the leading fork, then `$LAB check <dir> --base <current tip>` in the leading fork's worktree. The best fork that `$LAB keep --id f<p>-<i>` accepts becomes the new tip; if none does, the tip stays. Remove the fork worktrees and branches; their journal rows stay.
- **Flush the coordinator too:** after selection, fold the loop's own context to contract + journal + tip before the next experiment.

## Child campaigns (downward recursion, depth)

Use a child when an experiment exposes a sub-question with its own scalar metric that a short campaign can settle, such as "the best tile size for this kernel shape" inside "make this kernel faster".

1. **Write** `<dir>/child-<n>/contract.md`: question, metric (read by a locked harness), threshold, fence, budget, and its own noise floor.
2. **Open:** `$LAB child <dir> <dir>/child-<n> --experiments <m> [--fence '<narrower glob>']`. It refuses beyond max depth (default 2), more than half of the parent's remaining experiments, or a fence outside the parent's; the child inherits every parent lock, and its `check` applies the fence of every ancestor.
3. **Run:** one fresh subagent with the child contract, on branch `lab/<slug>/c<n>` from the parent tip, in its own worktree, under these same loop rules. It may open its own child if depth allows. One leg only: `$LAB leg` refuses a child. On `device: shared` the parent waits while the child measures.
4. **Return:** the child records its end with `$LAB end`, writes its leg report in its own directory, and the parent journals one row: `c<n> · question · end state · best metric · SHA`. Merging the child's tip into the parent is then an ordinary parent experiment: predict it (the child's best reading is the prediction), measure with the parent harness, gates, `$LAB check`, keep or revert.
