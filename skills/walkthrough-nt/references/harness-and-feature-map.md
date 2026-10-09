## Phase 6 — Leave the lever

Before reporting, distill the journeys just walked into a **committed, rerunnable verification harness**: a small CLI (`scripts/verify.*` or the repo's convention) with three entry points.

- **`doctor`**: the freshness preflight. Right build running, port owned by this checkout, seed loaded, hydration settled. It reports what's wrong and what to do; it never fixes silently.
- **`verify <feature>`**: drive one feature area's journeys, named as in the feature map.
- **`verify`**: the full sweep, exit non-zero on failure.

Commit it to the repo, not `plan/`. Give it a real `--help`, error messages that say what to do instead, and one machine-readable summary line per run.

**Worktree-safe.** From a worktree, derive the app port and any browser profile paths from the checkout path, so parallel runs never share an instance. Refuse to attach to the main checkout's port from a worktree without an explicit flag.

**Leave the feature map with it.** Write or update `verify/features/README.md` (the index, in sweep order) plus one short file per feature area: *what exists · how a user reaches it · how to drive it with the harness · what usually lies* (flaky waits, gated variants, signals that look like failures but aren't). Keep it behaviour-level. The next walkthrough's Phase 1, `/autopilot-nt` and `/guide-nt` read it. A fix that changes behaviour updates the map in the same commit.

- **First walkthrough:** create the smallest script that proves each role's happy path.
- **Later walkthroughs:** run it first, walk what it can't reach, then extend it.
- **Re-verify every RED under Phase 4's driver-suspect rule before committing.** A harness that ships a false RED teaches every later run to ignore it.
- **Wait on a condition, never a fixed sleep**: `document.activeElement`, an element's presence, an app state flag, with a timeout that fails loudly. A tuned sleep can turn a live defect green (`SUBSTANCE.md` §6.7).
- **If `make verify` already means a static gate, add yours beside it** (`make walk`, `make doctor`) and document both as required; never replace it.
- **The repo's own lint applies to the harness.** Fix the harness to satisfy a rule (e.g. a storage-API screen that rejects a `showDirectoryPicker` stub); never exempt it.
- **Pin chaos findings.** Every confirmed Phase 5 finding enters as a regression case under its feature area, named by finding ID: the replayed action prefix, asserting the invariant now holds.
- **Arm the Phase 3 floor set (all seven) on every harness run.** An `INV-SILENT` breach is logged as a lead, not a failure; the other six fail the run.
