## Phase 6 — Leave the lever

Before reporting, distill the journeys just walked into a **committed, rerunnable verification harness**: a small CLI (`scripts/verify.*` or the repo's convention) with three entry points.

- **`doctor`**: the freshness preflight. Right build running, port owned by this checkout, seed loaded, hydration settled. It reports what's wrong and what to do; it never fixes silently. Run it again after any failed drive, not only at the start. When the failure is a state `doctor` cannot see (a wedged dialog on a healthy process), reset to the seed or relaunch rather than driving on.
- **`verify <feature>`**: drive one feature area's journeys, named as in the feature map.
- **`verify`**: the full sweep, exit non-zero on failure.

Commit it to the repo, not `plan/`. Give it a real `--help`, error messages that say what to do instead, and one machine-readable summary line per run.

**Own what it starts; keep what it proves.** The harness records the PIDs, ports and profile directories it creates and tears down exactly those on exit, on failure and on `SIGINT`. It never kills by process name or by port alone, because that can take down another checkout's instance or the user's own. Evidence (screenshots, transcripts, response bodies, the summary line) goes to one directory the `--help` names, and teardown never touches it.

**Worktree-safe.** From a worktree, derive the app port and any browser profile paths from the checkout path, so parallel runs never share an instance. Refuse to attach to the main checkout's port from a worktree without an explicit flag.

**Leave the feature map with it.** Write or update `verify/features/README.md` (the index, in sweep order) plus one short file per feature area: *what exists · how a user reaches it · how to drive it with the harness · what usually lies* (flaky waits, gated variants, signals that look like failures but aren't). Keep it behaviour-level. The next walkthrough's Phase 1, `/autopilot-nt` and `/guide-nt` read it. A fix that changes behaviour updates the map in the same commit. When a feature's file lists several ways in (menu, shortcut, deep link, CLI flag), `verify <feature>` drives each one; a run that drives only the convenient entry point covers part of the feature, and says so. A feature the harness cannot reach is reported as `unreachable` with the concrete prerequisite (auth, entitlement, OS, external state) and the route attempted; a prerequisite the map omits is map drift.

- **First walkthrough:** create the smallest script that proves each role's happy path.
- **Later walkthroughs:** run it first, walk what it can't reach, then extend it.
- **Prove the user's path, not a shortcut to it.** Drive the real UI or command, never an internal setter or a test-only endpoint. Assert the side effect (file written, row stored, request sent) as well as what the screen shows. When the safe path is a dry-run or test mode, observe what it skips (files, network, git refs) instead of trusting its name, because some dry-runs still write or call out.
- **Run the harness once, cold, before committing it.** From a fresh shell: `doctor`, `verify <one feature>`, teardown. Then check that the evidence directory still holds the run's proof and that no process or port it started survives. Run teardown after every failed attempt too. A harness that never ran end to end is a draft.
- **Re-verify every RED under Phase 4's driver-suspect rule before committing.** A harness that ships a false RED teaches every later run to ignore it.
- **Wait on a condition, never a fixed sleep**: `document.activeElement`, an element's presence, an app state flag, with a timeout that fails loudly. A tuned sleep can turn a live defect green (`SUBSTANCE.md` §6.7).
- **If `make verify` already means a static gate, add yours beside it** (`make walk`, `make doctor`) and document both as required; never replace it.
- **The repo's own lint applies to the harness.** Fix the harness to satisfy a rule (e.g. a storage-API screen that rejects a `showDirectoryPicker` stub); never exempt it.
- **Pin chaos findings.** Every confirmed Phase 5 finding enters as a regression case under its feature area, named by finding ID: the replayed action prefix, asserting the invariant now holds.
- **Arm the Phase 3 floor set (all six) on every harness run.** Every breach fails the run.
