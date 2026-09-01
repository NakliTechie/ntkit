---
description: Generate a searchable single-file HTML guide — walk each role's features across whatever surfaces the app has (browser, CLI, native macOS) capturing screenshots or terminal transcripts. Regenerates from a committed generator; never hand-edits output.
argument-hint: "[role/feature to focus | 'update' to refresh an existing guide]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "mcp__computer-use__*"]
entry: "at least one surface is runnable (dev server, CLI binary, or built .app); guide generator committed (or created this run)"
exit: "single-file HTML guide regenerated from the generator — never hand-edited"
writes: "guide generator + output"
---

Build a **searchable HTML guide** for the app: identify each user role, drive the running app through their features **capturing screenshots or terminal transcripts**, and assemble a single-file `guide/index.html` — role sections × feature subsections × captioned captures, with **inline search**. This is the documentation sibling of `/walkthrough-nt`: same role-driven spine, but it *captures and documents* the app instead of *finding and fixing* bugs.

**The guide is a build artifact.** Its source of truth is a small committed **generator** — a capture script (route-plans per role, tagged with a capture backend) + a builder (captions/sections → HTML). The prose lives in the generator's data, so you **edit the generator and regenerate**; you never hand-edit `index.html`. (See Phase 3 for the edit-vs-regenerate rule.)

If the current directory isn't a git repo, ask which project — don't guess. If no surface (Phase 1) can be detected at all — no dev server, no CLI entry point, no app bundle — say so; there's nothing to capture.

`$ARGUMENTS` (optional): a role (`admin`) or feature (`checkout`) to scope the capture to, or `update` to refresh an existing guide. If empty, cover every role and their primary features.

## Phase 1 — Detect the surface(s)

A guide's capture mechanics depend entirely on how the app is actually used. Classify before doing anything else:

- **`browser`** — web framework + dev server (the original, still the default case). Capture = Playwright/Chrome MCP screenshots.
- **`cli`** — `package.json` `bin`, a Cargo `[[bin]]`, `console_scripts`, or an argparse/clap entry point, with no web server. Capture = terminal transcripts (Phase 4b).
- **`native-macos`** — `.xcodeproj`, `.swiftpm`/`Package.swift` with an app target, or an `Info.plist`/`.app` bundle. Capture = `computer-use` MCP screenshots (Phase 4c).
- **`mixed`** — more than one of the above genuinely exists (e.g. a CLI tool with a companion web dashboard). Capture each surface with its own backend; the guide gets one section per surface, roles/features nested inside.

Record the detected backend(s) — they drive Phase 3's route-plan shape and Phase 4's capture path. `$ARGUMENTS` can also name a surface directly when a repo is genuinely `mixed` and the ask is scoped to one of them.

## Phase 2 — Identify roles + the feature map

Derive the cast and the screens, the same way `/walkthrough-nt` does, per detected surface:

- **Roles** — from RBAC enums, route guards, role-forked UI, CLI subcommand permissions, seed personas, docs. Always include the **anonymous visitor** and the **brand-new zero-data user** (first-run) — a guide that only shows a full-of-data app misleads new users. A single-user CLI or native app may have one "role"; don't force role sections that don't exist.
- **Features per role** — entry-points-first, the screens/flows/commands each role actually uses. This list **becomes the capture script's route-plan**: an ordered set of `(NN, slug, backend, target, wait_ms)` per role, exactly like Bahi's `PHARMA_ROUTES` / `CONSULTING_ROUTES` — `target` is a URL for `browser`, a shell command for `cli`, or an action sequence (launch/click/type) for `native-macos`. If the repo has a feature map (`verify/features/`, left by `/walkthrough-nt`), derive the route-plan from it rather than from code — and write any drift you notice back to the map, not just the route-plan.

Roles are the guide's top-level sections; features are the subsections. `$ARGUMENTS` narrows the map to one role or feature.

## Phase 3 — Detect or scaffold the generator (the edit-vs-regenerate decision)

Look for an existing generator — a `guide/` or `demo/` folder with a capture script + builder (Bahi uses `demo/{capture.py,build_index.py,regenerate.sh}`).

