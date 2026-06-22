---
description: Fresh-eyes whole-app audit — walk the codebase start to finish hunting bugs, security issues, and stray code; rank findings with stable IDs, batch them into a fix-workplan, save to plan/
argument-hint: "[path or focus, e.g. src/api | security]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task", "Write"]
---

Do a **fresh-eyes forward pass** over the project's code — a cold read of the whole app as if you've never seen it — hunting three things: **bugs**, **security issues**, and **stray code**. This is an AUDIT of the entire codebase, not a review of recent changes (that's what `/code-review`, `/review`, and `/security-review` are for — they're all diff-scoped).

**READ-ONLY.** Report, rank, and plan — never edit code, never auto-fix.

`$ARGUMENTS` (optional): a path to scope the pass (e.g. `src/api`), or a focus hint (e.g. `security`). If empty, audit the whole app with all three lenses.

## Phase 1 — Map the codebase

Before reading line-by-line, build a map:
- Language(s), framework(s), build system, package manifest
- **Entry points** — server bootstrap, `main`, CLI bin, `index`, route registration, job/cron entry, message consumers
- Directory layout and architectural layers (e.g. routing → handlers → services → data)
- The **primary execution flow(s)** — how a request / command / event travels through the system

This map drives traversal order and becomes the coverage map in the report. Use Glob/Grep/Bash here; don't read every file yet.

## Phase 2 — Forward traversal with three lenses

Walk the code **start → finish following the real flow** from entry points outward — not alphabetically. For a large app, fan out parallel subagents (Task) by module or flow-segment so coverage is thorough; for a small app, read directly.

Apply all three lenses to each unit (unless `$ARGUMENTS` narrows the focus):

**Bugs** — logic errors, off-by-one, null/undefined/None handling, unhandled edge cases, incorrect or swallowed error handling, race conditions, await/async mistakes, resource leaks (unclosed handles/connections), wrong assumptions about input shape, broken invariants, timezone/encoding/locale pitfalls.

**Security** — injection (SQL, command, XSS, template, NoSQL), authn/authz gaps and missing checks, hardcoded secrets/keys/tokens, unsafe deserialization, SSRF, path traversal, missing or weak input validation, insecure defaults, weak/misused crypto, permissive CORS/CSP, sensitive data in logs or error responses, dependency risks (known-bad or unpinned), mass-assignment, IDOR.

**Stray code** — dead/unreachable code, unused exports/functions/vars/imports, commented-out blocks, leftover debug logging (`console.log`, `print`, `dbg!`, `println`), `TODO`/`FIXME`/`HACK`/`XXX`, orphaned files imported nowhere, duplicated logic, leftover test/debug endpoints or backdoors, stale feature flags, dead config.

## Phase 3 — Aggregate, dedupe, rank, assign IDs

Collect all findings. Dedupe across subagents. Rank by severity and **assign each a stable ID** so it can be referenced everywhere downstream (workplan, progress log, commits):

- **Critical → `C1, C2, …`** — exploitable security hole, data loss, or a bug that breaks core functionality in normal use
- **High → `H1, H2, …`** — likely-hit bug or real security weakness; fix before shipping
- **Medium → `M1, M2, …`** — real issue, narrower blast radius or rarer trigger
- **Low → `L1, L2, …`** — minor bug or hardening opportunity
- **Stray → `S1, S2, …`** — dead/leftover code (separate track, not severity-ranked)

Each finding: `**ID** [Bug|Security|Stray] path:line — what it is · why it matters · suggested fix`.

**Preserve dismissals — don't silently drop.** When you discard something as a false positive or non-issue, record it in a dedicated **"False positives / non-issues (verified)"** list WITH the one-line reasoning that cleared it (e.g. `C3 — false positive: getStockOnHand sums batches only; the opening-stock column is never added to a total`). This stops the next forward pass from re-flagging it. Still drop pure linter/typechecker/CI noise without ceremony.

Keep a short **"Worth a look (lower confidence)" → `W1, W2, …`** bucket for fresh-eyes hunches you couldn't fully verify — don't hide them, don't inflate their severity.

## Phase 4 — Batch the findings into a fix-workplan

Turn the actionable findings (everything except false-positives/non-issues) into an **ordered, batched workplan** — the executable counterpart to the findings list:

- **Group into themed batches** by area/subsystem (e.g. "Transaction integrity", "Input validation", "Auth"), not by severity — related fixes that touch the same code travel together.
- **Order batches for execution.** Put a keystone first — a batch others depend on — and mark it: `## Batch A — <theme>  (keystone)`. Respect sequencing.
- **Tri-state checkboxes** on every item: `[ ]` open · `[x]` done · `[~]` partial.
- **Each item carries** its finding ID, precise location, and a one-line "what + why it works": `- [ ] **H5** <fix> (path:line). <one-line rationale>.`
- **`[test]` markers** — append e.g. **[test: <how>]** to any item whose fix can't be verified by static reasoning or unit tests and needs a runtime check.
- **Deferrals state why + what unblocks.** A `[~]` partial or deferred item must say what's done, what's left, and what would un-defer it — and point at `/decide-nt` when the blocker is a decision: `DEFERRED: needs a versioned-hash migration story — decide first (/decide-nt).`

## Phase 5 — Write the report + print

**Write `plan/forward-pass-YYYY-MM-DD.md`** — a self-contained audit-and-fix artifact, in this order:

1. **Header** — date, scope, one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray").
2. **Verification reality** — a short note on how this app can/can't be tested (browser runtime needed? no headless path? pure-logic harness available?), so the `[test]` markers have context.
3. **Findings** — by ID, grouped Critical → High → Medium → Low → Stray.
4. **False positives / non-issues (verified)** — preserved with reasoning.
5. **Worth a look (lower confidence)**.
6. **Coverage map** — what was reviewed and, crucially, what was NOT reached or skipped (the blind spots).
7. **Workplan** — the batched, ordered, checkbox plan from Phase 4. This section doubles as the fix workplan; work straight from it.
8. **Progress log** — seed with one dated entry: `- YYYY-MM-DD: forward pass complete, workplan created. Starting Batch A.`

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. Don't commit/push — plan/ is local. **Do not overwrite the canonical `workplan.md`** — this report carries its own Workplan section. (Promotion into `workplan.md` happens via `/replan-nt`, or offer to move it if the user has no competing workplan.)

**Print to chat:** the summary counts + findings grouped by severity + the coverage map. Keep the full batched workplan in the file (just say it's there and name the keystone batch).

## Phase 6 — Handoff

End with a tight next-steps note (don't act on it):
- The keystone batch to start with
- Any architectural finding a fix is *blocked on* — record it with `/decide-nt` (e.g. a hash-migration decision)
- As you work the batches: check items off in the report, and append progress-log entries with **verification evidence** (`tests pass; still needs runtime test: C1`) and the **commit SHA** pushed
- `/replan-nt` will fold open batch items into `pending.md`/`workplan.md`, record dismissed false-positives into history's Dead ends, and archive this report

Do NOT start fixing. The forward pass finds, ranks, and plans; the user decides what to execute.
