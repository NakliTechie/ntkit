---
description: Generate a searchable HTML guide — identify each role, walk the running app through their features in a real browser capturing screenshots, and build a single-file guide (role + feature sections, captions, inline search). Regenerates from a committed generator; never hand-edits the output.
argument-hint: "[role/feature to focus | 'update' to refresh an existing guide]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "app boots; guide generator committed (or created this run)"
exit: "single-file HTML guide regenerated from the generator — never hand-edited"
writes: "guide generator + output"
---

Build a **searchable HTML guide** for the app: identify each user role, drive the running app through their features **in a real browser capturing screenshots**, and assemble a single-file `guide/index.html` — role sections × feature subsections × captioned screenshots, with **inline search**. This is the documentation sibling of `/walkthrough-nt`: same role-driven browser spine, but it *captures and documents* the app instead of *finding and fixing* bugs.

**The guide is a build artifact.** Its source of truth is a small committed **generator** — a capture script (route-plans per role) + a builder (captions/sections → HTML). The prose lives in the generator's data, so you **edit the generator and regenerate**; you never hand-edit `index.html`. (See Phase 2 for the edit-vs-regenerate rule.)

If the project has no browser surface (pure CLI, library, backend-only), say so — there's nothing to screenshot. If the current directory isn't a git repo, ask which project — don't guess.

`$ARGUMENTS` (optional): a role (`admin`) or feature (`checkout`) to scope the capture to, or `update` to refresh an existing guide. If empty, cover every role and their primary features.

## Phase 1 — Identify roles + the feature map

Derive the cast and the screens, the same way `/walkthrough-nt` does:
- **Roles** — from RBAC enums, route guards, role-forked UI, seed personas, docs. Always include the **anonymous visitor** and the **brand-new zero-data user** (first-run) — a guide that only shows a full-of-data app misleads new users.
- **Features per role** — entry-points-first, the screens/flows each role actually uses. This list **becomes the capture script's route-plan**: an ordered set of `(NN, slug, route, wait_ms)` per role, exactly like Bahi's `PHARMA_ROUTES` / `CONSULTING_ROUTES`.

Roles are the guide's top-level sections; features are the subsections. `$ARGUMENTS` narrows the map to one role or feature.

## Phase 2 — Detect or scaffold the generator  (the edit-vs-regenerate decision)

Look for an existing generator — a `guide/` or `demo/` folder with a capture script + builder (Bahi uses `demo/{capture.py,build_index.py,regenerate.sh}`).

- **It exists → you are UPDATING.** Read it. Add/adjust route-plan rows and **caption data** for new or changed features; **preserve every existing hand-written caption and section intro**. Then regenerate (Phase 5) — full, or *scoped* to the changed role/feature. **Do not patch `index.html` by hand** — it's regenerated output; edits there are lost on the next run.
- **None exists → SCAFFOLD one**, modelled on the Bahi pattern:
  - `guide/capture.py` — Playwright route-plans per role (Phase 4).
  - `guide/build_index.py` — `CAPTIONS` (slug → title + one-line description) and `SECTIONS` (title, intro, item-slugs) as **data**, assembled into `guide/index.html` (Phase 5).
  - `guide/regenerate.sh` — ensure dev server → capture → build (Bahi's orchestration; idempotent server start).

**The rule:** the output HTML is generated; the source of truth is the generator's *data* (route-plans + captions + sections). Updating = edit data → regenerate. This is why regenerate beats hand-editing — a full rebuild re-shoots screenshots and re-assembles HTML but **never loses prose**, because the prose isn't in the HTML.

## Phase 3 — Boot the app, the browser, and a session per role

Same runtime discipline as `/walkthrough-nt`:
- **Serve a production build, not dev mode** — faster, pre-compiled, and the bundle users actually run. (Bahi serves the static app with `python3 -m http.server`; a framework app needs `build` + `start`.) Use explicit `127.0.0.1` + a known-free port.
- **Wait for real readiness before each shot** — `load` + `document.fonts.ready` + a short settle; never `domcontentloaded` (it fires before hydration → blank screenshots).
- **Enter as each role with seeded data.** Prefer the app's own in-page hooks to inject a seeded dataset and **bypass un-automatable pickers** (Bahi's `capture.py` calls `readKhata`/`openDbFromBytes` and stubs the FS-Access picker). Otherwise log in through the UI. Seed enough that screens aren't empty — except the deliberate first-run shots. Draw from the **shared demo seed** (`demo/seed/`, shared with `/demo-nt` and `/walkthrough-nt`) so the three don't drift.
- **WebGPU can't be tested headless** — which is *why* we stage the DOM instead of running the model (headless Chromium has **no WebGPU**, so in-browser model inference just errors). Staged screenshots look right but aren't the live model output. To capture a genuinely model-loaded state, drive a real GPU browser via the **Chrome MCP** rather than headless Playwright.
- **Capture console errors/warnings per route** — they go in the capture log and flag screens that are secretly broken.

