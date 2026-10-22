# Meta mode: a campaign whose subject is a skill's playbook

`/lab-nt meta <skill>` runs in the repository that holds `skills/<skill>/` (ntkit, scholia). The inner system is the skill's playbook. The loop proposes one edit per experiment and keeps it only when a held-out score rises beyond noise. This is the AIDE² pattern (arXiv:2609.26457): an outer agent rewrote a research agent's harness and kept a rewrite only when a private held-out grade improved; 7 rewrites were accepted in 8 days and the gains carried to 4 benchmarks the loop never saw.

## Contract (Phase 0, meta form)

The five gates still apply, in this shape:

1. **Question:** "does editing `<skill>`'s references raise its private-suite score?"
2. **Metric:** the runner's aggregate score on the private split. Direction and threshold as usual.
3. **Fence:** `skills/<skill>/references/**` only. The root `SKILL.md` (contract and stop-lines), `bin/` (deterministic gates), `tests/` and `evals/` are locked, so the loop can change how the skill works but never what it is allowed to do or how it is checked. A skill with no `references/` must first be split into a router by a human (AUTHORING §9).
4. **Budget:** experiments, hours, and a usd cap. Paid models are allowed only inside the cap; the runner reports spend per call and the loop stops at the cap (BUDGET).
5. **Noise floor:** run the unchanged skill on the private split three times; the loop sees only the three aggregate numbers.

Also record whether the user grants `merge: auto` for this campaign.

## The suite, the split and the runner (all locked)

- **Suite:** `plan/lab/meta-<skill>/suite/`, one directory per task with whatever the runner needs (a prompt, a fixture, a reference answer or a target). Examples: research questions with rubrics for `/research-nt`; past panels with blind-judged rankings for `/panel-nt`; replay tasks for `/lab-nt` itself (a starting commit, a locked harness, and a target the project's history shows is reachable).
- **Split:** written once before the first experiment, by `sha256(task_id + salt)` parity, into `split.json` with the salt. Never re-split during a campaign. Grow the suite before the first run until one lucky task cannot clear the noise floor alone; five tasks is too few.
- **Runner:** a command `<runner> <checkout> public|private` that installs the candidate skill from `<checkout>` into a scratch project under its own Claude config directory (the `evals/run.sh` pattern, so the installed copy in `~/.claude/skills` does not shadow it), runs each task, and prints one JSON line `{"score": <x>, "n": <tasks>, "usd": <spent>}`. On the public split it may also write per-task results the loop can read; on the private split it prints the aggregate only.

`lab.py init` locks the suite, the split, the runner, the skill's root `SKILL.md`, `bin/**`, `tests/**` and `evals/**`, with the fence set to `skills/<skill>/references/**`.

## The loop (Phase 1, meta form)

1. Edit the references (one idea per experiment). `lab.py spend`, then `lab.py check`.
2. Run the public split. Read per-task public results to steer the next idea.
3. Only when the public score beats the public noise does the candidate earn one private run. Read the aggregate number only.
4. `lab.py keep --noise <private floor> --gate pass --base <private baseline readings> --cand <private reading(s)>`. KEEP commits on `lab/meta-<skill>`.
5. Forks and children work as in `references/loop.md`; a child here is a narrower question about one reference file.

## When `lab-nt` is the subject

The outer loop runs the copy of `/lab-nt` installed when the leg started, and never reloads itself mid-leg. The candidate copy runs only inside the runner's scratch install. The outer contract and its stop-lines therefore cannot be changed by the experiment being judged.

## Merge (only with `merge: auto` granted)

After a KEEP and `lab.py check` exit 0: `git merge --no-ff lab/meta-<skill>` into the default branch in the main checkout, as a local commit `lab meta <skill>: <what> — private <old → new>`. Journal the merge SHA and its revert command (`git revert -m 1 <sha>`). Never push; the user, `/windup-nt` or `/release-nt` publishes. Without the grant, the kept edits stay on the branch and the leg report lists them under Needs you.
