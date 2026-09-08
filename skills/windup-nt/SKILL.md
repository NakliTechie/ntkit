---
description: "End of session: day summary, pending, commit and push non-plan work, resume handoff."
entry: "any state — warns when closing from building (uncommitted work / verifier not green) and records that state in the handoff"
exit: "summary + pending + workplan updated (consolidated first if plan/ had accumulated), non-plan work pushed, clean closes merged to main, stray worktrees swept, resume handoff printed"
writes: "plan/<date>-summary.md, plan/pending.md, plan/workplan.md; via the implicit replan: plan/history.md, plan/_archive/"
---

Wind up the current project for today, in the project's repo root, steps 0–6 in order.

If the current directory is not inside a git repo, stop and ask the user which project to wind up.

**Closing-state guard.** Windup persists whatever state the repo is in (per ntkit's `STATES.md`) — it never blocks — but it must be honest about which state that is. Closing from `building` (uncommitted work, a half-done chunk, a verifier not run or not green) → say so before writing anything — "Closing from `building`, not `verifying`: <what's unfinished>" — and record that state and the unfinished item in both the day summary and the resume handoff, so tomorrow's `/resume-nt` reopens on the truth. A windup that papers over a mid-chunk state is the one bug this command can have.

## The run

On entering a step, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead.

| Step | Outcome | Detail |
|---|---|---|
| 0 Implicit replan | Count `plan/` files from before today that `/replan-nt` would fold (dated summaries, autopilot and audit reports, scratch, a `soc.md` with old entries). 3 or more → announce and run the full `/replan-nt` consolidation first; carry its `Replay:` verdict into the handoff. Fewer → skip silently. | `references/replan-trigger.md` |
| 1 Day summary | `plan/<date>-summary.md` from the conversation, today's `git log`, `git status`/`diff`, and today's `soc.md` entries — Shipped (with SHAs) · Verified (and what is still owed) · Decisions · Tried then rolled back · Open questions · Deferred / parked. Bullets, not prose. | `references/summary-and-pending.md` |
| 2 Pending | `plan/pending.md` merged, not rewritten: Now / Parked / Open questions preserved, finished items removed, a "not now" said today lands in Parked, a flat file stays flat. | `references/summary-and-pending.md` |
| 3 Workplan | `plan/workplan.md` re-chunked from pending: logical, convenient, related; keystone marked; tri-state checkboxes; loose sizes; finding IDs and `[test]` markers carried; leftovers under `## Unbatched`. Top chunk is what the next session starts on. | `references/workplan.md` |
| 4 Gitignore | `plan/` present in `.gitignore`; add it if not. | `references/ship.md` |
| 5 Ship | Non-plan changes committed by path and pushed to the branch's upstream (never force; pushing to main is authorized by invoking windup). On a feature branch and closing clean → merge to the default branch, push, delete the branch. Closing from `building` → push the branch, do not merge, name it in the handoff. Sweep worktrees: clean and merged → remove; dirty or unmerged → keep and list. `git worktree prune`. | `references/ship.md` |
| 6 Handoff | The message below, printed last. | below |

## 6. Resume handoff (the final message)

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

This is the bridge to the next conversation — the folder path must be absolute and copy-pasteable, and the named chunk is the one the next session grabs first. `/resume-nt` reads the workplan, pending, and latest summary and briefs the user from them.

## Impact declaration

`plan/<date>-summary.md` is a **record**: append-only, never rewritten ([`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md)). End it with an `## Impact` section naming what changed in the derived files this run:

```markdown
## Impact
- pending.md/Now — add: review the auth refactor branch before it goes stale
- workplan.md/B2 — reword: split the migration chunk, it was two jobs
- none — nothing shipped today that changes the plan
```

`/windup-nt` is one of the **three sanctioned reconcile writers** (with `/replan-nt` and `/scaffold-nt`), so unlike the audit commands it both declares the impact *and* applies it in Steps 2–3. Declare it anyway: the summary is the record that explains why `pending.md` looks the way it does tomorrow, and it is what a replay check reads. Tag every item you add with `[from: <date>-summary]` so the provenance resolves.
