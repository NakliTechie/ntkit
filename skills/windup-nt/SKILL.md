---
description: "End of session: day summary, pending, commit and push non-plan work, resume handoff."
argument-hint: "(none)"
allowed-tools: ["Bash", "Glob", "Read", "Write", "Edit"]
entry: "any state — warns when closing from building (uncommitted work / verifier not green) and records that state in the handoff"
exit: "summary + pending + workplan updated (consolidated first if plan/ had accumulated), non-plan work pushed, clean closes merged to main, stray worktrees and merged branches swept, resume handoff printed"
writes: "plan/<date>-summary.md, plan/pending.md, plan/workplan.md; via the implicit replan: plan/history.md, plan/standing.md (answers only, if it exists), plan/_archive/"
---

Wind up the current project for today, in the project's repo root, steps 0–6 in order. Not in a git repo → ask which project; this command commits and pushes. First, create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`.

**Closing-state guard.** Windup persists whatever state the repo is in (per ntkit's `STATES.md`) and never blocks, but it names that state honestly. Closing from `building` (uncommitted work, a half-done chunk, a verifier not run or not green) → say so before writing anything: "Closing from `building`, not `verifying`: <what's unfinished>". Record that state and the unfinished item in both the day summary and the resume handoff, so `/resume-nt` reopens on the truth.

## The run

On entering a step, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Step | Outcome | Detail |
|---|---|---|
| 0 Implicit replan | Count `plan/` files from before today that `/replan-nt` would fold (dated summaries, autopilot and audit reports, scratch, a `soc.md` with old entries). 3 or more → announce and run the full `/replan-nt` consolidation first; carry its `Replay:` verdict into the handoff. Fewer → skip silently. | `references/replan-trigger.md` |
| 1 Day summary | `plan/<date>-summary.md` from the conversation, today's `git log`, `git status`/`diff`, and today's `soc.md` entries — Shipped (with SHAs) · Verified (and what is still owed) · Decisions · Tried then rolled back · Open questions · Deferred / parked. Bullets, not prose. | `references/summary-and-pending.md` |
| 2 Pending | `plan/pending.md` merged, not rewritten: Now / Parked / Open questions preserved, finished items removed, a "not now" said today lands in Parked, a flat file stays flat. | `references/summary-and-pending.md` |
| 3 Workplan | `plan/workplan.md` re-chunked from pending: logical, convenient, related; in-flight chunks copied through; keystone marked; tri-state checkboxes; loose sizes; finding IDs and `[test]` markers carried; leftovers under `## Unbatched`. Top chunk is what the next session starts on. | `references/workplan.md` |
| 4 Gitignore | `plan` ignored per MEMORY.md §0 (`git check-ignore -q plan`; add `/plan`, no trailing slash). | `references/ship.md` |
| 5 Ship | Non-plan changes committed by path and pushed to the branch's upstream (never force; pushing to main is authorized by invoking windup). On a feature branch and closing clean → merge to the default branch, push, delete the branch. Closing from `building` → push the branch, do not merge, name it in the handoff. Sweep worktrees: rescue each one's `plan/` files first; clean and merged → remove; dirty or unmerged → keep and list. `git worktree prune`. Sweep branches with `$SKILL/bin/branches.sh`: delete `merged` ones (local and remote) with their tip SHAs in the summary; list `hold` and `unmerged` ones and ask about them in one Open question. Sweep review media with `$SKILL/bin/review-media.sh`: delete the media of `done` run folders by name, each with its size in the summary; keep `open` ones. | `references/ship.md` |
| 6 Handoff | The message below, printed last. | below |

## 6. Resume handoff (the final message)

```
Wound up <project-name> for today.
[if Step 0 fired:] Replanned first: <N> files folded · Replay: <clean | N orphans / M ghosts>
[if unmerged:] Branch `<name>` pushed but NOT merged — <why>
[if worktrees kept:] Worktrees kept: <path> — <what it holds>
[if branches deleted:] Branches deleted: <N> merged (tip SHAs in the summary)
[if held or unmerged:] Branches waiting on you: <ref> — <reason>, … (merge, keep, or delete?)

Folder: <absolute path>
Resume next session: cd <absolute path> and run /resume-nt

Next chunk — <title from top of workplan.md>:
  - <item>
  - <item>
  - <item>
```

The folder path is absolute and copy-pasteable; the named chunk is the one the next session starts on.

## Impact declaration

`plan/<date>-summary.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Unlike the audit commands, `/windup-nt` is a reconcile writer: it applies these lines itself in Steps 2–3, and the section records what they changed ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)). Tag every item you add `[from: <date>-summary]`, quoting the summary's own words where it has them (`[from: <date>-summary "the words"]`, MEMORY.md §4), so `plancheck` can prove the item says what the summary says.
