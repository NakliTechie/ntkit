## Phase 1 — Cold start

Manufacture a genuine newcomer, recipe by surface.

**Web:**
- **Wipe everything**: a fresh browser context with no localStorage, sessionStorage, IndexedDB, cookies, cache, service workers, OPFS or picked folders. A new Playwright context is cold by default; in a persistent browser, clear site data first. **Do not seed**; empty is the thing under test.
- **Serve a production build** on `127.0.0.1` and a known-free port. A zero-build single-file app is served as shipped; say so. **If the build writes into the repo** (an asset-assembly target, a generated `site/`), replicate it into a scratch directory outside the repo and serve from there.
- **Headless Chromium has no WebGPU.** Walk model-loading beats in real Chrome (`claude-in-chrome`), or capture the pre-model first run and list the model beats as blind spots.
- **Approach from the canonical entry** (the landing URL or repo), with no deep-link shortcuts.

**CLI:**
- **Isolated `$HOME`**: run with `HOME=$(mktemp -d)` and the inherited `PATH`, so no dotfiles, cached config, saved auth or history leak in. Build or install fresh there.
- **Follow the documented install path** (the README's command), not a shortcut you know.

**TUI:**
- The CLI recipe, launched inside a detached `tmux` session (`tmux new-session -d`).
- Start at **80×24** and note it in the report; a finding that is really "the terminal was 200 columns wide" isn't a finding.

**Native (macOS / iOS):**
- **macOS:** remove `~/Library/Application Support/<app>`, the app's preferences plist and any keychain items it created, then launch fresh via `mcp__computer-use__open_application`.
- **iOS:** `xcrun simctl erase <device>`, then install and launch fresh via the Simulator tool's `launch` action.
- Request tool access (`request_access`, the simulator's device-permission prompt) as its own observed step; a newcomer sees that prompt too.

## Arm the invariants and start recording

Both go on **before the first interaction**, on every surface.

**Web invariants:** the walkthrough floor set of seven (`INV-EXC`, `INV-REJ`, `INV-ERR`, `INV-HTTP`, `INV-SILENT`, `INV-DIALOG`, `INV-DURABLE`), implemented as in `$SKILL/../walkthrough-nt/references/boot.md`. Two details matter even without it: catch rejections with `page.addInitScript(() => addEventListener("unhandledrejection", e => console.error("INV-REJ", e.reason)))`, since `pageerror` misses them; and `INV-DURABLE`'s oracle compares all persisted state, not only the active pane, or a UI reset reads as data loss. `INV-DIALOG` also enforces the house rule: an in-app toast or modal, never a native dialog. Register the auto-dismissing dialog handler first, or one `confirm()` hangs the run. `INV-SILENT` is a lead generator (28 fires, 0 findings across two runs): whitelist by class, never by beat; on a canvas surface diff the app's own state. Report zero breaches as zero. **CLI/TUI:** a non-zero exit, a stderr write, or a stack trace reaching the user. **Native:** a crash log or an `os_log` fault during the walk. Attribute each breach to the beat before it, and list the armed set in the report header.

**The recording**, into `plan/ux-review-<date>-run/`:
- **Web:** Playwright `recordVideo`, closed in a `finally` and on `SIGINT`/`SIGTERM` (mechanics in walkthrough's `boot.md`, cited above).
- **TUI:** `asciinema rec`, or `tmux capture-pane -p` per keystroke assembled into a transcript.
- **Native:** `xcrun simctl io <device> recordVideo` on iOS; a screen recording or a per-step screenshot sequence on macOS.
- **CLI:** the annotated transcript: every invocation with its stdout, stderr and exit code, in order.

**One recording per viewport.** A review that covers desktop and phone walks each as its own full pass from wiped storage, with its own recording and beat log (`desktop/`, `phone/`). The phone pass emulates a phone, not a narrow window: `isMobile`, `hasTouch`, a phone user agent, taps instead of hover. Full-page screenshots reset Chromium's touch emulation mid-run. Take viewport-only captures on the phone pass and re-check the emulation at every beat.

Keep an **append-only beat log** beside it: index, time relative to recording start (`T0`), what was done, what appeared, any invariant breach. Write "what was done" as prose from the newcomer's view ("clicked the blue Import button in the toolbar", never `click(600,337)`). If the run spans several recording segments, namespace beat indices by segment and rename each `page@<hash>.webm` to match. Take screenshots as well as video; capture both.

**Build the driver once.** Phase 2 needs a per-beat capture (screenshot, a readable DOM or accessibility snapshot, the prose note, the invariant results) keyed by beat index. Phase 3 needs the same, plus re-driving any beat-log prefix from a cold context.

**Your driver is a suspect.** Before any candidate defect earns a finding, reproduce it in a clean context with real input and a settled microtask, and confirm against the code what "working" looks like (the rule in `$SKILL/../walkthrough-nt/references/walk-and-fix.md`).
