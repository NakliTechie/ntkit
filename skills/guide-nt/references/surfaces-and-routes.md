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
