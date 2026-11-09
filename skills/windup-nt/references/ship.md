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
- **Rescue `plan/` first.** Before removing a worktree, copy any `plan/` files it holds that the main checkout lacks into the main checkout's `plan/`, keeping their names. A symlinked `plan` holds nothing of its own.
- For each linked worktree in `git worktree list`: clean and its branch fully merged into the default branch → `git worktree remove <path>` and delete the branch; dirty or holding unmerged commits → leave it untouched and list it in the handoff with what it holds. Never delete work to tidy up.
- Finish with `git worktree prune`.

**Review-media sweep:**
- Run `sh $SKILL/bin/review-media.sh` from the repo root. It changes nothing. It prints one line per `plan/*-run/` folder that still holds media (the script's one extension list): `done` or `open`, the file count and the size in KB. `open` means an open item (`[ ]` or `[~]`) in `pending.md` or `workplan.md` cites the report, by its name or its date key.
- `done` → delete that folder's media by name, never the folder: `sh $SKILL/bin/review-media.sh --list <dir>` prints each media file; `rm` each printed path. Keep the report, beat logs and JSON. List each in the day summary as `<dir> — <files> files, <MB> MB`.
- `open` → keep; the fixer replays beats from it. Name it in the handoff with the item that holds it.

**Promo-output sweep** (`/package-nt` output is regenerable):
- Run `sh $SKILL/bin/marketing.sh` from the repo root. It changes nothing. It prints `drop` or `keep` per file in `marketing/` and per `brag-output*/` folder, with its size in KB. `keep` means an open item (`[ ]` or `[~]`) names the file or folder, or the folder holds a `.source` marker: a proof video still in progress, kept with no citation until the author posts and deletes it.
- `drop` → delete that entry by name (`rm -rf <path>`), never a glob and never `marketing/` itself. List each in the day summary as `<path> — <MB> MB`.
- `keep` → leave it, and name it in the handoff with the item that holds it.
- Confirm `/marketing` and `/brag-output*` are in `.gitignore` (`git check-ignore -q marketing`); add them if not, and `git rm -r --cached marketing` when files are tracked. A repo's existing card path (`assets/social.png`) is not promo output and stays.

**Stray-branch sweep** (after the worktree sweep, so the branches it freed are counted):
- `git fetch --prune origin` when an `origin` exists, then run `sh $SKILL/bin/branches.sh`. It changes nothing. It prints one line per branch, oldest first: `merged`, `hold`, or `unmerged`, with the tip SHA and the reason. Its verdict already covers squash and rebase merges, unmerged remote commits, plan citations and long-lived names; do not re-derive it.
- `merged` → delete it: `git branch -D <name>` (`-d` refuses a squash-merged branch, and the script has proved the work is in), `git push origin --delete <name>` for an `origin/<name>` line. List each in the day summary as `<ref> @ <sha> — <last commit subject>`; the SHA restores it (`git branch <name> <sha>`, `git push origin <sha>:refs/heads/<name>`).
- `hold` and `unmerged` → never delete; asking is the action. List them in the handoff with the script's reason, and keep one `pending.md/Open questions` item naming them all: "Branches waiting on a call: `<ref>` (<reason>), … — merge, keep, or delete?" `[from: <date>-summary]`. Update that item when an earlier windup left one; never add a second.

**Scratch sweep** (last action of Step 5):
- Run `sh $SKILL/bin/scratch.sh <scratchpad> plan` with the scratchpad path your system prompt names. It changes nothing. It prints `drop` or `keep` per top-level entry, then `older` or `recent` per other session's scratchpad, with its size in KB.
- `drop` → delete that entry by name (`rm -rf <path>`), never a glob and never the scratchpad's parent. A video composition, a capture set or a clone the next session needs is a `keep`: it must be named in an open item, or it goes. List each deletion in the day summary as `<path> — <MB> MB`, then report `df -h /`.
- `keep` → leave it, and name it in the handoff with the item that holds it.
- `older` → other sessions' scratchpads of this project, with neither the scratchpad nor its session transcript written for 7 days: list them in the handoff with their sizes and ask; delete by name only on a yes. Another project's folders are never listed here and never touched.
- `recent` → that session wrote there, or its transcript changed, in the last 7 days, so it may still be running: list it in the handoff; never delete it, even on a yes, until it turns `older`.
- Anything this session wrote outside the scratchpad (a `/tmp` clone, a profile copy, a model download) is not found by the script. Delete each by name from your own footprint notes, or list it in the handoff.
- Stop any dev server, preview or watcher this session started from a scratch directory before deleting it.

**Footprint report** (feeds the handoff; deletes nothing):
- `du -sk .worktrees` for the worktrees kept above.
- Running outside resources this session started: `/demo-nt` hosted mode leaves a Cloudflare tunnel and launchd agents (`launchctl list | grep -i <project>`; `cloudflared tunnel list`). List each by name; stopping them is the user's call.
- If `disktree-cli` is installed, `disktree-cli scan . --limit 20`: when `judge`-tier findings total over 1 GB, point at `/reclaim-nt` in the handoff. Windup never runs `apply`.
- Finish with `df -h /`.