- **It exists → you are UPDATING.** Read it. Add/adjust route-plan rows (each tagged with its `backend`) and **caption data** for new or changed features; **preserve every existing hand-written caption and section intro**. Then regenerate (Phase 5) — full, or *scoped* to the changed role/feature. **Do not patch `index.html` by hand** — it's regenerated output; edits there are lost on the next run.
- **None exists → SCAFFOLD one**, modelled on the Bahi pattern, generalized to whatever Phase 1 detected:
  - `guide/capture.*` — route-plans per role, each row carrying a `backend` (Phase 4).
  - `guide/build_index.py` — `CAPTIONS` (slug → title + one-line description) and `SECTIONS` (title, intro, item-slugs) as **data**, assembled into `guide/index.html` (Phase 5).
  - `guide/regenerate.sh` — ensure each needed surface is up (dev server / built binary / built .app) → capture → build (Bahi's orchestration; idempotent server start).

**The rule:** the output HTML is generated; the source of truth is the generator's *data* (route-plans + captions + sections). Updating = edit data → regenerate. This is why regenerate beats hand-editing — a full rebuild re-shoots captures and re-assembles HTML but **never loses prose**, because the prose isn't in the HTML.

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

## Phase 5 — Build the single-file guide

The builder reads the captures + caption data and emits one self-contained `guide/index.html`:
- **Structure** — header/intro · a **TOC** · one section per surface (only if `mixed`) · one **role section** per role · **feature subsections** inside each, every feature = `capture + caption (title + one-line "what this is")`. (Single-role app? Drop the role wrapper and organize straight by feature.)
- **Card type follows the capture, not the backend** — a route that produced a PNG (`browser`, `native-macos`) renders as an **image card** with the lightbox (below); a route that produced a transcript (`cli`) renders as a **terminal card**: `<pre>` with ANSI SGR codes converted to inline spans (a small vanilla-JS parser, no dependency), styled as a terminal window (traffic-light dots, monospace, dark theme by default — since there are no CSS tokens to read from a CLI). A `mixed` guide has both card types side by side without incident, since the builder branches per capture.
- **Theme from the app's own design tokens, where they exist** — for a `browser` (or web-dashboard half of a `mixed` app) surface, read the app's `:root` CSS custom properties and font stack, and build the guide's chrome from *those*, so it reads as part of the product, not a generic gallery. This is the biggest visual-quality lever for surfaces that have tokens to steal; a pure-CLI guide has none, so its chrome is the terminal theme instead.
- **Relative asset paths** — reference `screenshots/<role>/…` / `transcripts/<role>/…` and, for a `browser` surface, link back into the app via a `../`-style base, so the guide works opened as a file or served from any host.
- **Captions are authored content** — keep them in the builder's `CAPTIONS`/`SECTIONS` data so regeneration never loses them. Write a real one-line explanation per screen or command, not the slug.
- **Inline search (the addition over Bahi).** A sticky search box that filters live:
  - Give each card a `data-search` attribute = lowercased `role + feature title + caption + slug` — for a terminal card, also fold in the command text itself, so a reader can search by command name.
  - On input: lowercase the query, toggle a `.hidden` class per card by `data-search.includes(query)`, hide sections left empty, show a "no matches" note when nothing matches.
  - `/` focuses the box, `Esc` clears it. Pure vanilla JS, no dependencies, inlined in the page.
- **Lightbox viewer — image cards only.** Every screenshot opens full-size in an in-page lightbox — a dimmed overlay showing the image at max size with its caption below; never a bare `<a href="img">` that navigates away. Terminal cards skip the lightbox entirely — the `<pre>` is already legible at card width, so "opening" one is just letting it expand to full width in place. Vanilla JS, inlined, no dependencies:
  - **Open/close** — click/tap a screenshot opens it; `Esc`, a visible `×` button, and a click/tap on the backdrop all close it. Closing restores scroll position.
  - **Navigation** — `←`/`→` step to the previous/next screenshot in guide order (skipping search-hidden and non-image cards); `↑`/`↓` jump to the first screenshot of the previous/next feature section. On-screen prev/next arrows mirror the keys, with a `role · feature — N/M` position line.
  - **Mobile** — swipe left/right = prev/next, swipe down (or tap backdrop) = close, native pinch-zoom on the image not blocked, on-screen controls ≥44px, image letterboxed to fit the viewport (`max-width/max-height: 100%`, `object-fit: contain`).
- **Responsive layout.** The guide itself must read well on a phone: `<meta name="viewport">`, cards/screenshots at `max-width: 100%`, terminal cards horizontally scrollable rather than overflowing, the sticky search usable at small widths, TOC collapsing to a simple list.

Keep CSS inlined; the guide must be a single portable file plus its `screenshots/`/`transcripts/` folders.

## Phase 6 — Verify + report

Don't ship a guide you haven't looked at:
- **Serve `guide/` and open it.** Confirm image captures load (not blank) and terminal captures render with ANSI colors intact (not raw escape codes), the **inline search** filters correctly (type a feature or command name → only matching cards remain; `Esc` restores), and TOC anchors jump.
- **Exercise the lightbox on image cards** — open a screenshot, arrow through prev/next (`←`/`→`) and section jumps (`↑`/`↓`), confirm the position line updates and `Esc`/backdrop close it, and that navigation skips terminal cards and search-hidden cards.
- **Check it on a phone viewport** — mobile emulation (~375px): guide readable, search usable, lightbox opens on image cards, swipe left/right navigates, swipe down closes, pinch-zoom works on images, terminal cards scroll horizontally without breaking layout.
- **Print:** roles × features covered per surface, total screenshots + transcripts, any `empty`/`fail`/console-error/non-zero-exit routes (the blind spots), and the path to the guide.
- **Shipping:** unlike `plan/`, the guide is meant to be committed. Screenshots can be large — respect `.gitignore`/`.assetsignore` and let the user decide whether to commit images or host them. Don't push; `/windup-nt` ships it.

End by naming where the guide is, which surfaces it covers, what was (re)captured, any broken screens/commands worth a `/walkthrough-nt`, and — for an update — that you edited the generator + regenerated, not the HTML.
