---
description: Role-driven browser walkthrough — identify each user role, drive the running app through their journeys in a real browser, catch logical errors as they surface, and fix them. A live runtime audit, not a static read.
argument-hint: "[role or flow to focus, e.g. admin | checkout]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "app boots with the shared demo seed"
exit: "every role walked in a real browser; fixes committed; verification harness created or extended; report written"
writes: "code, the committed verification harness, plan/walkthrough-<date>.md"
---

Drive the **running app through a real browser, one user role at a time** — walking each role's journeys exactly as that user would — and **fix the logical errors you hit along the way**. This is a *live runtime* audit: the inverse of `/forward-pass-nt`, which reads the code cold and never runs or touches anything. Walkthrough boots the app, clicks through it as each role, watches what actually happens, and repairs what's broken.

**This command edits code, iteratively.** The moment it hits a logical error it fixes it *in place* — reproduce, root-cause, fix, re-verify in the browser — then walks on. It does not collect a findings dump and fix later: you're already booted, seeded, and logged in at the exact spot the bug lives, and fixing now unblocks the downstream journey a broken step would otherwise hide. Only *clear* logical errors get fixed inline; anything that changes product behavior, needs a design call, or is a large refactor gets **deferred** to the workplan (point at `/decide-nt`), never force-applied. It does not commit or push — the fixes sit in the working tree for review (`/windup-nt` ships them).

If the project has no browser surface (pure CLI, library, backend-only), say so and suggest `/forward-pass-nt` instead. If the current directory isn't a git repo, ask which project — don't guess.

**Stronger with different eyes.** This is a checker command — its whole value is that it doesn't share the maker's blind spots. Fresh context is the floor; running it from a **different model family** than the one that built the code is the stronger posture, since two contexts of the same model still misjudge the same things identically. If you *are* the family that built most of this code, say so in the report header — the reader should know which grade of eyes graded it.

`$ARGUMENTS` (optional): a role (`admin`) or a flow (`checkout`) to scope to. If empty, cover every role and their primary journeys.

## Phase 1 — Identify the roles

Derive the cast of users from the **code**, not from guesses. Look for:
- **Auth / RBAC** — role enums, permission/policy tables, route guards and middleware, `if (user.role === …)` / `can?()` / `@requires_role`, plan/tier feature flags.
- **UI that forks by role** — role-gated nav, menus, components, admin-only screens.
- **Seed data, fixtures, test users** — and any existing logins you can reuse.
- **Docs** — README / handoff personas.

Always include two roles the code rarely names explicitly but every real user passes through:
- **Anonymous visitor** — unauthenticated; landing, signup, public pages, and the auth wall itself.
- **Brand-new user with zero data** — the **first-run** path. This is literally a new user's first action and is the least-exercised flow in daily dev (which always runs against existing data), so it's where silent breakage hides.

Produce a **role inventory**: for each role — name · how it authenticates · what it can reach · the credentials or seed to enter as it. If a role's auth or credentials are unknown, **ask the user** — never invent or hardcode auth. If roles are ambiguous, confirm the list before driving.

## Phase 2 — Map each role's journeys

For each role, list the **features/flows to exercise** — entry-points first, following the real flows a user of that role would take. Build a per-role checklist, e.g.:
- *admin*: invite a user → change a setting → read the audit log → revoke access
- *member*: sign up → **create your first <thing>** → edit it → delete it → log out and back in
- *anonymous*: land → sign up → hit a protected URL and get bounced

Mark the **first-run / empty-state** journeys explicitly — they get tested deliberately, not skipped. `$ARGUMENTS` narrows this to one role or one flow.

## Phase 3 — Boot the app, the browser, and a session per role

Get a running app and a browser driving it:
- **Start the app — prefer a production build over dev mode.** Dev mode recompiles each route on first hit (slow, times out the driver) and isn't the bundle users actually run; a `build` + `start` is pre-compiled and fast. Dev is a fallback.
- **Drive it with the browser tooling available** (the `preview_*` tools if present; otherwise Playwright or a browser MCP). Use explicit `127.0.0.1` and a known-free port — "localhost" can resolve to a different listener than the one you started.
- **WebGPU can't be tested headless.** Headless Chromium has **no WebGPU** — any flow that loads or runs a model in-browser via WebGPU (and other GPU-gated features) errors out headless. Drive those flows with the **Chrome MCP** (a real, GPU-backed Chrome), not headless Playwright; otherwise mark them untested.
- **Wait for the app to actually be ready before asserting** — a React/Next page returns blank if you read before hydration. Wait for `load` + `document.fonts.ready` + a short settle, not just `domcontentloaded`.
- **Enter as each role.** Prefer logging in *through the UI* (it exercises the real auth flow as that role); injecting a seeded session cookie is the fallback. Seed enough data that no page is a pure empty-state — **except** the first-run journeys, where empty *is* the thing under test. Draw from the **shared demo seed** (`demo/seed/` — the canonical asset `/demo-nt`, `/guide-nt`, and `/walkthrough-nt` all load); extend it when a feature lands, rather than inventing per-command seed data.
- **Turn on an error surface before you start clicking.** Capture `console`, `pageerror`/uncaught exceptions, unhandled rejections, and failed/4xx/5xx network responses for the whole run. If the app has no global error net, that absence is itself a finding — an exception in an event handler otherwise produces *nothing* (no toast, no log), which is exactly how a dead button survives for months.

## Phase 4 — Walk and fix, one step at a time

