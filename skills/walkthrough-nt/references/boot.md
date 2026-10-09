## Phase 3 — Boot the app, the browser, and a session per role

- **If a harness exists, run its `doctor` first**; it encodes this repo's freshness traps. The bullets below are the fallback for a repo without one.
- **Generated or integrity-pinned product: find the regenerator before your first edit.** Hand-editing a file that pins its own CSP script hashes blanks the page with no pointer to the cause. Find the sync target (`make`, a build script, a `--write` check) and record it in the feature map.
- **Serve a production build** (`build` + `start`); dev mode recompiles each route on first hit and times out the driver. A zero-build single file is the artifact: serve it as shipped and say so.
- **Ports:** hash the checkout path to a port when something outside the process must reach it; bind port `0` and read it back when it only has to be free. Never use 9222 (Chrome's remote-debugging port). Attach an `error` handler to every `listen`, so `EADDRINUSE` fails one check instead of crashing the run.
- **Use `127.0.0.1`, not `localhost`**; `localhost` can resolve to a different listener than the one you started.
- **Driver:** Playwright, because the recording below needs its `recordVideo`; the browser pane and browser MCPs do not record video. Headless Chromium has **no WebGPU**: drive WebGPU flows in real Chrome (`claude-in-chrome`, recorded as a GIF or a screenshot per beat), or mark them untested.
- **Wait on a condition, never a fixed sleep.** A React/Next page reads blank before hydration. Wait for `load`, `document.fonts.ready`, and an app-ready signal (a rendered root element, a state flag), not `domcontentloaded`.
- **Enter as each role**, through the UI login where possible; a seeded session cookie is the fallback. Seed from the **shared demo seed** (`demo/seed/`, also loaded by `/demo-nt` and `/guide-nt`) so no page is a pure empty state, except the first-run journeys, where empty is the thing under test. Extend the seed when a feature lands. Without `demo/seed/`, use the repo's fixture convention and name it in the report; create `demo/seed/` only if the repo has none.
- **Arm the invariant set before the first click**: named conditions checked after every action, each breach a finding with an ID even when the step looked fine. The floor set of seven (after Bombadil's zero-spec browser defaults):

  | ID | Invariant |
  |---|---|
  | `INV-EXC` | no uncaught exception / `pageerror` |
  | `INV-REJ` | no unhandled promise rejection |
  | `INV-ERR` | no `console.error` |
  | `INV-HTTP` | no 4xx/5xx response, except ones the journey deliberately provokes |
  | `INV-SILENT` | every user-initiated action changed *something* observable: a toast, a dialog, a row, a status line, a route |
  | `INV-DIALOG` | no native `alert` / `confirm` / `prompt` |
  | `INV-DURABLE` | after anything that should persist, a reload returns the same state |

  - `INV-DURABLE`'s oracle compares **all** persisted state. One that reads only the active tab, sheet or pane reports a UI-state reset as data loss.
  - Register an auto-dismissing dialog handler (`page.on("dialog", d => { log(d.type(), d.message()); d.dismiss(); })`) before the first click. An unhandled `confirm()` hangs the driver and loses the run.
  - `INV-SILENT` is a lead generator, not an oracle. Diff a text digest of the main region plus live regions before and after each action. Whitelist by class (boundary caret moves, downloads unless the context sets `acceptDownloads`, native-seam cancels, controls that render into a detached overlay), never by step. On a canvas or WebGL surface, diff the app's own state (its model, an accessor, its agent face), or disable the invariant and say so.
  - `pageerror` misses unhandled rejections. Add `page.addInitScript(() => addEventListener("unhandledrejection", e => console.error("INV-REJ", e.reason)))` and count those as `INV-REJ`, not `INV-ERR`. Tag every breach by cause, not by the channel it arrived on.
  - Report zero breaches as zero. A quiet log is not evidence the app is sound, and the set only sees what the driver requests (headless never fetches a favicon; a headed browser reports that 404 on the console channel, not the `response` event — tag by cause).
  - Add repo invariants from the repo's own CSP, locked decisions and doctrines, never a generic rule.
  - Write the armed list into the report header. Attribute each breach to the action that caused it, often several steps back.
  - No global error net in the app is itself a finding.
- **Record the run** into `plan/walkthrough-<date>-run/`:
  - **Video:** `browser.newContext({ recordVideo: { dir: "plan/walkthrough-<date>-run/", size: { width: 1280, height: 720 } } })`. The file is written only on `context.close()`: close it in a `finally` and on `SIGINT`/`SIGTERM` (a `pkill`ed driver writes no video). Budget 1.2–1.7 MB per minute at 720p. Playwright writes one `page@<hash>.webm` per context; delete zero-byte files and write `recordings.md` mapping each file to its leg and action-index range. If the driver cannot record, take a screenshot per beat and call it a contact sheet in the report.
  - **Action log**, append-only, one line per action: index, time relative to recording start (`T0`), role, journey step, the action as prose ("clicked Save on the invite dialog", not `click(600,337)`), the selector, and any invariant breach. Phase 5 replays from it.
