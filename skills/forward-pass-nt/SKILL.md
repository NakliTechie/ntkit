---
description: "Cold whole-codebase audit for bugs, security, stray code, stubs; writes a ranked fix-workplan. Read-only."
argument-hint: "[path or focus, e.g. src/api | security]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task", "Write"]
entry: "briefed or later; a codebase to read"
exit: "batched workplan with stable finding IDs written"
writes: "plan/forward-pass-<date>.md"
---

Do a **fresh-eyes forward pass** over the project's code — a cold read of the whole app as if you've never seen it — hunting four things: **bugs**, **security issues**, **stray code**, and **stubs masquerading as done**. This is an AUDIT of the entire codebase, not a review of recent changes (`/code-review`, `/review`, and `/security-review` are diff-scoped).

**READ-ONLY.** Report, rank, and plan — never edit code, never auto-fix.

**Rotate the eyes.** This is a checker command; two runs of the same model misjudge the same things identically. Before starting, read only the `Reviewer:` header line of this command's most recent report in `plan/` — never its findings, which would anchor the cold read. Repeat run → prefer a different **model family** (an agent CLI on the PATH such as `codex` or `gemini`, checked with `which`, driven through this same brief via Bash); none reachable → a different model of the current family (subagent with a model override); neither → run as-is and say so in the report. Never rotate to materially weaker eyes; log the rotation as unavailable instead. The report header carries `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and names it if you are the family that built most of this code.

`$ARGUMENTS` (optional): a path to scope the pass (e.g. `src/api`), a focus hint (e.g. `security`), and/or `fix` — after the report lands, hand the keystone batch to `/autopilot-nt`. The maker–checker split holds either way: the audit completes and the report is written first; fixing is a second pass with its own verification. If empty, audit the whole app with all four lenses.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Map | Languages, entry points, layers, and the primary execution flows — the traversal order and the report's coverage map. Cross-checked against `verify/features/` when a walkthrough left one. | `references/lenses.md` |
| 2 Traverse | Entry points outward, following the real flow; parallel subagents by module for a large app. Four lenses per unit: bugs · security · stray code · stubs. The stub lens cross-references what `plan/`, README and CHANGELOG claim finished against what the code does, and flags the gap loudly. | `references/lenses.md` |
| 3 Rank | Deduped findings with stable IDs: `C/H/M/L` by severity, `S` stray, `SB` stub (a live-path stub also carries a severity ID), `W` worth a look. Dismissals preserved with the reasoning that cleared them. | `references/ranking-and-workplan.md` |
| 4 Workplan | Themed batches ordered for execution, keystone first; tri-state checkboxes; finding ID, location, and rationale per item; `[test: how]` markers; deferrals name what unblocks. | `references/ranking-and-workplan.md` |
| 5 Report | `plan/forward-pass-<date>.md` in fixed order, with stubs in their own section and the `Reviewer:` line. Print counts, findings by severity, the stubs list, the coverage map. Never overwrite `workplan.md`. | `references/report.md` |
| 6 Handoff | The keystone batch to start, decisions to record via `/decide-nt`, what `/replan-nt` folds later. Without `fix`: stop here. With `fix`: hand the keystone batch to `/autopilot-nt`. | `references/report.md` |

## Impact declaration

`plan/forward-pass-<date>.md` is a **record**: append-only, never rewritten ([`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md)). End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- workplan.md/B2#3 — status: [ ] → [x], verified by <the check that proves it>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. Do not write the item into `pending.md` or `workplan.md` yourself — a record that declares its impact and a reconcile pass that folds it are what keep the plan rebuildable from the log. An `add` line with nothing later citing this record is a **ghost**, and `plancheck` reports it.
