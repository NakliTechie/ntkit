---
description: Execute a batched fix-workplan from a /forward-pass-nt, /ux-review-nt, or /maintain-nt report (or plan/workplan.md) — work the top batch item by item, fix and verify each, check it off, log progress with the commit SHA, and pause between batches. The executor for static findings.
argument-hint: "[report or batch, e.g. forward-pass | A]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
---

Work through a batched fix-workplan and actually do the fixes. The audit commands — `/forward-pass-nt`, `/ux-review-nt`, `/maintain-nt` — *find* and *plan*: they hand you a `## Batch A/B` workplan of items with stable IDs (`C1`, `H2`, …) and leave execution to you. `/execute-nt` is that missing verb. It picks up the top batch, works each item (fix → verify → check off → progress-log), and **pauses between batches** so you stay in control. (`/walkthrough-nt` fixes inline as it drives the browser; this is its counterpart for a *static* report.)

It edits code and verifies — but it is **not a runaway**: it verifies every fix and stops at each batch boundary.

If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): which report (`forward-pass`, `ux-review`, `maintenance`) or which batch (`A`, `B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

## Phase 1 — Pick the plan and the batch

Find the workplan: the most recent `plan/forward-pass-*.md` / `plan/ux-review-*.md` / `plan/maintenance-*.md` report (each carries its own Workplan section), or `plan/workplan.md`. Pick the batch per `$ARGUMENTS`, else the **keystone** (or top) batch. **Show the chosen batch and its open items before starting**, and respect sequencing — a keystone or depended-on batch goes first.

## Phase 2 — Work each item, in order

For each `[ ]` item in the batch:
1. **Read the finding** — its ID, precise location, and the one-line "what + why".
2. **Make the fix** — match the surrounding code; the smallest change that resolves it. If the item is really a *decision* (a UX/structural call), don't force it — `/decide-nt` and skip.
3. **Verify it** — the right way for *this* item: a unit test, typecheck, or build for logic; a **runtime / browser** check for any `[test]`-marked item (use `/walkthrough-nt` discipline — and **WebGPU flows via the Chrome MCP**, never headless).
4. **Check it off** — flip `[ ]` → `[x]` in the report, and append a **progress-log entry**: what changed · how it was verified · the commit SHA once committed.

A `[~]` partial states what's done, what's left, and what would un-defer it. A blocker that needs a decision → `/decide-nt`.

## Phase 3 — Don't auto-ship

Leave the fixes in the working tree — **don't commit or push** (that's `/windup-nt`) unless asked. When the batch is done, summarize what landed and what verification is still owed, then **pause and ask before starting the next batch.** Running a whole report's batches unattended is how a fix masks or causes the next bug — stop at the boundaries.

## Phase 4 — Handoff

Report: the batch completed, items fixed vs. deferred, any `[test]` verification still owed, and the next batch. `/windup-nt` ships the working-tree fixes; `/replan-nt` folds the remaining items.
