## 4. Verify plan/ is gitignored

Check that `plan/` (or `/plan/`) appears in the repo's `.gitignore`. If not, add it. The plan/ folder is local-only working notes — its contents must not be pushed to remote.

## 5. Commit, merge to main, push — and sweep stray worktrees

**Commit + push:**
- Run `git status` to see what's outside plan/.
- If there are uncommitted changes outside plan/: stage them (by path, never `git add -A`), commit with a clear one-line message summarizing the day's work, then `git push` to the current branch's upstream.
- If there's nothing to commit, skip the commit but still attempt `git push` in case earlier local commits haven't been pushed.
- If the repo has no remote configured or the push fails, note it in the final handoff message rather than silently swallowing the error.
- Never force-push. Otherwise, push without prompting — including to `main`/`master`. (windup is end-of-session ritual; if the user invoked it, they're authorizing the push.)

**Merge to main (conditional — the closing-state guard gates it):**
- On the default branch already → nothing to merge.
- On a feature branch AND closing clean (work committed, verifier run and green): merge into the default branch, push it, delete the feature branch (local + remote). Small logical chunks land on main at close — that's the convention.
- Closing from `building` (uncommitted work, verifier not run or not green): do **not** merge. Push the feature branch as-is and name it in the handoff ("on branch `x`, unmerged: <why>"). A windup never launders unverified work onto main.

**Stray-worktree sweep:**

> **Rescue `plan/` before you remove anything.** A worktree's `plan/` is gitignored, so it exists in
> that directory and nowhere else — no commit, no remote, no reflog. `git worktree remove` deletes it
> with the rest of the tree, and a run report, its recordings and its action logs go with it. Before
> removing a worktree, copy any `plan/` files it holds that the main checkout does not into the main
> checkout's `plan/`, keeping their names. Only then remove. This has already cost two walkthrough
> reports and 51 screen recordings in one session.

- Run `git worktree list`. For each linked worktree beyond the main checkout (autopilot/agent leftovers):
  - Clean (no uncommitted changes) and its branch fully merged into the default branch → `git worktree remove <path>` and delete the branch.
  - Dirty, or holding unmerged commits → leave it untouched and list it in the handoff with what it's holding. Never delete work to tidy up.
- Finish with `git worktree prune` to clear stale registrations.
