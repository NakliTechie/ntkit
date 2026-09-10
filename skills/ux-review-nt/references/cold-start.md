## Phase 1 — Cold start (the defining setup)

Manufacture a genuine newcomer, recipe by surface:

**Web:**
- **Wipe everything.** A fresh browser context with no storage — localStorage, sessionStorage, IndexedDB, cookies, cache, service workers, OPFS, any picked folders. (A new Playwright context is cold by default; in a persistent browser, clear site data first.) **Do not seed** — empty *is* the thing under test.
- **Serve a production build** — the real bundle a newcomer hits, on explicit `127.0.0.1` + a known-free port.
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

On **CLI/TUI** the analogue is a non-zero exit code, a stderr write, or a stack trace reaching the user; on **native**, a crash log or an `os_log` fault written during the walk. Attribute each breach to the beat that preceded it, and put the armed list in the report header so a reader knows what was watched.

This command is **read-only**: an invariant breach is *reported*, never fixed. A cold-start run that trips `INV-EXC` on the first screen is one of the most valuable things this command can hand back — route it to `/walkthrough-nt`, which fixes.

**The recording.** The deliverable of a UX review is a newcomer struggling, and prose is a poor container for that. Record the walk:
- **Web (Playwright):** one context option — `browser.newContext({ recordVideo: { dir: "plan/ux-review-<date>-run/", size: { width: 1280, height: 720 } } })`. The file only lands on `context.close()`, so close in a `finally`.
- **TUI:** `asciinema rec`, or `tmux capture-pane -p` per keystroke assembled into a transcript.
- **Native:** `xcrun simctl io <device> recordVideo` on iOS; a screen recording or a per-step screenshot sequence on macOS.
- **CLI:** the annotated transcript is the recording — every invocation with its stdout/stderr and exit code, in order.

Keep an **append-only beat log** alongside it: index, timestamp, what was done, what appeared, any invariant that broke. The timestamps are what make the recording navigable from the report.
