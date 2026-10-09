## Phase 1 — Detect the surface(s)

Classify the app as `browser`, `cli`, `native-macos`, or `mixed` (more than one genuinely exists, such as a CLI with a web dashboard; capture each with its own backend). Record the backend(s). `$ARGUMENTS` can name a surface directly when the repo is `mixed` and the ask is scoped to one of them.

## Phase 2 — Roles, routes and the hero flow

- **Features per role**: entry points first, the screens, flows and commands each role actually uses. This list becomes the capture script's **route-plan**: an ordered set of `(NN, slug, backend, target, wait_ms)` per role, where `target` is a URL for `browser`, a shell command for `cli`, or an action sequence (launch, click, type) for `native-macos`. If the repo has a feature map (`verify/features/`, left by `/walkthrough-nt`), derive the route-plan from it rather than from code, and write any drift you notice back to the map.
- **The hero flow**: the 2–3 captures that show the product doing its job, **entry → key action → result**, from one role (the primary user's), in order. Record them as `HERO_FLOW`, a list of capture ids (`<role>/NN-<slug>`), next to the route-plans. `/package-nt` hands it to its launch-video step (`$SKILL/../package-nt/references/launch-video.md`), so the video shows real screens with seeded data. A landing page describing the product is not a hero step; the working app is. Keep an existing `HERO_FLOW` unless a route it names was removed or renamed.
