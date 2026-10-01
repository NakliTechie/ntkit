## Phase 4.5 — The final gate

Per-item checks don't prove the fixes coexist. Run the **whole-project deterministic gate once**: the full test suite, typecheck, build and linter, the committed verification harness if `/walkthrough-nt` left one, **plus an explicit check for each never-degrade property** from the goal spec. A degraded property is a red gate even with every test green. Green → the run is **landed**; go to Phase 5. Red → the run is **not landed**, whatever the per-item log says: bisect if cheap (revert the suspect commits on the branch until green, park what you reverted), otherwise skip Phase 5 and report the branch red with the failure output first.

## Phase 5 — Ship it (green gate only)

Only on a green gate, merge the run to the default branch (`main` or `master`) and push, from the main checkout. Take `$MAIN` and the branch from the record's first lines (Phase 0.5), never from `date`:

```bash
git -C "$MAIN" merge --no-ff "autopilot/<date>" -m "autopilot <date>: <N> items — gate green"
git -C "$MAIN" push origin HEAD
```

Each of these **cancels the ship** and leaves the branch for review (report it in Phase 6):
- **Red or skipped gate.**
- **`$MAIN` is dirty or not on the default branch** — merging on top of the user's work isn't yours to do.
- **Any conflict, or anything beyond a clean `--no-ff` merge** — main moved under you; never resolve conflicts unattended.
- **Push rejected** — the merge stays local; say the push is owed.
