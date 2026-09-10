## Phase 1 — Cold start (the defining setup)

Manufacture a genuine newcomer, recipe by surface:

**Web:**
- **Wipe everything.** A fresh browser context with no storage — localStorage, sessionStorage, IndexedDB, cookies, cache, service workers, OPFS, any picked folders. (A new Playwright context is cold by default; in a persistent browser, clear site data first.) **Do not seed** — empty *is* the thing under test.
- **Serve a production build** — the real bundle a newcomer hits, on explicit `127.0.0.1` + a known-free port. **For a zero-build single-file app there is no bundle step**; serve the shipped file as-is, and say so in the report rather than inventing a build to satisfy this line. **If the repo's build writes into the repo** (an asset-assembly target, a generated `site/`), replicate it into a scratch directory outside the repo and serve from there — this command is read-only, and a build that dirties the worktree breaks that before the walk has started.
- **WebGPU can't be tested headless.** Headless Chromium has **no WebGPU**, so a local-AI app that loads/runs a model in-browser errors on the model step — you can't walk the post-load journey cold. Walk those beats with the **Chrome MCP** (a real GPU browser); otherwise capture the pre-model first-run and record the model-dependent beats as blind spots. (This is the single most common gap in a local-AI cold review.)
- **Approach from the canonical entry** the way a first-timer would — the landing URL / repo, no prior knowledge, no deep-link shortcuts. Pretend you've never seen it.

