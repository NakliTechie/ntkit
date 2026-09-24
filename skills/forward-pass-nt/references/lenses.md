## Phase 1 — Map the codebase

Before reading line-by-line, build a map:
- Language(s), framework(s), build system, package manifest
- **Entry points** — server bootstrap, `main`, CLI bin, `index`, route registration, job/cron entry, message consumers
- Directory layout and architectural layers (e.g. routing → handlers → services → data)
- The **primary execution flow(s)** — how a request / command / event travels through the system

This map drives traversal order and becomes the coverage map in the report. Use Glob/Grep/Bash here; don't read every file yet.

If the repo has a feature map (`verify/features/`, left by `/walkthrough-nt`), read its index as a second input: a feature-level inventory to cross-check the coverage map against — a feature area in the map with no code path in your traversal is a blind spot to close, and vice versa is map drift worth a Stray finding. It orients the pass; it never substitutes for reading the code cold.

## Phase 2 — Forward traversal with six lenses

Walk the code **start → finish following the real flow** from entry points outward — not alphabetically. For a large app, fan out parallel subagents (Task) by module or flow-segment so coverage is thorough; for a small app, read directly.

Apply all six lenses to each unit (unless `$ARGUMENTS` narrows the focus):

**Bugs** — logic errors, off-by-one, null/undefined/None handling, unhandled edge cases, incorrect or swallowed error handling, race conditions, await/async mistakes, resource leaks (unclosed handles/connections), wrong assumptions about input shape, broken invariants, timezone/encoding/locale pitfalls.

**Security** — injection (SQL, command, XSS, template, NoSQL), authn/authz gaps and missing checks, hardcoded secrets/keys/tokens, unsafe deserialization, SSRF, path traversal, missing or weak input validation, insecure defaults, weak/misused crypto, permissive CORS/CSP, sensitive data in logs or error responses, dependency risks (known-bad or unpinned), mass-assignment, IDOR. For a security-sensitive app (untrusted network input, another user's data, an LLM agent/MCP server, or a Cloudflare/cloud deploy), also read `references/security-classes.md` for the domain-specific hunting classes this paragraph doesn't cover.

**Stray code** — dead/unreachable code, unused exports/functions/vars/imports, commented-out blocks, leftover debug logging (`console.log`, `print`, `dbg!`, `println`), `TODO`/`FIXME`/`HACK`/`XXX`, orphaned files imported nowhere, duplicated logic, leftover test/debug endpoints or backdoors, stale feature flags, dead config.

**Stubs masquerading as done** — the sharpest lens: implementations that *look* finished but aren't wired to do the real work. Chirag's recurring pain — a section gets stubbed, then marked done and forgotten. Hunt for:
- **Placeholder returns** — functions that ignore their inputs and always return the same hardcoded value (`return true`, `return []`, `return {}`, `return null`, `return 0`, `return ""`, an empty success), or return canned/mock/sample data on a *production* path.
- **Not-really-implemented bodies** — `throw new Error("not implemented")`, `NotImplementedError`, `raise NotImplementedError`, bare `pass` / `...` / empty bodies, a body that's only a `TODO`/`FIXME` comment, or a handler that logs "TODO" and returns success anyway.
- **Fakes on the live path** — `mock`/`fake`/`stub`/`dummy`/`sample`/`placeholder`/`fixture`/`hardcoded`-named symbols reachable from real entry points; a real branch short-circuited by a hardcoded flag/constant; a swallowed no-op where side effects (write, send, charge, persist) are expected but never happen.
- **The masquerade check (the point of this lens)** — cross-reference what the project *claims is complete* against what the code actually does. Read `README`, `CHANGELOG`, docs, and especially `plan/` (`history.md`, `workplan.md`, and any `[x]`/"done"/"✅"/"shipped"/"feature-complete" markers). Where something is asserted finished but the backing code is a stub per the signals above, flag it **loudly** — this gap is exactly what silently survives deploys. Note both sides: "claimed done in `plan/workplan.md:42`, but `computeTotals()` returns `[]` at `src/x.ts:88`".

A stub on a dead/unused path is Stray. A stub reachable in normal use — especially one claimed done — is a real defect: severity-rank it (usually Critical/High, since it silently breaks functionality) **and** list it in the Stubs track so it's never buried.

**Agent-readiness** — the assumption behind everything else in this kit: software gets operated by an agent, not a human, so an agent-facing door has to actually exist and hold parity with the human one. (Source: ntkit's own `DRIVER.md` and the Build Doctrine's "two doors, one core" rule. Skip this lens only for a pure library or a single-shot CLI with no persistent app surface — there's no "door" to speak of.)
- **Does a door exist at all?** Look for a declared tool/command manifest: MCP `registerTool` calls, a `window.<app>.tools` table, a documented API route list, a CLI's own subcommand set treated as its contract. A surface a human operates through a UI with **no** such door — clicking is the only way to drive it — is itself the finding. Name it once for the app, not once per screen.
- **Parity — `manifest ⊇ command bus`.** Enumerate what the UI can dispatch (buttons, menu items, form submits, keyboard commands) and diff it against what the manifest declares. Every UI action missing from the manifest is a gap, unless it's a **non-delegable act** — a signature, a consent screen, a final submit the tool exists to witness — and it's marked person-only *in the manifest*. Left off silently instead of marked is the defect; a doctrine-legal omission is not.
- **Staging on mutation.** A manifest entry that mutates state or is irreversible should stage before it lands, same commit-rule discipline as a human-facing action — an agent-callable delete/send/spend/publish that executes immediately with no staged-and-confirmed step is a real defect, not a nice-to-have.
- **DRIVER's ergonomics self-check** (full ten principles in `DRIVER.md`): a single perception act (one bounded status/brief read, not required exploration to get oriented); machine-decidable output (typed classes / closed vocabularies the agent branches on, not prose it must interpret); a stated output-size bound; a crash-safety story (atomic writes; safe to re-run after a mid-turn kill); where the trajectory/journal lives and what renders it; at least one accretion mechanism; the layer tower nameable in one line per layer; the evaluator boundary named with its fail-closed behavior. One or two missing pieces are gaps to note; three or more and the app is agent-hostile by construction — call that out as its own themed batch, not scattered single findings.
- **Attribution.** Can a machine caller's action be told apart from a human's anywhere in the app's own history or audit log? Missing attribution is Low unless the project specifically claims an audit trail.

A gap with no live caller yet still belongs in this lens — catching it before a caller exists is the whole point. A gap that's *also* live and consequential right now (an unstaged mutating tool call reachable today) gets a severity ID too, same cross-reference rule as a live-path Stub.

**Test value** — the suite that is supposed to catch the other five. Apply it when the traversal reaches tests (skip it for a repo with none, and say so in the coverage map). Read `references/test-value.md` for the hunting classes and the retention bar. Hunt tests that cannot fail for the reason they claim: assertion-free probes, expected values produced by the code under test, mocks that implement the behaviour asserted, mirror tests of source text or export lists, duplicate proof of one contract, vacuous negatives, and regression tests with no record of going red on the pre-fix code. Hunt the production side too: exports, flags, and hooks that exist only so a test can reach inside. The retention bar outranks the hunt — a test guarding a protocol, migration, security, or other contract stays even when it looks like implementation. This lens recommends; it never deletes. A test that fails on today's code is a Bugs finding, not a test to remove.
