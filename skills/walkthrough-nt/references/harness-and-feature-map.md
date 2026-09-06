## Phase 4.5 — Leave the lever

A walkthrough that only fixes what it found re-derives everything next time. Before reporting, **distill the journeys just walked into a committed, rerunnable verification harness** — a small CLI (`scripts/verify.*` or the repo's convention) with **three entry points**, not a monolith:

- **`doctor`** — the freshness preflight: right build actually running, port owned by this checkout, seed loaded, hydration settled. Reports what's wrong and what to do about it; never fixes silently.
- **`verify <feature>`** — drive one feature area's journeys, named as in the feature map.
- **`verify`** — the full sweep, exit non-zero on failure.

Agent-friendly throughout: error messages that say what to do instead, a real `--help`, one machine-readable summary line per run. The full `verify` is what the `/release-nt` and `/autopilot-nt` gates run — that contract is unchanged; `doctor` and `verify <feature>` are what a mid-task agent reaches for without paying for the whole sweep. Committed to the repo, not `plan/` — the point is that anyone (or any later run) can rerun the evidence.

**Worktree-safe by construction.** The harness must run correctly from an isolated worktree: `test -f .git` distinguishes a worktree (`.git` is a file) from the main checkout (a directory). From a worktree, derive the app port and any browser profile / user-data paths from the checkout path, so parallel runs — an `/autopilot-nt` branch, a second walkthrough — never fight the main workspace's instance or each other. Refuse to attach to the main workspace's port from a worktree unless an explicit flag says that's intended. This is the browser-harness face of the actor rule: one run per worktree, no shared state.

**Leave the map with the lever.** Alongside the harness, write (or update) a committed **feature map** — `verify/features/README.md` (the index, in top-to-bottom sweep order) plus one short file per feature area answering four questions: *what exists · how a user reaches it · how to drive it with the harness · what usually lies* (flaky waits, gated variants, signals that look like failures but aren't). Behavior-level, short enough to act on without reading source. This is what the next walkthrough's Phase 1 reads instead of re-deriving the app, what `/autopilot-nt` reads to verify the one feature it just touched, and what `/guide-nt`'s route-plans derive from — the same shared-asset pattern as `demo/seed/`. A fix that changes behavior updates the map in the same commit.

- **First walkthrough:** create it from the journeys walked — the smallest script that proves each role's happy path.
- **Later walkthroughs:** run it first (regressions surface for free), then walk what it can't reach, then extend it with anything new.
- **What it can't drive** (payment, email, native dialogs) stays in the report's blind-spot list — the harness covers what's automatable, never pretends to more.

This harness **is the project's verifier** from now on: `/release-nt`'s gate runs it, `/autopilot-nt`'s final gate runs it. A repo with one no longer passes the release guard vacuously — the lever is the definition of green.
