## Phase 5 — Write the report + print

**Write `plan/forward-pass-YYYY-MM-DD.md`** — a self-contained audit-and-fix artifact, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.

1. **Header** — date, scope, the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule above), the `Commit:` line (`git rev-parse --short HEAD`, plus `+dirty` when `git status --porcelain` prints anything), one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray · 4 Stub · 6 Test · 3 Agent-readiness"), and the reconcile counts (e.g. "11 new · 4 still open · 1 regression · 2 re-flagged").
2. **Verification reality** — a short note on how this app can/can't be tested (browser runtime needed? no headless path? pure-logic harness available?), so the `[test]` markers have context.
3. **Findings** — by ID, grouped Critical → High → Medium → Low → Stray → Stub → Test value → Agent-readiness. Give **Stubs** (`### Stubs masquerading as done`) and **Agent-readiness gaps** (`### Agent-readiness`) **each their own dedicated section**, even when an entry is also listed under its severity — these are the sections meant to be scanned first, so make them impossible to miss. For a Stub, show the claimed-done source next to the actual stubbed code; for an Agent-readiness gap, show the UI action next to its missing (or unstaged, or unmarked) manifest counterpart. Each entry ends with its reconcile mark (`new`, `still open: <report> <ID>`, `regression`, `re-flagged`), and each challenged entry carries `challenge: stood — <evidence>`. Put regressions first within their severity.
4. **False positives / non-issues (verified)** — preserved with reasoning.
5. **Worth a look (lower confidence)**.
6. **Coverage map** — what was reviewed and, crucially, what was NOT reached or skipped (the blind spots).
7. **Workplan** — the batched, ordered, checkbox plan from Phase 4. This section doubles as the fix workplan; work straight from it.
8. **Progress log** — seed with one dated entry: `- YYYY-MM-DD: forward pass complete, workplan created. Starting Batch A.`

**Check every pointer before you print.** Run `python3 "$SKILL/bin/cite-check.py" plan/forward-pass-<date>.md` from the project root, where `$SKILL` is this skill's base directory, printed when the skill loads. It is stdlib-only and fails when a cited `path:line` names a missing file or a line past the end, or when a finding entry cites no `path:line` at all. Write every path from the project root (`app/services/ledger.rb:90`, not `ledger.rb:90`); a bare filename does not resolve. A finding about a whole file cites its line 1. Fix or drop every failure and re-run until it exits 0. A pointer that does not resolve is a fabrication (ATTEST §2), not a typo to leave in. It checks that the place exists, not what the code there does; the challenge step owns that.

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. Don't commit/push — plan/ is local. **Do not overwrite the canonical `workplan.md`** — this report carries its own Workplan section. (Promotion into `workplan.md` happens via `/replan-nt`, or offer to move it if the user has no competing workplan.)

**Print to chat:** the summary counts + findings grouped by severity + **the Stubs-masquerading-as-done list and the Agent-readiness list, both called out explicitly** (claimed-done vs. actual; missing door / parity gap vs. the UI action it corresponds to) + the coverage map. Keep the full batched workplan in the file (just say it's there and name the keystone batch).

## Phase 6 — Handoff

End with a tight next-steps note (don't act on it):
- The keystone batch to start with
- Any architectural finding a fix is *blocked on* — record it with `/decide-nt` (e.g. a hash-migration decision)
- As you work the batches: check items off in the report, and append progress-log entries with **verification evidence** (`tests pass; still needs runtime test: C1`) and the **commit SHA** pushed
- `/replan-nt` will fold open batch items into `pending.md`/`workplan.md`, record dismissed false-positives into history's Dead ends, and archive this report

Without `fix` in `$ARGUMENTS`: do NOT start fixing — the forward pass finds, ranks, and plans; the user decides what to execute. With `fix`: the audit is complete and the report is on disk — now hand the keystone batch to `/autopilot-nt` (fix · verify · commit · log evidence, rolling forward, parking anything risky instead of stopping) and go.
