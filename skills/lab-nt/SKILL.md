---
description: "Turn an idea into a measured contract, then run bounded experiment legs; can self-improve skills."
argument-hint: "[idea, e.g. \"can QAT recover fp16 quality at int4 in-browser\" | resume [<slug>] | status | meta <skill>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent", "WebSearch", "WebFetch"]
entry: "an idea in $ARGUMENTS or the conversation, an open campaign in plan/lab/ to resume, or `meta <skill>` in the repo holding skills/<skill>/; never re-armed at an unchanged wall"
exit: "leg ended GOAL-MET (verified) | BUDGET | STAGNANT | DRY-WELL | PARKED, journal + leg report written, `lab.py check` exit 0 on the best-so-far; never a silent end"
writes: "its own worktrees, plan/lab/<slug>/ (contract.md, lab.json, journal.md, <date>-leg.md, child-<n>/); in meta mode with `merge: auto` granted, a local merge commit on the default branch"
---

`/lab-nt` answers what isn't known yet. It shapes an idea with the user into a contract with a falsifiable finish line, then runs the `autoresearch` loop: smallest experiment → measure → keep or revert → journal → next. It searches an unknown space under a budget, and the honest exit is often "best so far". Every leg is bounded, the best-so-far is always committed, and continuing is earned, never assumed.

It is recursive in two directions. **Downward:** a leg forks fresh-context branches at set points (fork-and-flush) and may open a child campaign for a sub-question with its own metric, to depth 2. **Upward:** `meta <skill>` runs a campaign whose subject is a skill's own playbook, including `/lab-nt`'s, graded on a held-out suite it can neither read nor edit.

**Experiment mode only.** The goal must reduce to a scalar a harness can read. If no real proxy metric exists, decline the launch and say so.

## Inputs and defaults

`$ARGUMENTS`: an **idea** (Phase 0) · **resume** (newest open campaign, or `resume <slug>`) · **status** (read-only: campaigns, children, leg count, best-so-far, end state) · **meta \<skill>** (Phase 0 in meta mode, `references/meta.md`). Meta mode refuses, writing nothing, when `skills/<skill>/references/` does not exist: that folder is its whole fence, and splitting a skill into a router is a human's edit.

Contract fields, each with its default, stated rather than asked:

| Field | Default | Effect |
|---|---|---|
| per-leg budget | 25 experiments or 4 hours | BUDGET when spent; `lab.py spend` counts |
| odometer | 5 legs | RETIRED when spent; extend only via `/decide-nt` |
| critic | every 5 experiments | fresh subagent, contract + journal only |
| stagnation | 8 experiments without a kept gain | STAGNANT |
| forks | 3 per fork point, at 1/3 and 2/3 of a leg of 12+ experiments | `lab.py forks`; `off` disables |
| device | `own` | `shared` (one GPU, one benchmark box) serialises forks and children |
| max depth | 2 | `lab.py child` refuses deeper |
| gates | none | commands that must pass on the same commit before its metric counts |
| merge | `none` | `auto` is a per-run grant, meta mode only |
| usd cap | none, so no paid model calls | paid models only inside a cap the user names |

`python3 $SKILL/bin/lab.py` (anchored; `$SKILL` is this skill's base directory) enforces the rules a script can check: the sealed state file, lockbox hashes and new files in locked paths, the fence of the campaign and every ancestor, experiment budgets for legs, children and forks, child depth, the keep decision, the leg odometer, the STAGNANT and DRY-WELL resume refusal, and the merge grant. Its docstring is the contract; its verdict beats the loop's opinion. The critic, the stagnation count, the clock and the usd cap stay with the loop and its leg report.

## Phases

On entering a phase, read its file, then act. The Outcome column is the contract.

| Phase | Outcome | Detail |
|---|---|---|
| 0 Contract | five gates passed; `contract.md` written | `references/contract.md` |
| 0.5 Isolate | worktree on `lab/<slug>`; noise floor measured; `lab.py init` exit 0; journal opened | `references/contract.md` |
| 1 Leg loop | experiments journaled, kept ones committed under the joint gate; forks and children run by the rules | `references/loop.md` |
| 2 End | first exit wins: GOAL-MET, BUDGET, STAGNANT, DRY-WELL, PARKED | `references/ending.md` |
| 3 Re-arm | the leg report recommends CONTINUE or STOP; only a human resumes, through `lab.py leg` | `references/ending.md` |
| 4 Report | teardown, audit, leg report, impact section, notify | `references/ending.md` |
| meta | a skill's playbook is the fence; public suite steers, private suite decides | `references/meta.md` |

## Stop-lines

`/autopilot-nt`'s stop-lines (no publishing, sending, deleting, credentials, money, destructive infra), plus:

- Never modify the harness, the gates, the contract, `lab.json`, or past journal rows. `lab.py check` must exit 0 before any keep, fork selection, child return or merge; a violation reverts the experiment.
- Never spend outside the ladder: no new paid API, no bigger instance, no self-granted extra hour, nothing past the usd cap.
- Never arm or schedule the next leg. Only a human starts another. A child runs one leg and returns.
- A child never exceeds max depth, takes at most half its parent's remaining experiments, keeps its fence inside its parent's, and inherits every lock.
- Meta mode edits only `skills/<skill>/references/`. It never edits a root `SKILL.md`, `bin/`, `tests/`, `evals/`, the suite, its split or its runner, and never reads private task content or per-task private results.
- Merging is denied unless `lab.py merge-ok` confirms the user's `merge: auto` grant for this campaign. Even then: a local merge from the lab's own worktree, never the main checkout, after a private-suite win, `lab.py check` exit 0 and the repo's free tests, with the revert command logged. Never push.
