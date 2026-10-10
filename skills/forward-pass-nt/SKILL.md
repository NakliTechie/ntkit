---
description: "Cold whole-codebase audit for bugs, security, stray code, stubs, test value, agent-readiness; ranked fix-workplan. Read-only."
argument-hint: "[path or focus, e.g. src/api | security] [fix]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Agent", "Write"]
entry: "briefed or later; a codebase to read"
exit: "batched workplan with stable finding IDs written; `bin/cite-check.py` exits 0 on the report"
writes: "plan/forward-pass-<date>.md"
---

Do a **fresh-eyes forward pass**: a cold read of the whole app, hunting six things: **bugs**, **security issues**, **stray code**, **stubs masquerading as done**, **low-value tests**, and **agent-readiness gaps**. `/code-review` and `/security-review` review a diff or a named target; this command audits the whole app cold. For the diff-time review method and the 22-scanner list, see `references/diff-review.md`.

`$SKILL` is this skill's base directory, printed when the skill loads; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

**Read-only.** Report, rank, and plan; never edit code, never auto-fix.

**Rotate the eyes.** Before starting, read only the `Reviewer:` line of this command's latest report in the main checkout's `plan/`, never its findings. If that run used your model family, prefer another family's agent CLI on PATH (`codex`, `gemini`, checked with `which`), else another model of your family; never materially weaker eyes. Neither reachable → run as-is and write `rotation: unavailable` in the `Reviewer:` line. The report header says `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and notes when you are the family that built most of the code. Prior findings come back in Phase 3, after your own are ranked.

`$ARGUMENTS` (optional): a path to scope the pass (e.g. `src/api`), a focus hint (e.g. `security`), and/or `fix`. Empty: the whole app, all six lenses. With `fix`, the report is written first and the keystone batch then goes to `/autopilot-nt`, a separate pass with its own verification.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Map | Languages, entry points, layers, and the primary execution flows — the traversal order and the report's coverage map. Trust boundaries: who can reach each entry point and what they control. A history seed: past fixes to re-check and hunt variants of. Churn: the most-edited files, where structure findings start. Cross-checked against `verify/features/` when a walkthrough left one. | `references/lenses.md` |
| 2 Traverse | Entry points outward, following the real flow; parallel subagents by module for a large app. Six lenses per unit: bugs · security · stray code · stubs · test value · agent-readiness. The stub lens cross-references what `plan/`, README and CHANGELOG claim finished against what the code does; the agent-readiness lens cross-references what a human can do in the UI against what a machine caller can do through a declared manifest. Both flag the gap loudly. The stray lens also tests live structure: no caller, deletion, two adapters. | `references/lenses.md`, `references/test-value.md` |
| 3 Rank | Deduped findings with stable IDs: `C/H/M/L` by severity, `S` stray, `SB` stub, `T` test value, `AR` agent-readiness gap (a live/reachable stub or gap, or a vacuous test hiding a live defect, also carries a severity ID), `W` worth a look. Every Critical, High, and Security candidate is challenged first by a fresh agent that sees only the claim and its `path:line`. Severity capped by what the attacker gains. Then, and only then, reconciled against prior runs: new · still open · regression · re-flagged. A fix that would undo a recorded decision quotes it and defers to `/decide-nt`. Dismissals preserved with the reasoning that cleared them. | `references/ranking-and-workplan.md` |
| 4 Workplan | Themed batches ordered for execution, keystone first; tri-state checkboxes; finding ID, location, and rationale per item; `[test: how]` markers; deferrals name what unblocks. | `references/ranking-and-workplan.md` |
| 5 Report | `plan/forward-pass-<date>.md` in fixed order, with stubs and agent-readiness gaps each in their own section, plus the `Reviewer:` and `Commit:` lines. Every `path:line` resolves under `bin/cite-check.py` before you print. Print counts, findings by severity, the stubs and agent-readiness lists, the coverage map, and the keystone batch's name; the full workplan stays in the file. Never overwrite `workplan.md`. | `references/report.md` |
| 6 Handoff | The keystone batch to start, decisions to record via `/decide-nt`, what `/replan-nt` folds later. Without `fix`: stop here. With `fix`: hand the keystone batch to `/autopilot-nt`. | `references/report.md` |

## Impact declaration

`plan/forward-pass-<date>.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
