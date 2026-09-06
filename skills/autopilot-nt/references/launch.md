## Phase 0 — The launch contract (the one interactive moment)

**Refuses cleanly, never invents a plan.** If no report with open `[ ]` items, no `plan/workplan.md` with an open chunk, and no explicit goal in `$ARGUMENTS` exists, stop and say so: "Nothing to execute — no open fix-workplan and no goal given. Run `/forward-pass-nt`, `/ux-review-nt`, or `/maintain-nt` first, point me at `plan/workplan.md`, or give me a goal." Improvising a plan from the codebase is an audit command's job, not this one's — the maker–checker split only holds if finding and fixing stay separate runs.

Before going dark, state the plan back so the user can veto or amend it *before* they walk away. Show:
- **The goal spec** — three lines, not one:
  1. **Done when:** the machine-checkable condition (from `$ARGUMENTS` or the workplan) and where the run stops (batch, goal, or "until the safe work runs out").
  2. **Because:** one line of why the goal matters — pulled from the workplan/handoff or asked for. This is what guides trade-offs when instructions run out; a condition without a why gets satisfied literally and wrongly.
  3. **Never degrade:** 2–3 protected properties the run must not sacrifice while pursuing the goal — existing tests stay green, the sovereignty invariants hold, no new dependencies, bundle size, whatever this repo protects. Derive from the doctrines and the repo; confirm with the user. **The final gate (Phase 4.5) checks these too** — a goal met by degrading a protected property is a red gate, not a shipped run.
- **The stop-line** — the actions it will refuse to do autonomously and will park instead (Phase 4). Name them.
- **Default-decision policy** — for reversible design forks it hits, it will pick the option most consistent with the surrounding code and existing decisions in `history.md`, record the assumption, and move on rather than block.
- **Budget** — the run's hard ceiling: a wall-clock cap and/or item cap (default: the scoped batch, 6 hours — whichever ends first). A loop without a budget is the most expensive bug in unattended work.
- **Where it runs** — the worktree and branch it will create (Phase 0.5), so the user knows their own checkout stays untouched.
- **Checker model** — state the default: fresh-eyes verification on the same family, fresh context. Where the setup allows a **different model family** (an external CLI, another provider), name it as the available upgrade — a different family can't share the maker's blind spots — and use it if the user says so. A stated default to veto, never a question to answer.

Then go — the contract is a **veto window, not a questionnaire**: state it and start; a present user amends or cancels it in the moment, an absent one reads it back in the morning report. This is the only pause-shaped moment — everything after runs to completion. If the user isn't present at all (e.g. this was itself scheduled), skip straight to Phase 0.5 using the safest reading of scope: the top batch only, nothing destructive, default budget.

## Phase 0.5 — Isolate in a worktree

Never run unattended on the user's live checkout. Create an isolated worktree and do all code work there:

```bash
git worktree add .worktrees/autopilot-$(date +%Y-%m-%d) -b autopilot/$(date +%Y-%m-%d)
```

(Ensure `.worktrees/` is gitignored; suffix `-2` if the branch already exists.) A worktree shares the repo's history but has its own checkout — an overnight run can't collide with anything the user does, and the morning review collapses to **one branch diff: merge or discard wholesale.** Two mechanics:
- **`plan/` stays canonical in the main checkout.** It's gitignored, so the worktree won't have it — symlink it in (`ln -s "$MAIN/plan" plan`, where `$MAIN` is the original repo root) so the plan is read from, and every log and report is written to, one place.
- **Rebuild what doesn't travel.** Run the project's install step in the worktree if the build needs it — `node_modules` and friends don't come with a worktree.

All commits from here on land on the `autopilot/<date>` branch. Don't remove the worktree at the end — the human does that after review.
