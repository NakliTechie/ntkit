---
description: Execute a batched fix-workplan from a /forward-pass-nt, /ux-review-nt, or /maintain-nt report (or plan/workplan.md) — work the batches item by item: fix, verify, commit locally, check off, log evidence; roll batch to batch, pausing only on red flags. The executor for static findings.
argument-hint: "[report or batch, e.g. forward-pass | A]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "an open fix-workplan exists — refuse otherwise (see Phase 0)"
exit: "batch items [x] with commit SHAs, or blocked with a tried-trail"
writes: "code, the source report's checkboxes + progress log"
---

Work through a batched fix-workplan and actually do the fixes. The audit commands — `/forward-pass-nt`, `/ux-review-nt`, `/maintain-nt` — *find* and *plan*: they hand you a `## Batch A/B` workplan of items with stable IDs (`C1`, `H2`, …) and leave execution to you. `/execute-nt` is that missing verb. It picks up the top batch, works each item (fix → verify → commit → check off → progress-log), and **rolls batch to batch by default**, pausing only on a red flag — the user steers by interrupting, not by being polled. (`/walkthrough-nt` fixes inline as it drives the browser; this is its counterpart for a *static* report.)

It edits code and verifies — but it is **not a runaway**: every fix is verified before it lands and committed locally so nothing is ever lost; nothing is ever pushed (the push stays `/windup-nt`'s).

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): which report (`forward-pass`, `ux-review`, `maintenance`) or which batch (`A`, `B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

## Phase 0 — Entry guard

`/execute-nt` executes an existing plan; it never invents one. If no report with open `[ ]` items and no `plan/workplan.md` with an open chunk exists, **refuse and stop**: "Nothing to execute — no open fix-workplan. Run `/forward-pass-nt`, `/ux-review-nt`, or `/maintain-nt` first, or point me at a batch." Don't improvise a plan from the codebase; that's an audit command's job, and the maker–checker split only holds if finding and fixing stay separate runs.

## Phase 1 — Pick the plan and the batch

Find the workplan: the most recent `plan/forward-pass-*.md` / `plan/ux-review-*.md` / `plan/maintenance-*.md` report (each carries its own Workplan section), or `plan/workplan.md`. Pick the batch per `$ARGUMENTS`, else the **keystone** (or top) batch. **Show the chosen batch and its open items before starting**, and respect sequencing — a keystone or depended-on batch goes first.

## Phase 2 — Work each item, in order

For each `[ ]` item in the batch:
1. **Read the finding** — its ID, precise location, and the one-line "what + why".
2. **Make the fix** — match the surrounding code; the smallest change that resolves it. If the item is really a *decision* (a UX/structural call), don't force it — `/decide-nt` and skip.
3. **Verify it** — the right way for *this* item: a unit test, typecheck, or build for logic; a **runtime / browser** check for any `[test]`-marked item (use `/walkthrough-nt` discipline — and **WebGPU flows via the Chrome MCP**, never headless). For anything non-trivial, verify with **fresh eyes** — a Task subagent that sees only the item, the diff, and how to check, so the context that wrote the fix isn't grading it. And never satisfy a check by weakening it: a fix that modifies, skips, or deletes its own test isn't a fix — flag any test-file change in the batch summary.
4. **Commit it** — one focused commit per item (or tight cluster), by path, never `git add -A`. Local only — the push stays `/windup-nt`'s. Continuous commits are what make the run safe to interrupt: a crash or reload loses at most the item in flight, never the batch.
5. **Check it off** — flip `[ ]` → `[x]` in the report, and append a **progress-log entry** with three mandatory cells: **what changed · evidence · result**. Evidence is a *resolvable pointer*, never prose — the commit SHA, a `file:line`, a check's output; result is the outcome state (`tests green` / `build clean` / `reverted` / `deferred: <why>`). A row whose evidence doesn't resolve is the audit catching a gap — that's the discipline, not bureaucracy.

A `[~]` partial states what's done, what's left, and what would un-defer it. A blocker that needs a decision → `/decide-nt`.

## Phase 3 — Roll forward; pause only on red flags

When a batch is done, print a one-line batch summary (items landed · deferred · verification owed) and **continue into the next batch** — that's the default. Hand back to the user only when something genuinely needs them:

- **`$ARGUMENTS` scoped the run to one batch** — honor the scope, stop there.
- **A test file changed** anywhere in the batch — green isn't trustworthy until a human looks.
- **Verification is owed this session can't perform** — a `[test]` item with no runnable path here.
- **A systemic pattern** — two items failing for the same root cause means the substrate is sick; stop poking items and say so.

Never push — commits stay local; `/windup-nt` ships.

## Phase 4 — Handoff

Report: batches completed, items fixed vs. deferred (with commit SHAs), any `[test]` verification still owed, and — if the run paused on a red flag — which flag and what clears it. `/windup-nt` pushes the local commits; `/replan-nt` folds the remaining items.
