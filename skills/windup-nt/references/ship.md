## 4. Verify plan/ is gitignored

Check per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives) (`git check-ignore -q plan`; add `/plan`, no trailing slash). Nothing under `plan/` is ever pushed.

## 5. Commit, merge to main, push — and sweep stray worktrees

**Commit + push:**
- Stage changes outside `plan/` by path, never `git add -A`; commit with a one-line message summarizing the day's work; `git push` to the current branch's upstream.
- Nothing to commit → still `git push`, in case earlier local commits are unpushed.
- No remote, or the push fails → say so in the handoff; never swallow the error.
- Never force-push. Otherwise push without prompting, including to `main`/`master`.

**Merge to main (the closing-state guard gates it):**
- On the default branch already → nothing to merge.
- On a feature branch and closing clean (work committed, verifier run and green) → merge into the default branch, push it, delete the feature branch (local + remote).
- Closing from `building` → do **not** merge. Push the feature branch as-is and name it in the handoff ("on branch `x`, unmerged: <why>"). A windup never puts unverified work on main.

**Stray-worktree sweep:**
- **Rescue `plan/` first.** Before removing a worktree, copy any `plan/` files it holds that the main checkout lacks into the main checkout's `plan/`, keeping their names. A real-folder `plan/` in a worktree exists nowhere else and dies with it (this once cost two walkthrough reports and 51 screen recordings); a symlinked `plan` holds nothing of its own.
- For each linked worktree in `git worktree list`: clean and its branch fully merged into the default branch → `git worktree remove <path>` and delete the branch; dirty or holding unmerged commits → leave it untouched and list it in the handoff with what it holds. Never delete work to tidy up.
- Finish with `git worktree prune`.