This is the heart of the command, and it's a **loop, not two passes**: walk a step → if it breaks, fix it and re-verify *right there* → then continue the journey. You're already booted, seeded, and logged in as the role at the exact spot the bug lives — that runtime state is the most expensive thing you have, so spend it now rather than re-deriving the repro later. Fixing in place also **unblocks downstream coverage**: a broken "create your first thing" hides every bug behind it; fix it and you get to walk the rest.

For each role, drive the browser through each journey, repeating this loop per step:

1. **Act** — click the real controls, fill real forms, submit, navigate. Don't shortcut via URLs unless you're testing deep links.
2. **Observe** — after every meaningful action: did the UI change as expected? did the right data render? did the action actually *do* something? Check the console, the network tab, and the resulting state. Hunt the **logical-error class static analysis misses**:
   - a control that silently does nothing — dead button, a handler that threw, a promise that never settles
   - wrong / stale data; optimistic UI that diverges from the server; totals that don't add up
   - broken validation — accepts bad input, or rejects good input; a form that loses data on error
   - navigation dead-ends, broken back-button, double-submit, lost session
   - **first-run / empty-state** broken (the create-from-scratch path)
   - display bugs in currency / dates / numbers / locale; off-by-one in lists and pagination
3. **If it broke, fix it now.** First give it a stable ID by severity — `C1/H1/M1/L1` (Critical / High / Medium / Low), the same scheme `/forward-pass-nt` uses so the IDs read the same downstream — and capture evidence: repro steps · expected vs. observed · a console/network excerpt · a screenshot. Then close the loop:
   - **Reproduce** to be sure it's real — don't fix a symptom you can't trigger.
   - **Root-cause** it — read the handler / component / service. Common culprits: an exception thrown inside an event handler or async callback; reading DOM/state *after* a teardown (modal close, unmount); a promise resolved inside a handler that hangs when the handler throws.
   - **Fix minimally** — match the surrounding code; smallest change that corrects the behavior.
   - **Re-verify in the browser** — re-walk that exact step; confirm it works *and* throws no new console error. If the edit triggered an HMR reload or a restart, **re-establish the role's session and seed before continuing** — a reload can silently drop you back to anonymous.
4. **Continue** the journey from where you were.

**Two guardrails so the loop stays a walkthrough, not a refactor:**
- **Timebox each fix.** If the root cause turns into a large refactor, a shared-contract change, or anything that alters product behavior / needs a design call — **don't fix it inline. Defer it**: log the finding ID with what's broken and what would unblock it, point at `/decide-nt`, and keep walking. Iterative ≠ reckless.
- **One fix at a time, re-verified**, so a fix doesn't silently mask or cause the next bug.

Run a **cross-role authorization probe** as part of the walk: as a low-privilege role, try a high-privilege action or URL directly — does the guard hold, or does the UI just hide the button (IDOR / privilege leak)? Fix a leak in place, or defer it if it needs a policy call.

For surfaces the browser can't drive — payments, outbound email, native file pickers/dialogs — **stub the seam** (monkeypatch the global, e.g. `window.showSaveFilePicker = async () => fakeHandle`) so the journey continues, and note what was stubbed vs. genuinely exercised.

## Phase 4.5 — Leave the lever

A walkthrough that only fixes what it found re-derives everything next time. Before reporting, **distill the journeys just walked into a committed, rerunnable verification harness** — a script (`scripts/verify.*` or whatever the repo's convention is) that drives the app through each role's core journeys and exits non-zero on failure. Committed to the repo, not `plan/` — the point is that anyone (or any later run) can rerun the evidence.

- **First walkthrough:** create it from the journeys walked — the smallest script that proves each role's happy path.
- **Later walkthroughs:** run it first (regressions surface for free), then walk what it can't reach, then extend it with anything new.
- **What it can't drive** (payment, email, native dialogs) stays in the report's blind-spot list — the harness covers what's automatable, never pretends to more.

This harness **is the project's verifier** from now on: `/release-nt`'s gate runs it, `/autopilot-nt`'s final gate runs it. A repo with one no longer passes the release guard vacuously — the lever is the definition of green.

## Phase 5 — Report + handoff

**Write `plan/walkthrough-YYYY-MM-DD.md`** — a self-contained record, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.
1. **Header** — date, scope (roles × journeys covered), counts: *found / fixed / deferred*.
2. **Role inventory + coverage map** — each role, the journeys walked, and — crucially — **what was NOT reached**: roles you couldn't authenticate, flows you couldn't drive (payment, email, native dialogs), states you couldn't reach. The blind spots.
3. **Issues** by ID, grouped Critical → High → Medium → Low — each: role · journey step · symptom · root cause · then either **FIXED: `path:line` + verification evidence** or **DEFERRED: why + what unblocks** (`→ /decide-nt`).
4. **Cross-role / authz findings** — privilege leaks and guards that held.
5. **Verification reality** — what the browser could and couldn't exercise this run, and what was stubbed.
6. **Progress log** — seed one dated entry: `- YYYY-MM-DD: walkthrough complete — N roles, M journeys; X fixed, Y deferred.`

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. **Don't overwrite the canonical `workplan.md`** — this report carries its own deferred items; `/replan-nt` folds them into `pending.md` / `workplan.md`.

**Print to chat:** the counts, the issues grouped *fixed* vs. *deferred* (with one-line evidence each), and the coverage map's blind spots. Keep the full detail in the file.

The code fixes are **live in the working tree, uncommitted** — don't commit or push. End by naming what changed, what's deferred (and why), and that `/windup-nt` will ship the fixes when the user is ready.
