## Phase 4.5 — The final gate

Per-item checks prove each fix in isolation; they don't prove the fixes coexist — an early item can break a later one's assumptions while every individual check stays green. So before shipping, run the **whole-project deterministic gate once**: the full test suite, the typecheck, the build, the linter — and the committed verification harness if `/walkthrough-nt` has left one (the lever outranks ad-hoc checks) — whatever the project has — **plus the never-degrade list from the goal spec**: each protected property gets an explicit check here, and a degraded one is a red gate even with every test green. Green → the run is **landed**, proceed to Phase 5 to ship it. Red → the run is **not landed**, whatever the per-item log says: bisect if cheap (revert the most recent suspect commits on the branch until green, park what you reverted), otherwise **skip Phase 5** and report the branch red with the failure output front and center. "Done" is the gate's word, never the agent's — and only a green gate ships.

## Phase 5 — Ship it (green gate only)

**Only if Phase 4.5 came back GREEN**, merge the run to the project's default branch (`main`, or `master`) and push it. This is the one outward action autopilot is authorized to take, gated three ways — green gate, clean main, clean merge:

```bash
# from the main checkout ($MAIN); requires it to be on the default branch and clean
git -C "$MAIN" merge --no-ff "autopilot/$(date +%Y-%m-%d)" -m "autopilot <date>: <N> items — gate green"
git -C "$MAIN" push origin HEAD
```

Each of these **cancels the ship** and falls back to leaving the branch for review (report it in Phase 6 — the branch is the safety net):
- **Red or skipped gate** — never merge unverified work.
- **Main isn't clean, or isn't on the default branch** — the user has uncommitted work or a different branch checked out in `$MAIN`; merging on top of that isn't yours to do.
- **Non-fast-forward beyond a clean `--no-ff` merge / any conflict** — main moved under you. Don't resolve conflicts unattended; leave the branch and flag it.
- **Push rejected** — remote moved or auth failed non-interactively; the merge stays local and the push is *owed* — say so.

Never `--force`, never touch a branch-protection rule, never open or merge a PR on the user's behalf. **Leave the worktree in place regardless** — the human removes it after a glance. On a clean ship, the branch is merged into the default branch and the remote is updated.
