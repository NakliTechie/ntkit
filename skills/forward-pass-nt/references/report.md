## Phase 5 — Write the report + print

**Write `plan/forward-pass-YYYY-MM-DD.md`** in this order:

1. **Header** — date, scope, the `Reviewer:` line (per the rotation rule), the `Commit:` line (`git rev-parse --short HEAD`, plus `+dirty` when `git status --porcelain` prints anything), one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray · 4 Stub · 6 Test · 3 Agent-readiness"), and the reconcile counts (e.g. "11 new · 4 still open · 1 regression · 2 re-flagged").
2. **Verification reality** — how this app can and can't be tested (browser runtime needed? no headless path? pure-logic harness available?), so the `[test]` markers have context.
3. **Findings** — by ID, grouped Critical → High → Medium → Low → Stray → Stub → Test value → Agent-readiness. **Stubs** (`### Stubs masquerading as done`) and **Agent-readiness gaps** (`### Agent-readiness`) each get their own section, even when an entry is also listed under its severity. A Stub shows the claimed-done source next to the stubbed code; an Agent-readiness gap shows the UI action next to its missing (or unstaged, or unmarked) manifest counterpart. Each entry ends with its reconcile mark (`new`, `still open: <report> <ID>`, `regression`, `re-flagged`), and each challenged entry carries `challenge: stood — <evidence>`. Regressions go first within their severity.
4. **False positives / non-issues (verified)** — with reasoning.
5. **Worth a look (lower confidence)**.
6. **Coverage map** — what was reviewed and what was NOT reached or skipped.
7. **Workplan** — the batched, ordered, checkbox plan from Phase 4; it doubles as the fix workplan.
8. **Progress log** — seed with one dated entry: `- YYYY-MM-DD: forward pass complete, workplan created. Starting Batch A.`

**Check every pointer before you print.** Run `python3 "$SKILL/bin/cite-check.py" plan/forward-pass-<date>.md` from the project root, where `$SKILL` is this skill's base directory, printed when the skill loads. Write every path from the project root (`app/services/ledger.rb:90`, not `ledger.rb:90`); a bare filename does not resolve. A finding about a whole file cites its line 1. Fix or drop every failure and re-run until it exits 0; an unresolved pointer is a fabrication, not a typo.

Create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`. If today's report already exists, suffix `-2`. Don't commit or push; `plan/` is local.

## Phase 6 — Handoff

Whoever works the batches checks items off in this report and appends progress-log rows with the verification evidence and the commit SHA.

The next-steps note also says what `/replan-nt` does later: folds open batch items into `pending.md`/`workplan.md`, records dismissed false positives in history's Dead ends, and archives this report.