## Phase 4 — Capture, walking each role's route-plan

In the capture script, for each role: load that role's seeded dataset, then walk its route-plan — nav to each feature route, wait, screenshot:
- **Retina** (`device_scale_factor=2`), fixed viewport (e.g. 1400×900), to `guide/screenshots/<role>/NN-<slug>.png`.
- **Blank-capture guard** — after each nav, assert the main content actually rendered (Bahi checks `#main` innerHTML length > 50; a blank page is also a tell-tale ~8 KB JPEG). Re-shoot or mark `empty`/`fail`.
- **Per-route log** — write a `CAPTURE-LOG.md`: `N/M routes rendered ok · X console errors`, with the failures named. This is the coverage artifact.
- **Scoped re-capture on update** — when `$ARGUMENTS`/`update`, only re-shoot the changed/added routes; leave the rest.

A route that renders blank or throws console errors is both a bad screenshot **and** a likely bug — note it, and hand it to `/walkthrough-nt` rather than papering over it.

## Phase 5 — Build the single-file guide

The builder reads the screenshots + caption data and emits one self-contained `guide/index.html`:
- **Structure** — header/intro · a **TOC** · one **role section** per role · **feature subsections** inside each, every feature = `screenshot + caption (title + one-line "what this screen is")`. Keyboard shortcuts / notes where useful. (Single-role app? Drop the role wrapper and organize straight by feature.)
- **Theme from the app's own design tokens** — read the app's `:root` CSS custom properties (colors, radii, shadows) and font stack, and build the guide's chrome from *those*, so it reads as part of the product, not a generic gallery. (Bahi's builder pulls the app's color vars for exactly this.) This is the biggest visual-quality lever — don't hand-pick a palette when the app already defines one.
- **Relative asset paths** — reference `screenshots/<role>/…` and link back into the app via a `../`-style base, so the guide works opened as a file or served from any host (Bahi's `BAHI_BASE="../"`).
- **Captions are authored content** — keep them in the builder's `CAPTIONS`/`SECTIONS` data so regeneration never loses them. Write a real one-line explanation per screen, not the slug.
- **Inline search (the addition over Bahi).** A sticky search box that filters live:
  - Give each card a `data-search` attribute = lowercased `role + feature title + caption + slug`.
  - On input: lowercase the query, toggle a `.hidden` class per card by `data-search.includes(query)`, hide sections left empty, show a "no matches" note when nothing matches.
  - `/` focuses the box, `Esc` clears it. Pure vanilla JS, no dependencies, inlined in the page.

Keep CSS inlined; the guide must be a single portable file plus its `screenshots/` folder.

## Phase 6 — Verify + report

Don't ship a guide you haven't looked at:
- **Serve `guide/` and open it.** Confirm screenshots load (not blank), the **inline search** filters correctly (type a feature name → only matching cards remain; `Esc` restores), and TOC anchors jump.
- **Print:** roles × features covered, total screenshots, any `empty`/`fail`/console-error routes (the blind spots), and the path to the guide.
- **Shipping:** unlike `plan/`, the guide is meant to be committed. Screenshots can be large — respect `.gitignore`/`.assetsignore` and let the user decide whether to commit images or host them. Don't push; `/windup-nt` ships it.

End by naming where the guide is, what was (re)captured, any broken screens worth a `/walkthrough-nt`, and — for an update — that you edited the generator + regenerated, not the HTML.
