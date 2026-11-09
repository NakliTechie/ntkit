---
name: forward-pass-nt
description: "Cold whole-codebase audit for bugs, security, stray code, stubs, test value, agent-readiness; ranked fix-workplan. Read-only."
allowed-tools: Bash Glob Grep Read Agent Write
metadata:
  argument-hint: "[path or focus, e.g. src/api | security] [fix]"
  entry: "briefed or later; a codebase to read"
  exit: "batched workplan with stable finding IDs written; `bin/cite-check.py` exits 0 on the report"
  writes: "plan/forward-pass-<date>.md"
---

Do a **fresh-eyes forward pass**: a cold read of the whole app, hunting six things: **bugs**, **security issues**, **stray code**, **stubs masquerading as done**, **low-value tests**, and **agent-readiness gaps**. `/code-review` and `/security-review` review a diff or a named target; this command audits the whole app cold. For the diff-time review method and the 22-scanner list, see `references/diff-review.md`.

`$SKILL` is the directory containing this skill's loaded `SKILL.md`; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

**Read-only.** Report, rank, and plan; never edit code, never auto-fix.

**Rotate the eyes:** before starting, follow `$SKILL/../forward-pass-nt/references/other-families.md` § Rotation (forward-pass-nt uses `references/other-families.md`); with no other family reachable, run as-is and write `rotation: unavailable` in the `Reviewer:` line. Prior findings come back in Phase 3, after your own are ranked.

Optional input: a path to scope the pass (e.g. `src/api`), a focus hint (e.g. `security`), and/or `fix`. Empty: the whole app, all six lenses. With `fix`, the report is written first and the keystone batch then goes to `/autopilot-nt`, a separate pass with its own verification.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Map | Languages, entry points, layers and primary flows (the traversal order and coverage map), plus trust boundaries, a history seed of past fixes, and churn; cross-checked against `verify/features/` when one exists. | `references/lenses.md` |
| 2 Traverse | Every unit read from entry points outward under six lenses: bugs · security · stray code · stubs · test value · agent-readiness (parallel subagents by module for a large app). The masquerade check (claimed done vs. what the code does) and the UI-vs-manifest parity check are flagged loudly; every implicit state machine reached goes into an inventory. | `references/lenses.md`, `references/test-value.md` |
| 3 Rank | Deduped findings with stable IDs (`C/H/M/L`, `S`, `SB`, `T`, `AR`, `W`). Every Critical, High and Security candidate is challenged first by a fresh agent that sees only the claim and its `path:line`. Then, and only then, reconciled against prior runs; dismissals kept with their reasoning. | `references/ranking-and-workplan.md` |
| 4 Workplan | Themed batches ordered for execution, keystone first; tri-state checkboxes; finding ID, location, and rationale per item; `[test: how]` markers; deferrals name what unblocks. | `references/ranking-and-workplan.md` |
| 5 Report | `plan/forward-pass-<date>.md` in fixed order, with the `Reviewer:` and `Commit:` lines. Every `path:line` resolves under `bin/cite-check.py` before you print. Print counts, findings by severity, the stubs and agent-readiness lists, the coverage map, and the keystone batch's name. Never overwrite `workplan.md`. | `references/report.md` |
| 6 Handoff | The keystone batch to start, decisions to record via `/decide-nt`, what `/replan-nt` folds later. Without `fix`: stop here. With `fix`: hand the keystone batch to `/autopilot-nt`. | `references/report.md` |

## Impact declaration

`plan/forward-pass-<date>.md` is a record: append-only. End it with `## Impact`: one line per change it implies for `pending.md`, `workplan.md` or `history.md` (`- pending.md/Now — add: …`), or `- none — <reason>`. Never add, drop or reword items there yourself; a status flip on an existing item is allowed. `/replan-nt` applies the rest (MEMORY.md §3).
