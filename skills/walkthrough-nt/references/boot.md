## Phase 3 — Boot the app, the browser, and a session per role

Get a running app and a browser driving it:
- **If a harness already exists, run its `doctor` first** — it encodes this repo's specific freshness traps. The bullets below are the fallback for a repo that doesn't have one yet.
- **Start the app — prefer a production build over dev mode.** Dev mode recompiles each route on first hit (slow, times out the driver) and isn't the bundle users actually run; a `build` + `start` is pre-compiled and fast. Dev is a fallback.
- **Drive it with the browser tooling available** (the `preview_*` tools if present; otherwise Playwright or a browser MCP). Use explicit `127.0.0.1` and a known-free port — "localhost" can resolve to a different listener than the one you started.
- **WebGPU can't be tested headless.** Headless Chromium has **no WebGPU** — any flow that loads or runs a model in-browser via WebGPU (and other GPU-gated features) errors out headless. Drive those flows with the **Chrome MCP** (a real, GPU-backed Chrome), not headless Playwright; otherwise mark them untested.
- **Wait for the app to actually be ready before asserting** — a React/Next page returns blank if you read before hydration. Wait for `load` + `document.fonts.ready` + a short settle, not just `domcontentloaded`.
- **Enter as each role.** Prefer logging in *through the UI* (it exercises the real auth flow as that role); injecting a seeded session cookie is the fallback. Seed enough data that no page is a pure empty-state — **except** the first-run journeys, where empty *is* the thing under test. Draw from the **shared demo seed** (`demo/seed/` — the canonical asset `/demo-nt`, `/guide-nt`, and `/walkthrough-nt` all load); extend it when a feature lands, rather than inventing per-command seed data.
- **Arm the invariant set before you start clicking.** Not "watch the console" — a **named list of conditions checked after every action**, each of which produces a finding with an ID when it breaks, exactly like a step that visibly failed. The floor set, borrowed from Bombadil's zero-spec browser defaults:

  | ID | Invariant |
  |---|---|
  | `INV-EXC` | no uncaught exception / `pageerror` |
  | `INV-REJ` | no unhandled promise rejection |
  | `INV-ERR` | no `console.error` |
  | `INV-HTTP` | no 4xx/5xx response, except ones the journey deliberately provokes |
  | `INV-SILENT` | every user-initiated action changed *something* observable — a toast, a dialog, a row, a status line, a route |

  **`INV-SILENT` is the one that pays.** The other four catch *noisy* failure. The dead button this command exists to find is quiet by definition: the handler threw or bailed, nothing was logged, and the UI simply did not respond. After any action, diff the DOM (or a cheap proxy — a text digest of the main region plus live-region content) against the state before it and flag a null delta; whitelist genuine no-ops by step rather than weakening the check.

  **Implementing `INV-REJ`:** `pageerror` does not catch unhandled promise rejections, so surface them with an init script — `page.addInitScript(() => addEventListener("unhandledrejection", e => console.error("INV-REJ", e.reason)))` — and tag them, because they arrive through the console channel and will otherwise be counted as `INV-ERR`.

  Extend it with anything this repo protects — a sovereignty invariant (no outbound request to a third-party origin), a budget (no bundle over N), a domain rule that must hold on every screen. Write the list into the report header so a reader knows what was being watched, and **attribute each breach to the action that preceded it** — an exception that fires three steps after the click that caused it is the normal case, not the exception.

  The point of naming them is that they catch what the scripted journey isn't looking at. A step can *look* correct — the right screen rendered, the right row appeared — while a handler threw on the way. Judgement checks the step; the invariants check everything the step didn't think to check.

  **If the app has no global error net, that absence is itself a finding** — an exception in an event handler otherwise produces *nothing* (no toast, no log), which is exactly how a dead button survives for months.

- **Record the run, and log every action.** Two artifacts, both into `plan/walkthrough-<date>-run/` (gitignored — a video is not a repo asset):
  - **A recording.** With Playwright this is one context option, so there is no excuse to skip it: `browser.newContext({ recordVideo: { dir: "plan/walkthrough-<date>-run/", size: { width: 1280, height: 720 } } })`. The file is only written on `context.close()`, so close the context in a `finally` — **and on `SIGINT`/`SIGTERM`**, because this walk spans many tool calls and a driver killed with `pkill` writes no video at all. Budget roughly **1.7 MB per minute** at 720p. If the driver genuinely cannot record, fall back to a screenshot per beat and say in the report that the recording is a contact sheet, not a video.
  - **An append-only action log** — one line per action: index, timestamp, role, journey step, the action **written as prose a reader can follow** ("clicked Save on the invite dialog", not `click(600,337)`), the selector or target, and any invariant that broke. This is what makes a finding *replayable* rather than described (Phase 5), and it is what the step narrative's timestamps point into, so a reader can jump to the moment in the recording instead of reading a repro paragraph.