**CLI:**
- **Isolated `$HOME`.** Run with `HOME=$(mktemp -d)` (and an otherwise-inherited `PATH`) so no dotfiles, cached config, saved auth, or shell history leak in. Build/install fresh into that environment — don't reuse a warm install.
- **Approach via the documented install path** a newcomer would actually follow (the README's install command), not a shortcut you already know.

**TUI:**
- Same isolated-`$HOME` recipe as CLI, but launched inside a **detached `tmux` session** (`tmux new-session -d`) since the app is full-screen and interactive — a one-shot shell invocation can't drive it.
- Start at a **known terminal size** (e.g. 80×24) and note it in the report; TUI rendering is size-sensitive and a finding that's really "the terminal was 200 columns wide" isn't a finding.

**Native (macOS / iOS):**
- **macOS:** remove `~/Library/Application Support/<app>`, the app's preferences plist, and any keychain items it created, then launch fresh via `mcp__computer-use__open_application`.
- **iOS:** `xcrun simctl erase <device>`, then install + launch fresh via the Simulator tool's `launch` action.
- Either way, request tool access (`request_access` / the simulator's device-permission prompt) **as its own observed step**, not silently before the walk starts — a newcomer sees that prompt too.

## Arm the invariant set, and start recording

Both of these go on **before the first interaction**, on every surface. They are cheap, and each one turns a class of failure that would otherwise be invisible into evidence.

**The invariants.** A newcomer's first run is where silent breakage hides — it is the least-exercised path in daily dev, which always runs against warm state. Arm a named list of conditions checked after every beat, each producing a finding when it breaks. The web floor set:

| ID | Invariant |
|---|---|
| `INV-EXC` | no uncaught exception / `pageerror` |
| `INV-REJ` | no unhandled promise rejection |
| `INV-ERR` | no `console.error` |
| `INV-HTTP` | no 4xx/5xx response, except ones the journey deliberately provokes |
| `INV-SILENT` | every user-initiated action changed *something* observable — a toast, a dialog, a cell, a status line, a route |
| `INV-DIALOG` | no native `alert` / `confirm` / `prompt` |
| `INV-DURABLE` | after anything that should persist, a reload returns the same state |

**`INV-DIALOG` is load-bearing twice over.** It is an invariant — the house convention is an in-app toast or modal, never a native dialog — and it is **hang prevention**: an unhandled `confirm()` blocks the driver and takes the whole run with it, so you get no findings and no video rather than one finding. Register an auto-dismissing handler (Playwright: `page.on("dialog", d => { log(d.type(), d.message()); d.dismiss(); })`) *before the first interaction*, so a native dialog produces a finding instead of a dead run.

**`INV-SILENT` targets the right failure and is the hardest to implement well — treat it as a lead generator, not an oracle.** Measured across two dogfood runs it fired 28 times for zero findings; everything real came from `INV-DURABLE` and unhandled throws. Whitelist by *class* (boundary caret moves, downloads, native-seam cancels, controls that render into a detached card), never per-beat. The other four catch *noisy* failure, and a well-built app is quiet: its expensive failures are the ones where a control was clicked, a handler threw or bailed, and the UI simply did not respond. Nothing is logged, so nothing else on this list fires. After any beat that invoked a user action, diff the DOM (or a cheap proxy — a text digest of the main region plus any live-region content) against the state before it, and flag a null delta. Expect false positives on genuine no-ops (clicking an already-active tab) and whitelist those by beat rather than weakening the check.

**On a canvas or WebGL surface, `INV-SILENT` needs a repo-specific oracle or it is worse than useless.** The DOM-diff formulation assumes the UI is the DOM; against a canvas-rendered grid or map every working control reads as a silent failure. Diff the app's own state instead, or disable the invariant and say so. `INV-DURABLE`'s oracle needs the same care — one that reads only the active tab or pane will report a UI-state reset as data loss.

**Zero breaches is a normal and reportable outcome.** On a mature, well-tested app this whole set stays silent for an entire run, and that is a *result* — "the app threw nothing at a newcomer" becomes a verified claim rather than an assumption. Report the zero. Do not go hunting for something to put in the slot, and do not read a quiet invariant log as evidence the app is sound: this set catches noisy failure, and the expensive failures in a good app are quiet ones. Note also that it only sees what the driver actually does — a headless browser never requests a favicon, so an app's only 4xx can be invisible to `INV-HTTP` and turn up in Phase 4's audit instead.

**Implementing `INV-REJ`:** `pageerror` does *not* catch unhandled promise rejections, so an init script has to surface them — `page.addInitScript(() => addEventListener("unhandledrejection", e => console.error("INV-REJ", e.reason)))` — which means they arrive through the console channel. Tag and count them as `INV-REJ`, not as `INV-ERR`; without the tag the two IDs collapse into one and the distinction in this table is fiction.

On **CLI/TUI** the analogue is a non-zero exit code, a stderr write, or a stack trace reaching the user; on **native**, a crash log or an `os_log` fault written during the walk. Attribute each breach to the beat that preceded it, and put the armed list in the report header so a reader knows what was watched.

This command is **read-only**: an invariant breach is *reported*, never fixed. A cold-start run that trips `INV-EXC` on the first screen is one of the most valuable things this command can hand back — route it to `/walkthrough-nt`, which fixes.

**The recording.** The deliverable of a UX review is a newcomer struggling, and prose is a poor container for that. Record the walk:
- **Web (Playwright):** one context option — `browser.newContext({ recordVideo: { dir: "plan/ux-review-<date>-run/", size: { width: 1280, height: 720 } } })`. The file only lands on `context.close()`, so close in a `finally` — **and, because a cold walk spans many tool calls, on `SIGINT`/`SIGTERM` too.** A long-lived driver killed with `pkill` writes no video at all, losing the whole run's recording. Budget **1.2-1.7 MB per minute** at 720p (a mostly-static text surface sits at the low end, a busy grid at the high one); a 45-minute review lands near 75 MB, which is fine inside a gitignored `plan/` but is not a repo asset — drop to 1024x576 if it needs to travel. The file only lands on close, so a long run cannot be inspected mid-flight; that is a reason to segment deliberately, not a reason to skip the recording.
- **TUI:** `asciinema rec`, or `tmux capture-pane -p` per keystroke assembled into a transcript.
- **Native:** `xcrun simctl io <device> recordVideo` on iOS; a screen recording or a per-step screenshot sequence on macOS.
- **CLI:** the annotated transcript is the recording — every invocation with its stdout/stderr and exit code, in order.

Keep an **append-only beat log** alongside it: index, **timestamp relative to recording start** (`T0`), what was done, what appeared, any invariant that broke. Relative is not a detail — Playwright's video begins at t=0, so a wall-clock timestamp navigates nothing. If the run spans more than one recording segment (a browser death, a deliberate restart), namespace the beat indices by segment and rename each `page@<hash>.webm` to match, or the log points into the wrong file. **Write the "what was done" as prose from the newcomer's point of view** — "clicked the blue Import button in the toolbar", never `click(600,337)`. The timestamp is only worth what the note beside it says; a timestamp against a coordinate navigates nothing.

Screenshots are not made redundant by the video, and vice versa. Findings get *found* in stills you can read at leisure; the video is what makes a finding *land* for whoever reads the report. Capture both.

## What the harness must capture (so you can build it once)

The no-read-ahead rule would otherwise make you build the whole driver before you are allowed to read what it is for. So, stated here: **Phase 2 needs a per-beat capture** — a screenshot, a readable DOM or accessibility snapshot, the beat's prose note, and the invariant results for that beat, all keyed by beat index. Phase 3 needs the same, plus the ability to re-drive an arbitrary prefix of the beat log from a cold context. Build for that and you will not have to rebuild.

## Your driver is a suspect too

Before any of the above earns a finding: **reproduce every candidate defect in a fresh, minimal context.** A cold-start harness is code you wrote minutes ago, under time pressure, and it fails in ways that look exactly like application bugs — interleaved input from a re-entrant loop reads as data corruption; a race between a screenshot and a re-render reads as a rendering bug; a programmatic `.click()` doesn't move focus the way a real click does, so focus-restore looks broken when it isn't; state read synchronously after an `async` handler is read before the handler resumed, so persistence looks broken when it isn't.

Two checks, and the second catches most of them. **First**, drive the same action in a clean context with the instrumentation stripped — this catches environment flakes. **Second, and more often the culprit: re-derive from the code path what "working" would look like, and confirm you are observing that.** Across two dogfood runs six of ten false candidates reproduced *perfectly* in a clean context, because the fault was the assertion — observing the document when the feature renders in a card, polling 25 seconds for a call that takes 30, or missing `acceptDownloads`, which makes every export look dead to a DOM diff.

Still broken after both → a finding. The twenty minutes spent proving otherwise are cheaper than the finding you would have filed. This applies to every phase, not just the performance measurements in Phase 4.
