## Phase 4 — Capture, walking each role's route-plan

Boot whatever the route's backend needs, then walk the route-plan for that backend. A `mixed` app runs more than one of these in the same pass.

### 4a — `browser` backend

- Serve the production build on an explicit `127.0.0.1` and a free port.
- **Wait for real readiness before each shot**: `load`, `document.fonts.ready`, every image loaded, and no finite animation still running; never `domcontentloaded` (it fires before hydration, so shots come out blank). Wait on the condition, not a fixed settle, with a timeout that fails loudly:
  ```js
  // page.wait_for_function(SETTLED, timeout=5000) — a timeout marks the route `unsettled` in the log
  () => [...document.images].every(i => i.complete)
     && document.getAnimations().every(a => a.playState !== 'running'
          || a.effect?.getComputedTiming().endTime === Infinity)
  ```
  Infinite animations (spinners, loops) never finish, so the check skips them; a spinner still on screen after the wait is a loading state for the blank-capture guard. The route's `wait_ms` stays for app-specific delays, such as a fetch with no DOM signal.
- **Enter as each role with seeded data** from `demo/seed/`. Prefer the app's own in-page hooks to inject the dataset and bypass un-automatable pickers; otherwise log in through the UI.
- **WebGPU**: headless Chromium has none, so capture a model-loaded state through the Chrome MCP in a real GPU browser.
- **Capture, per route**: retina (`device_scale_factor=2`), fixed viewport (e.g. 1400×900), to `guide/screenshots/<role>/NN-<slug>.png`. **Blank-capture guard**: assert the main content rendered (e.g. `#main` innerHTML length > 50); re-shoot or mark `empty`/`fail`. Log console errors and warnings per route.

### 4b — `cli` backend

The capture is a transcript, not a screenshot:
- Run each route-plan command via Bash exactly as a user would (real flags, real working directory), capturing stdout, stderr, and exit code.
- Write each as `guide/transcripts/<role>/NN-<slug>.txt`, raw with ANSI codes intact; the builder renders it.
- **Blank-capture guard**: the exit code matches the route's declared expectation, and output is non-empty unless the route is declared `no-output` (a silent success). Mismatch → mark `empty`/`fail`.
- **Interactive TUIs** (curses redraws, prompts that need live keystrokes) cannot be a one-shot transcript, and are never faked as plain text. Prefer a detached `tmux` session (`tmux new-session -d`, `send-keys`, then `capture-pane -p -e` per step), which runs unattended. Without `tmux`, drive Terminal.app through the `native-macos` backend, which needs the user's computer-use grant.
- Per-route log: `N/M commands captured ok · X non-zero exits`.

### 4c — `native-macos` backend

Uses the `computer-use` MCP, so it is **not fully unattended**; say so up front:
- **Request access once per app**, not per screen: call `request_access` for the target app before walking its route-plan.
- Walk the route-plan as an action sequence (launch → click/type/wait → screenshot) per feature.
- Screenshot each state to `guide/screenshots/<role>/NN-<slug>.png`, the same path a browser route uses.
- **Blank/fail guard**: no DOM to probe, so use a window-title check plus a pixel-variance check (a one-colour screenshot is a blank, loading or permission-dialog state); re-shoot or mark `empty`/`fail`.
- Never type real credentials or sensitive data into a native app during capture; use the demo seed where the app supports it.
