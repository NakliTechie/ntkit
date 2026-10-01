## Phase 0 — The launch contract (the one interactive moment)

State the plan back so the user can veto or amend it before they walk away:
- **The goal spec**, three lines:
  1. **Done when:** the machine-checkable condition (from `$ARGUMENTS` or the workplan) and where the run stops (batch, goal, or "until the safe work runs out").
  2. **Because:** one line of why the goal matters, from the workplan or handoff, or asked for.
  3. **Never degrade:** 2–3 protected properties the run must not sacrifice: existing tests stay green, the sovereignty invariants hold, no new dependencies, bundle size, whatever this repo protects. Derive them from the doctrines and the repo; confirm with the user. The final gate (Phase 4.5) checks these too.
- **The stop-lines** it will park instead of performing (Phase 4). Name them.
- **Default-decision policy** — at a reversible design fork, pick the option most consistent with the surrounding code and the decisions in `history.md`, record the assumption, and move on.
- **Budget** — a wall-clock cap and/or item cap (default: the scoped batch or 6 hours, whichever ends first).
- **Where it runs** — the worktree and branch (Phase 0.5); the user's own checkout stays untouched.
- **Checker model** — default: same family, fresh context. Where the setup allows a different model family (an external CLI, another provider), name it as the available upgrade and use it if the user says so.

## Phase 0.5 — Isolate in a worktree

Fix the run's names once, from today's date, and reuse them to the end even if the run crosses midnight: branch `autopilot/<date>`, worktree `.worktrees/autopilot-<date>`, record `plan/<date>-autopilot.md`. If the branch exists, suffix all three with the first free `-N`, N ≥ 2 (record `plan/<date>-N-autopilot.md`). Write the three names and the main checkout's absolute path (`$MAIN`) as the record's first lines; later phases read them from there, never from `date`.

```bash
git worktree add .worktrees/autopilot-<date> -b autopilot/<date>
```

- Ignore `.worktrees/` (via `.git/info/exclude` if it isn't ignored, so `$MAIN` stays clean for Phase 5).
- Link `plan/` in from the main checkout (`ln -s "$MAIN/plan" plan`) so every log and report lands in one place.
- Rerun the project's install step in the worktree if the build needs it; `node_modules` and friends don't travel.

All commits land on the run's branch. Don't remove the worktree; the human does that after review.
