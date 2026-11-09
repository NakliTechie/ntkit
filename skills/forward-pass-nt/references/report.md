## Phase 5 — Write the report + print

**Write `plan/forward-pass-YYYY-MM-DD.md`** in this order:

1. **Header** — date, scope, the `Reviewer:` line (per the rotation rule), the `Commit:` line (`git rev-parse --short HEAD`, plus `+dirty` when `git status --porcelain` prints anything), one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray · 4 Stub · 6 Test · 3 Agent-readiness"), and the reconcile counts (e.g. "11 new · 4 still open · 1 regression · 2 re-flagged").
2. **Verification reality** — how this app can and can't be tested (browser runtime needed? no headless path? pure-logic harness available?), so the `[test]` markers have context.
3. **Findings** — by ID, grouped Critical → High → Medium → Low → Stray → Stub → Test value → Agent-readiness. **Stubs** (`### Stubs masquerading as done`) and **Agent-readiness gaps** (`### Agent-readiness`) each get their own section, even when an entry is also listed under its severity. A Stub shows the claimed-done source next to the stubbed code; an Agent-readiness gap shows the UI action next to its missing (or unstaged, or unmarked) manifest counterpart. Each entry ends with its reconcile mark (`new`, `still open: <report> <ID>`, `regression`, `re-flagged`), and each challenged entry carries `challenge: stood — <evidence>`. Regressions go first within their severity.
   **Implicit state machines** (`### Implicit state machines`) get their own section after the findings: one entry per machine from the inventory (`references/lenses.md`), with where it lives, its states, the combinations the fields allow against the meaningful ones, its transition sites, explicit or implicit, and the IDs of the findings it produced on the code, user and agent sides. An implicit machine with no finding is still listed. Optionally, draw each implicit machine with three or more states as a Mermaid `stateDiagram-v2` block (chart choice: `$SKILL/../guide-nt/references/charts.md`): states named as the user sees them, arrows labelled with the event, nested states for sub-states, and `--` for parallel regions. Mark any state with no screen or no agent read on the diagram.
4. **False positives / non-issues (verified)** — with reasoning.
5. **Worth a look (lower confidence)**.
6. **Coverage map** — what was contract-checked, what was only read, and what was NOT reached or skipped.
7. **Workplan** — the batched, ordered, checkbox plan from Phase 4; it doubles as the fix workplan.
8. **Progress log** — seed with one dated entry: `- YYYY-MM-DD: forward pass complete, workplan created. Starting Batch A.`

**Check every pointer before you print.** Run `python3 "$SKILL/bin/cite-check.py" plan/forward-pass-<date>.md` from the project root, where `$SKILL` is the directory containing this skill's loaded `SKILL.md`. Write every path from the project root (`app/services/ledger.rb:90`, not `ledger.rb:90`); a bare filename does not resolve. A finding about a whole file cites its line 1. Fix or drop every failure and re-run until it exits 0; an unresolved pointer is a fabrication, not a typo.

Create or check `plan/` as `/decide-nt` step 2 does ([MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives)); a broken `plan` symlink stops the run. If today's report already exists, suffix `-2`. Don't commit or push; `plan/` is local.

## Phase 6 — Handoff

Whoever works the batches checks items off in this report and appends progress-log rows with the verification evidence and the commit SHA.

The next-steps note also says what `/replan-nt` does later: folds open batch items into `pending.md`/`workplan.md`, records dismissed false positives in history's Dead ends, and archives this report.
