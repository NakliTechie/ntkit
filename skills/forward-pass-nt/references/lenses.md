## Phase 1 — Map the codebase

Before reading line-by-line, build a map:
- Language(s), framework(s), build system, package manifest
- **Entry points** — server bootstrap, `main`, CLI bin, `index`, route registration, job/cron entry, message consumers
- Directory layout and architectural layers (e.g. routing → handlers → services → data)
- The **primary execution flow(s)** — how a request / command / event travels through the system

This map drives traversal order and becomes the coverage map in the report. Use Glob/Grep/Bash here; don't read every file yet.

If the repo has a feature map (`verify/features/`, left by `/walkthrough-nt`), read its index as a second input: a feature-level inventory to cross-check the coverage map against — a feature area in the map with no code path in your traversal is a blind spot to close, and vice versa is map drift worth a Stray finding. It orients the pass; it never substitutes for reading the code cold.

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
