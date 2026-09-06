## Phase 5 — Write the report + print

**Write `plan/forward-pass-YYYY-MM-DD.md`** — a self-contained audit-and-fix artifact, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.

1. **Header** — date, scope, the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule above), one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray · 4 Stub").
2. **Verification reality** — a short note on how this app can/can't be tested (browser runtime needed? no headless path? pure-logic harness available?), so the `[test]` markers have context.
3. **Findings** — by ID, grouped Critical → High → Medium → Low → Stray → Stub. Give **Stubs their own dedicated section** (`### Stubs masquerading as done`), even when a stub is also listed under its severity — this is the section Chirag wants to scan first, so make it impossible to miss, and for each entry show the claimed-done source next to the actual stubbed code.
4. **False positives / non-issues (verified)** — preserved with reasoning.
5. **Worth a look (lower confidence)**.
6. **Coverage map** — what was reviewed and, crucially, what was NOT reached or skipped (the blind spots).
7. **Workplan** — the batched, ordered, checkbox plan from Phase 4. This section doubles as the fix workplan; work straight from it.
8. **Progress log** — seed with one dated entry: `- YYYY-MM-DD: forward pass complete, workplan created. Starting Batch A.`

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. Don't commit/push — plan/ is local. **Do not overwrite the canonical `workplan.md`** — this report carries its own Workplan section. (Promotion into `workplan.md` happens via `/replan-nt`, or offer to move it if the user has no competing workplan.)

**Print to chat:** the summary counts + findings grouped by severity + **the Stubs-masquerading-as-done list called out explicitly** (claimed-done vs. actual) + the coverage map. Keep the full batched workplan in the file (just say it's there and name the keystone batch).

## Phase 6 — Handoff

End with a tight next-steps note (don't act on it):
- The keystone batch to start with
- Any architectural finding a fix is *blocked on* — record it with `/decide-nt` (e.g. a hash-migration decision)
- As you work the batches: check items off in the report, and append progress-log entries with **verification evidence** (`tests pass; still needs runtime test: C1`) and the **commit SHA** pushed
- `/replan-nt` will fold open batch items into `pending.md`/`workplan.md`, record dismissed false-positives into history's Dead ends, and archive this report

Without `fix` in `$ARGUMENTS`: do NOT start fixing — the forward pass finds, ranks, and plans; the user decides what to execute. With `fix`: the audit is complete and the report is on disk — now hand the keystone batch to `/autopilot-nt` (fix · verify · commit · log evidence, rolling forward, parking anything risky instead of stopping) and go.
