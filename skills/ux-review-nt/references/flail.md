## Phase 3 — The flail

Phase 2 walks the path a newcomer is *supposed* to take. **Real newcomers don't take it.** They click the thing that looked like a button, land somewhere they didn't mean to go, hit back, hit back again, and try to get home. The canonical journey cannot cover that by construction — it is written by someone who knows where they're going.

So after the scripted walk, from the states it reached, flail:

1. **Click what a confused person would click** — not what the journey says next. The prominent thing. The thing that looks clickable but isn't. The nav item whose label is ambiguous. Decorative chrome. The logo.
2. **Then try to get back** to where you were, or to something recognizable. This is the measurement, not the misclick.
3. **Interrupt things.** Navigate mid-load. Hit back after a submit. Double-click submit. Close the modal with Escape instead of the button, and with the button instead of Escape. Refresh mid-flow. Open a deep link in a fresh tab with no prior state.
4. **Enter the wrong thing.** Empty required field, absurdly long string, wrong format, leading whitespace, the wrong file type — and read the error as a person who doesn't know the internals.
5. **Deny every permission** the app asks for, then keep going.
6. **Refresh after every state change that should be durable**, and check you land where you left off. Do a thing, reload, look. This is the cheapest probe on the list and it finds the most alarming class of defect there is — an app that reopens on a *different* document than the one you were writing is a data-loss story to a newcomer even when the work is technically recoverable.
7. **Feed every ingest point the wrong artifact.** Wherever the app accepts data — a file picker, a paste target, an import dialog, a URL field — give it the wrong type, an empty file, a binary, something enormous. This is the *value*-shaped probe, and it is a different axis from the five action-shaped ones above: the app's most confident lies live here. An importer that accepts a PNG through "CSV file…", invents rows, and toasts *"Imported 3 rows"* is worse than a crash, and no scripted journey will ever hand it a PNG.

### What this phase is looking for — and what it isn't

**The finding class here is recoverability, not crashes.** Crashes are the Phase 1 invariant set's job and get reported the same way wherever they fire. What the flail is uniquely for:

- **Dead ends** — a state with no visible way back, forward, or out.
- **Lost work** — a form that empties on a validation error, a back-button that discards, a refresh that resets a half-finished setup.
- **Unrecoverable state** — a wrong early choice with no way to change it later, a denied permission that leaves a permanently broken screen with no re-ask.
- **Traps** — a modal that Escape won't close, a focus trap, a flow with no cancel.
- **Errors that don't tell you what to do** — the message names a symptom, an error code, or nothing at all, and the newcomer's next move is invisible.

**Budget: ~30 interactions for the flail itself, plus up to 10 more to produce a clean repro of anything it surfaces. Report both numbers.** The overrun is structural, not sloppiness: step 2 ("then try to get back") implicitly requires re-running a suspicious state cleanly, and a finding first seen tangled with unrelated state takes several attempts to isolate. Expect 20-30 minutes. Interactions are the bound you actually control — the wall-clock is not 15 minutes, because each misclick needs a screenshot read plus a follow-up probe to tell a real defect from a harness artifact, and that verification is not optional (see *Your driver is a suspect too*). Declare the budget in the report whether or not it yielded anything — "flail: 30 interactions across 2 entry points, 3 findings" and "flail: skipped" are different facts.

**Skip it deliberately, never silently.** If the cold app has irreversible side effects a random misclick would genuinely trigger — sends real mail, charges a card, writes upstream — say so and skip. That is a legitimate outcome, and it is also itself worth a line in the findings: an app where a newcomer's misclick is unrecoverable in the real world is a design problem, not just a testing obstacle.

**Still read-only.** Nothing here is fixed. A dead end is a finding with a proposed fix, tagged quick-win or structural like any other.
