# Meta mode: a campaign whose subject is a skill's playbook

`/lab-nt meta <skill>` runs in the repository that holds `skills/<skill>/` (ntkit, scholia). The inner system is the skill's playbook. The loop proposes one edit per experiment and keeps it only when a held-out score rises beyond noise. This is the AIDE² pattern (arXiv:2609.26457): an outer agent rewrote a research agent's harness and kept a rewrite only when a private held-out grade improved; 7 rewrites were accepted in 8 days and the gains carried to 4 benchmarks the loop never saw.

## Contract (Phase 0, meta form)

The five gates still apply, in this shape:

1. **Question:** "does editing `<skill>`'s references raise its private-suite score?"
2. **Metric:** the runner's aggregate score on the private split. Direction and threshold as usual.
3. **Fence:** `skills/<skill>/references/**` only. The root `SKILL.md` (contract and stop-lines), `bin/` (deterministic gates), `tests/` and `evals/` are locked, so the loop can change how the skill works but never what it is allowed to do or how it is checked. A skill with no `references/` must first be split into a router by a human (AUTHORING §9).
4. **Budget:** experiments, hours, and a usd cap. Paid models are allowed only inside the cap; the runner reports spend per call and the loop stops at the cap (BUDGET).
5. **Noise floor:** run the unchanged skill three times on each split. The public floor decides when a candidate earns a private run; the private floor decides KEEP. The loop sees only the three aggregate private numbers.

Also record whether the user grants `merge: auto` for this campaign.

## The suite, the split and the runner (all locked)

- **Suite:** `plan/lab/meta-<skill>/suite/`, one directory per task with whatever the runner needs (a prompt, a fixture, a reference answer or a target). Examples: research questions with rubrics for `/research-nt`; past panels with blind-judged rankings for `/panel-nt`; replay tasks for `/lab-nt` itself (a starting commit, a locked harness, and a target the project's history shows is reachable).
- **Split:** written once before the first experiment, by `sha256(task_id + salt)` parity, into `split.json` with the salt. Never re-split during a campaign. Grow the suite before the first run until one lucky task cannot clear the noise floor alone; five tasks is too few.
- **Runner:** a command `<runner> <checkout> public|private` that installs the candidate skill from `<checkout>` into a scratch project under its own Claude config directory (the `evals/run.sh` pattern, so the installed copy in `~/.claude/skills` does not shadow it), runs each task, and prints one JSON line `{"score": <x>, "n": <tasks>, "usd": <spent>}`. On the public split it may also write per-task results the loop can read; on the private split it prints the aggregate only.

`python3 $SKILL/bin/lab.py init plan/lab/meta-<skill> --fence 'skills/<skill>/references/**' --lock 'plan/lab/meta-<skill>/suite/**' 'plan/lab/meta-<skill>/split.json' '<runner path>' 'skills/<skill>/SKILL.md' 'skills/<skill>/bin/**' 'tests/**' 'evals/**' --experiments <n> [--merge auto]` locks all of it; a task file added to the suite later shows up in `check` as a new file in a locked path.

## The loop (Phase 1, meta form)

`$LAB` is `python3 $SKILL/bin/lab.py`, as in `references/loop.md`.

1. Edit the references (one idea per experiment). Predict its private score first, as in `references/loop.md` (`$LAB predict plan/lab/meta-<skill> <id> --proposer <who> --predicted <score>`). `$LAB spend plan/lab/meta-<skill>`, then `$LAB check plan/lab/meta-<skill> --base <best-so-far SHA>`.
2. Run the public split. Read per-task public results to steer the next idea.
3. Only when the public score beats the public noise floor does the candidate earn one private run. Read the aggregate number only.
4. `$LAB keep plan/lab/meta-<skill> --id <id> --gate pass --noise <private floor> --base <private baseline readings> --cand <private reading(s)>`. Exit 0 KEEP commits on `lab/meta-<skill>`; exit 4 reverts.
5. Forks and children work as in `references/loop.md`; a child here is a narrower question about one reference file.

## When `lab-nt` is the subject

The outer loop runs the copy of `/lab-nt` installed when the leg started, and never reloads itself mid-leg. The candidate copy runs only inside the runner's scratch install. The outer contract and its stop-lines therefore cannot be changed by the experiment being judged.

## Merge (only with `merge: auto` granted)

After a KEEP, `$LAB check plan/lab/meta-<skill>` exit 0 and `$LAB merge-ok plan/lab/meta-<skill>` exit 0, merge from your own worktree, never in the main checkout, where another session may be working:

1. `git worktree add --detach .worktrees/lab-merge <default branch>`; in it, `git merge --no-ff lab/meta-<skill> -m "lab meta <skill>: <what> — private <old → new>"`.
2. Run the repo's free tests there (`tests/run.sh` in ntkit). A failure stops the merge; the edit stays on its branch.
3. `git update-ref refs/heads/<default branch> <new SHA> <old SHA>`, so the update fails if the branch moved meanwhile. Then remove the merge worktree.
4. Journal the merge SHA and its revert command (`git revert -m 1 <sha>`).

Check each command's exit code on its own. Never push; the user, `/windup-nt` or `/release-nt` publishes. Without the grant, `merge-ok` exits 1, the kept edits stay on the branch, and the leg report lists them under Needs you.
