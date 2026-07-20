---
description: Fresh-eyes whole-app audit — walk the codebase start to finish hunting bugs, security issues, stray code, and stubs masquerading as done; rank findings with stable IDs, batch them into a fix-workplan, save to plan/
argument-hint: "[path or focus, e.g. src/api | security]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Task", "Write"]
entry: "briefed or later; a codebase to read"
exit: "batched workplan with stable finding IDs written"
writes: "plan/forward-pass-<date>.md"
---

Do a **fresh-eyes forward pass** over the project's code — a cold read of the whole app as if you've never seen it — hunting four things: **bugs**, **security issues**, **stray code**, and **stubs masquerading as done**. This is an AUDIT of the entire codebase, not a review of recent changes (that's what `/code-review`, `/review`, and `/security-review` are for — they're all diff-scoped).

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

Apply all four lenses to each unit (unless `$ARGUMENTS` narrows the focus):

**Bugs** — logic errors, off-by-one, null/undefined/None handling, unhandled edge cases, incorrect or swallowed error handling, race conditions, await/async mistakes, resource leaks (unclosed handles/connections), wrong assumptions about input shape, broken invariants, timezone/encoding/locale pitfalls.

**Security** — injection (SQL, command, XSS, template, NoSQL), authn/authz gaps and missing checks, hardcoded secrets/keys/tokens, unsafe deserialization, SSRF, path traversal, missing or weak input validation, insecure defaults, weak/misused crypto, permissive CORS/CSP, sensitive data in logs or error responses, dependency risks (known-bad or unpinned), mass-assignment, IDOR.

**Stray code** — dead/unreachable code, unused exports/functions/vars/imports, commented-out blocks, leftover debug logging (`console.log`, `print`, `dbg!`, `println`), `TODO`/`FIXME`/`HACK`/`XXX`, orphaned files imported nowhere, duplicated logic, leftover test/debug endpoints or backdoors, stale feature flags, dead config.

**Stubs masquerading as done** — the sharpest lens: implementations that *look* finished but aren't wired to do the real work. Chirag's recurring pain — a section gets stubbed, then marked done and forgotten. Hunt for:
- **Placeholder returns** — functions that ignore their inputs and always return the same hardcoded value (`return true`, `return []`, `return {}`, `return null`, `return 0`, `return ""`, an empty success), or return canned/mock/sample data on a *production* path.
- **Not-really-implemented bodies** — `throw new Error("not implemented")`, `NotImplementedError`, `raise NotImplementedError`, bare `pass` / `...` / empty bodies, a body that's only a `TODO`/`FIXME` comment, or a handler that logs "TODO" and returns success anyway.
- **Fakes on the live path** — `mock`/`fake`/`stub`/`dummy`/`sample`/`placeholder`/`fixture`/`hardcoded`-named symbols reachable from real entry points; a real branch short-circuited by a hardcoded flag/constant; a swallowed no-op where side effects (write, send, charge, persist) are expected but never happen.
- **The masquerade check (the point of this lens)** — cross-reference what the project *claims is complete* against what the code actually does. Read `README`, `CHANGELOG`, docs, and especially `plan/` (`history.md`, `workplan.md`, and any `[x]`/"done"/"✅"/"shipped"/"feature-complete" markers). Where something is asserted finished but the backing code is a stub per the signals above, flag it **loudly** — this gap is exactly what silently survives deploys. Note both sides: "claimed done in `plan/workplan.md:42`, but `computeTotals()` returns `[]` at `src/x.ts:88`".

A stub on a dead/unused path is Stray. A stub reachable in normal use — especially one claimed done — is a real defect: severity-rank it (usually Critical/High, since it silently breaks functionality) **and** list it in the Stubs track so it's never buried.

## Phase 3 — Aggregate, dedupe, rank, assign IDs

Collect all findings. Dedupe across subagents. Rank by severity and **assign each a stable ID** so it can be referenced everywhere downstream (workplan, progress log, commits):

- **Critical → `C1, C2, …`** — exploitable security hole, data loss, or a bug that breaks core functionality in normal use
- **High → `H1, H2, …`** — likely-hit bug or real security weakness; fix before shipping
- **Medium → `M1, M2, …`** — real issue, narrower blast radius or rarer trigger
- **Low → `L1, L2, …`** — minor bug or hardening opportunity
- **Stray → `S1, S2, …`** — dead/leftover code (separate track, not severity-ranked)
- **Stub → `SB1, SB2, …`** — stub masquerading as done (separate track). A live-path/claimed-done stub ALSO gets a severity ID (usually C/H) — cross-reference the two so a fake-done section shows up in both places and can't be lost.

Each finding: `**ID** [Bug|Security|Stray|Stub] path:line — what it is · why it matters · suggested fix`. For a Stub, name the masquerade explicitly: what's claimed (and where) vs. what the code actually does.

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

1. **Header** — date, scope, one-line summary counts (e.g. "2 Critical · 9 High · 7 Medium · 8 Low · 9 Stray · 4 Stub").
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

Do NOT start fixing. The forward pass finds, ranks, and plans; the user decides what to execute.
