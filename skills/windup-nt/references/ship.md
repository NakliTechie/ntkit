## 4. Verify plan/ is gitignored

Check per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives) (`git check-ignore -q plan`; add `/plan`, no trailing slash). Nothing under `plan/` is ever pushed.

## 5. Commit, merge to main, push — and sweep stray worktrees and branches

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

**Review-media sweep** (a review's recordings and screenshots are working evidence; the report is the record):
- Run `sh $SKILL/bin/review-media.sh` from the repo root. It changes nothing. It prints one line per `plan/*-run/` folder that still holds media (`*.webm`, `*.mp4`, `*.mov`, `*.cast`, `*.png`, `*.jpg`, `*.jpeg`, `*.gif`): `done` or `open`, the file count and the size in KB. `open` means an open item (`[ ]` or `[~]`) in `pending.md` or `workplan.md` cites the report, by its name or its date key.
- `done` → delete that folder's media by name, never the folder: `find <dir> -type f \( -name '*.webm' -o … \) -delete` with the same extension list. Keep the report, beat logs and JSON. List each in the day summary as `<dir> — <files> files, <MB> MB`.
- `open` → keep; the fixer replays beats from it. Name it in the handoff with the item that holds it.

**Stray-branch sweep** (after the worktree sweep, so the branches it freed are counted):
- `git fetch --prune origin` when an `origin` exists, then run `sh $SKILL/bin/branches.sh`. It changes nothing. It prints one line per branch, oldest first: `merged`, `hold`, or `unmerged`, with the tip SHA and the reason. It has already examined each one: is its work in the default branch (an ancestor, or a squash or rebase merge that changes no file), does its remote or a same-name local branch hold unmerged commits, does `pending.md` or `workplan.md` name it, is it a long-lived name (`develop`, `release/*`, `gh-pages` …). It leaves out the default branch, the current branch, worktree branches, and branches with no shared history.
- `merged` → delete it: `git branch -D <name>` (`-d` refuses a squash-merged branch, and the script has proved the work is in), `git push origin --delete <name>` for an `origin/<name>` line. List each in the day summary as `<ref> @ <sha> — <last commit subject>`; the SHA restores it (`git branch <name> <sha>`, `git push origin <sha>:refs/heads/<name>`).
- `hold` and `unmerged` → never delete; asking is the action. List them in the handoff with the script's reason, and keep one `pending.md/Open questions` item naming them all: "Branches waiting on a call: `<ref>` (<reason>), … — merge, keep, or delete?" `[from: <date>-summary]`. Update that item when an earlier windup left one; never add a second.
