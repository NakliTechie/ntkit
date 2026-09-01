---
description: End-of-day windup — implicit /replan-nt first when plan/ has accumulated, then day summary in plan/, update plan/pending.md, ensure plan/ is gitignored, commit/push non-plan changes, print resume handoff
entry: "any state — warns when closing from building (uncommitted work / verifier not green) and records that state in the handoff"
exit: "summary + pending + workplan updated (consolidated first if plan/ had accumulated), non-plan work pushed, clean closes merged to main, stray worktrees swept, resume handoff printed"
writes: "plan/<date>-summary.md, plan/pending.md, plan/workplan.md; via the implicit replan: plan/history.md, plan/_archive/"
---

Wind up the current project for today. Execute these steps in order (0–6), working in the current project's repo root.

If the current directory is not inside a git repo, stop and ask the user which project to wind up — do not guess.

**Closing-state guard.** Windup persists whatever state the repo is in (per ntkit's `STATES.md` — kit doctrine, not a file in this project) — it never blocks — but it must be honest about which state that is. If closing from `building` (uncommitted work, a half-done chunk, a verifier not run or not green), say so out loud before writing anything — "Closing from `building`, not `verifying`: <what's unfinished>" — and record that state and the unfinished item explicitly in both the day summary and the resume handoff, so tomorrow's `/resume-nt` reopens on the truth, not on an implied clean close. A windup that papers over a mid-chunk state is the one bug this command can have.

## 0. Implicit replan (conditional — fires on evidence, not ceremony)

Before writing anything, count what `plan/` has accumulated from **before today**: dated summaries, autopilot reports, any dated audit report (`plan/<type>-YYYY-MM-DD.md` — forward-pass, walkthrough, ux-review, maintenance, live-check, …), unnamed scratch, and a `soc.md` carrying pre-today entries. **3 or more such foldable files → run the full `/replan-nt` consolidation first** — classify, fold into the three canonical files, replay-check, archive — then proceed below on the freshly consolidated base. Fewer → skip silently; a light project's windup looks exactly as it always did (the STATES.md scaling rule: an artifact that doesn't exist can't trigger a step).

Announce, don't ask: "plan/ has accumulated N files — replanning first." Two mechanics matter:
- **Order.** The fold runs *before* Step 1, so today's summary is written after it and survives un-archived for `/resume-nt` to read tomorrow.
- **The replay check's verdict travels.** Carry `Replay: clean` — or the orphan/ghost list — into the final handoff (Step 6), so drift caught during the fold is seen at close, not buried in an archived file.

This makes consolidation ambient: `/replan-nt` stays invocable on its own, but nobody has to *remember* it — a windup on an accumulated plan/ folds as it closes.

## 1. Day summary

Write `plan/$(date +%Y-%m-%d)-summary.md` with what happened today. Gather context from:
- This session's conversation
- `git log --since=midnight --oneline --all` for commits made today
- `git status` and `git diff` for any uncommitted work
- `plan/soc.md` — today's stream-of-consciousness entries (from `/soc-nt`): fold the load-bearing ones into the summary's sections, but leave the file in place — `/replan-nt` owns its triage and archival

Cover, in this order:
- **Shipped** — what landed (PRs, commits, deploys), each with its commit SHA
- **Verified** — how it was checked (tests / typecheck / build / manual) and what verification is still owed (e.g. "needs runtime test")
- **Decisions** — what was chosen and why (especially anything non-obvious)
- **Tried then rolled back** — dead ends worth remembering so we don't repeat them
- **Open questions** — anything that surfaced today but isn't resolved
- **Deferred / parked** — anything raised today but consciously *not* done now (skipped, "later", out of current scope, not abandoned) → seeds `## Parked` in pending.md, so a "not now" said out loud doesn't evaporate

Keep it tight — bullet points, not prose. The future-self reading this wants signal, not a transcript.

## 2. Pending items

Write or update `plan/pending.md`. The canonical structure (shared with /replan-nt) is:

```
# Pending

## Now
- <actionable, top priority>

## Parked
- <deferred, not in scope right now but not abandoned>

## Open questions
- <question that needs answering before it can become a task>
```

Merge rules:
- **File exists with sections:** preserve them. New items surfaced today go into `Now` by default, `Open questions` if phrased as a question, or **`Parked` if it was deferred this session** — raised but chosen against for now (skipped, "later", out of current scope, not abandoned). Remove items finished today from wherever they sit. Actively move a "not now" into `Parked` rather than dropping it; leave already-parked items alone unless they came back into scope today.
- **File exists, flat (no sections):** keep it flat — don't restructure mid-windup. Just add new items and remove finished ones. (User can run `/replan-nt` when ready to migrate to the structured form.)
- **File doesn't exist:** create it with the three sections (canonical from day one).

Order items by priority within each section. Each item is one line — link to a deeper plan/ doc if there's more context. `pending.md` is the source of truth for what's open; execution order is the workplan's job (next step).

## 3. Workplan

Write or update `plan/workplan.md`. The workplan reorganizes `plan/pending.md` into chunks the next session can pick up and execute without re-thinking the strategy. Each chunk groups items that are:
- **Logical** — same area, feature, module, or file
- **Convenient** — small items and quick wins batched so they ship in one sitting
- **Related** — natural dependencies or sequencing flow

For each chunk include:
- A short title (what binds the items together); mark a **keystone** chunk others depend on
- 2–5 items pulled from `pending.md`, each a **tri-state checkbox**: `[ ]` open · `[x]` done · `[~]` partial
- A rough size estimate (e.g., "30 min", "half day", "1–2 hours") — keep it loose
- Optional: a note on prerequisites or sequencing

Item conventions:
- A `[~]` partial / deferred item states what's done, what's left, and what would un-defer it — point at `/decide-nt` when the blocker is a decision.
- If a chunk came from a `/forward-pass-nt`, `/walkthrough-nt`, `/ux-review-nt`, or `/maintain-nt`, carry the finding IDs (`C1`, `H2`, …) and a `[test]` marker on any item whose verification is still owed.

Items that don't yet cluster into a chunk go under a `## Unbatched` section — that flags they need more thought before they're actionable.

Order chunks so the next session can pick the top one and start. `pending.md` is the flat source of truth; `workplan.md` is the curated play.

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
- Run `git worktree list`. For each linked worktree beyond the main checkout (autopilot/agent leftovers):
  - Clean (no uncommitted changes) and its branch fully merged into the default branch → `git worktree remove <path>` and delete the branch.
  - Dirty, or holding unmerged commits → leave it untouched and list it in the handoff with what it's holding. Never delete work to tidy up.
- Finish with `git worktree prune` to clear stale registrations.

## 6. Resume handoff (the final message)

Print a clear, tight handoff message in this exact shape:

```
Wound up <project-name> for today.
[if Step 0 fired:] Replanned first: <N> files folded · Replay: <clean | N orphans / M ghosts>
[if unmerged:] Branch `<name>` pushed but NOT merged — <why>
[if worktrees kept:] Worktrees kept: <path> — <what it holds>

Folder: <absolute path>
Resume next session: cd <absolute path> and run /resume-nt

Next chunk — <title from top of workplan.md>:
  - <item>
  - <item>
  - <item>
```

This is the bridge to the next conversation — the folder path must be absolute and copy-pasteable, and the named chunk should be the one the next session should grab first. `/resume-nt` will read the workplan + pending + latest summary and brief the user automatically.
