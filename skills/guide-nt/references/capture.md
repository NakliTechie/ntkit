## Phase 4 — Capture, walking each role's route-plan

Boot whatever the route's backend needs, then walk the route-plan for that backend. A `mixed` app runs more than one of these in the same pass.

### 4a — `browser` backend (unchanged)

Same runtime discipline as `/walkthrough-nt`:
- **Serve a production build, not dev mode** — faster, pre-compiled, and the bundle users actually run. Use explicit `127.0.0.1` + a known-free port.
- **Wait for real readiness before each shot** — `load` + `document.fonts.ready` + a short settle; never `domcontentloaded` (it fires before hydration → blank screenshots).
- **Enter as each role with seeded data.** Prefer the app's own in-page hooks to inject a seeded dataset and **bypass un-automatable pickers**. Otherwise log in through the UI. Draw from the **shared demo seed** (`demo/seed/`, shared with `/demo-nt` and `/walkthrough-nt`) so the three don't drift.
- **WebGPU can't be tested headless** — headless Chromium has no WebGPU, so in-browser model inference just errors. To capture a genuinely model-loaded state, drive a real GPU browser via the **Chrome MCP** rather than headless Playwright.
- **Capture, per route**: retina (`device_scale_factor=2`), fixed viewport (e.g. 1400×900), to `guide/screenshots/<role>/NN-<slug>.png`. **Blank-capture guard** — assert the main content actually rendered (e.g. `#main` innerHTML length > 50; a blank page is also a tell-tale ~8 KB JPEG). Re-shoot or mark `empty`/`fail`. Log console errors/warnings per route — they flag screens that are secretly broken.

### 4b — `cli` backend (new)

No screenshots — the capture is the **transcript**, which is higher-fidelity than a pixel shot for text output (searchable, small, no rendering flakiness):
- Run each route-plan command via Bash exactly as a user would (real flags, real working directory), capturing stdout, stderr, and exit code.
- Write each as `guide/transcripts/<role>/NN-<slug>.txt` (raw, ANSI codes intact) — the builder renders it, not a pre-rasterized image.
- **Blank-capture guard** — exit code matches the route's declared expectation, and output is non-empty (unless the route is explicitly declared `no-output` ok, e.g. a silent success). Mismatch → mark `empty`/`fail`, same as a browser route.
- **Interactive TUIs** (curses redraws, prompts that need live keystrokes) can't be captured as a one-shot transcript — route those through the `native-macos` backend instead (drive Terminal.app via `computer-use`), not faked as plain text.
- Per-route log same as browser: `N/M commands captured ok · X non-zero exits`.

### 4c — `native-macos` backend (new)

Uses the `computer-use` MCP. This backend is **not fully unattended** — say so up front, don't discover it mid-run:
- **Request access once per app**, not per screen — call `request_access` for the target app before walking its route-plan; the user grants it interactively.
- Walk the route-plan as an action sequence (launch → click/type/wait → screenshot) per feature, mirroring a browser route's nav-and-shoot shape.
- Screenshot each state to the same `guide/screenshots/<role>/NN-<slug>.png` convention the builder already expects, so the builder doesn't need to know browser from native.
- **Blank/fail guard** — no DOM to probe; use a window-title check plus a trivial pixel-variance check (a screenshot that's one solid color is almost certainly a blank/loading/permission-dialog state) and re-shoot or mark `empty`/`fail`.
- Never type real credentials or seeded-but-sensitive data into a native app during capture; use the same demo seed discipline as the browser path where the app supports it.

A route that renders blank, errors, or exits non-zero unexpectedly is both a bad capture **and** a likely bug — note it, and hand it to `/walkthrough-nt` rather than papering over it.

**Scoped re-capture on update** (all backends) — when `$ARGUMENTS`/`update`, only re-shoot the changed/added routes; leave the rest.
