## Phase 4 — Walk and fix, one step at a time

This is the heart of the command, and it's a **loop, not two passes**: walk a step → if it breaks, fix it and re-verify *right there* → then continue the journey. You're already booted, seeded, and logged in as the role at the exact spot the bug lives — that runtime state is the most expensive thing you have, so spend it now rather than re-deriving the repro later. Fixing in place also **unblocks downstream coverage**: a broken "create your first thing" hides every bug behind it; fix it and you get to walk the rest.

For each role, drive the browser through each journey, repeating this loop per step:

1. **Act** — click the real controls, fill real forms, submit, navigate. Don't shortcut via URLs unless you're testing deep links.
2. **Observe** — after every meaningful action, two checks, not one. **The invariant set** armed in Phase 3 (`INV-EXC`, `INV-REJ`, `INV-ERR`, `INV-HTTP`, plus this repo's own) is checked mechanically — a breach is a finding with an ID even when the step looked fine, attributed to the action before it. **Then judgement:** did the UI change as expected? did the right data render? did the action actually *do* something? Check the network tab and the resulting state. Hunt the **logical-error class static analysis misses**:
   - a control that silently does nothing — dead button, a handler that threw, a promise that never settles
   - wrong / stale data; optimistic UI that diverges from the server; totals that don't add up
   - broken validation — accepts bad input, or rejects good input; a form that loses data on error
   - navigation dead-ends, broken back-button, double-submit, lost session
   - **first-run / empty-state** broken (the create-from-scratch path)
   - display bugs in currency / dates / numbers / locale; off-by-one in lists and pagination
3. **If it broke, fix it now.** First give it a stable ID by severity — `C1/H1/M1/L1` (Critical / High / Medium / Low), the same scheme `/forward-pass-nt` uses so the IDs read the same downstream — and capture evidence: repro steps · expected vs. observed · a console/network excerpt · a screenshot. Then close the loop:
   - **Check your assertion before you check your environment — your driver is a suspect, and the suspect is usually the assertion.** Don't fix a symptom you can't trigger, and don't fix one you triggered only through your own instrumentation. A harness written minutes ago fails in ways that look exactly like application bugs: a re-entrant input loop interleaves characters and reads as data corruption; a race between a screenshot and a re-render reads as a rendering bug; a programmatic `.click()` doesn't move focus the way a real click does, so focus-restore looks broken when it isn't; state read synchronously after an `async` handler is read before the handler resumed, so persistence looks broken when it isn't. Two checks, and **the second one catches most of them**:

     1. **Re-run in a clean context** with the instrumentation stripped. This catches environment flakes — races, re-entrancy, leaked state.
     2. **Re-derive, from the code path, what "working" would actually look like — then confirm you are observing that.** Across two dogfood runs, *six of the ten* false candidates reproduced perfectly in a clean context, because the fault was in the assertion, not the environment: asserting on the document when the feature renders in a card; polling 25 seconds for a call that takes 30; reading the active sheet when the state lives per-sheet; missing `acceptDownloads`, which makes every export look dead to a DOM diff; treating a toggle's second click as a second open. A clean re-run confirms each of those *beautifully*, three times out of three.

     Still broken after both → real. **This command edits code, so the cost of skipping this is a commit that changes working code in a shipped product to chase an artifact you created.** One run was a single probe away from rewiring a working handler.
   - **Root-cause** it — read the handler / component / service. Common culprits: an exception thrown inside an event handler or async callback; reading DOM/state *after* a teardown (modal close, unmount); a promise resolved inside a handler that hangs when the handler throws.
   - **Fix minimally** — match the surrounding code; smallest change that corrects the behavior.
   - **Re-verify in the browser** — re-walk that exact step; confirm it works *and* throws no new console error. If the edit triggered an HMR reload or a restart, **re-establish the role's session and seed before continuing** — a reload can silently drop you back to anonymous.
   - **Commit it** — one focused commit for the fix, by path, local only. The runtime state you're carrying (booted, seeded, logged in) is expensive and fragile; the commit makes the fix durable even if the session isn't.
4. **Continue** the journey from where you were.

**Two guardrails so the loop stays a walkthrough, not a refactor:**
- **Timebox each fix.** If the root cause turns into a large refactor, a shared-contract change, or anything that alters product behavior / needs a design call — **don't fix it inline. Defer it**: log the finding ID with what's broken and what would unblock it, point at `/decide-nt`, and keep walking. Iterative ≠ reckless.
- **One fix at a time, re-verified**, so a fix doesn't silently mask or cause the next bug.

Run a **cross-role authorization probe** as part of the walk: as a low-privilege role, try a high-privilege action or URL directly — does the guard hold, or does the UI just hide the button (IDOR / privilege leak)? Fix a leak in place, or defer it if it needs a policy call.

For surfaces the browser can't drive — payments, outbound email, native file pickers/dialogs — **stub the seam** (monkeypatch the global, e.g. `window.showSaveFilePicker = async () => fakeHandle`) so the journey continues, and note what was stubbed vs. genuinely exercised.

**Stub the seams before the chaos leg, or skip that leg.** Phase 5 drives a *random* walk over these same controls, so a seam that is merely avoided by the scripted journey will eventually be hit by an unscripted one — an un-stubbed payment or mail path is the reason a chaos leg gets skipped rather than run.
