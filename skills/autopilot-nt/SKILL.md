---
description: "Work a fix-workplan or goal unattended in a worktree; merges and pushes on green."
argument-hint: "[goal, report, or batch, e.g. \"finish the auth refactor\" | forward-pass | B]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent"]
entry: "briefed or building with an open report/workplan or explicit goal; clean base branch — never launched from blocked at the same wall"
exit: "run MERGED (gate green) or HELD (gate red) with a report written; never a silent end"
writes: "its own worktree; plan/<date>-autopilot.md (its record: goal, own queue, progress log, report, Impact); status flips on existing items in the source report or plan/workplan.md"
---

`/autopilot-nt` takes a batched fix-workplan (from `/forward-pass-nt`, `/ux-review-nt`, or `plan/workplan.md`) or a prose goal and works it: fix → verify → commit → check off → log, until the queue is done or it hits a wall.

`$SKILL` is this skill's base directory, printed when the skill loads; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

`$ARGUMENTS` (optional): a **goal** in prose (`"finish the auth refactor and get tests green"`), a **report name** to scope which audit's batch to run (`forward-pass`, `ux-review`), or a **batch letter** (`B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

Not in a git repo → ask which project; this command commits and may run unattended.

**Refuses cleanly, never invents a plan.** No report with open `[ ]` items, no open workplan chunk, and no goal in `$ARGUMENTS` → stop and say so: "Nothing to execute — run `/forward-pass-nt` or `/ux-review-nt` first, point me at `plan/workplan.md`, or give me a goal." Finding work is an audit command's job.

## The run

On entering a phase, read its Detail file first, then act; the Outcome column is the contract, not the procedure. Do not read ahead. Phase 0 is the only pause-shaped moment; everything after it runs to completion.

| Phase | Outcome | Detail |
|---|---|---|
| 0 Launch contract | Goal spec (done-when · because · never-degrade), stop-lines, default-decision policy, budget (default: the scoped batch or 6 hours), worktree, checker model — stated back as a veto window, then go. No user present → safest reading: top batch only, nothing destructive, default budget. | `references/launch.md` |
| 0.5 Worktree | `.worktrees/autopilot-<date>` on branch `autopilot/<date>`, names fixed once and written into the record; `plan/` symlinked from the main checkout; install step rerun. Never on the user's live checkout. | `references/launch.md` |
| 1 Order | An ordered queue: keystone first, unblockers front-loaded, stop-line candidates last. A prose goal is recorded verbatim and queued **in this run's own record**, never written into the shared workplan. | below |
| 2 Loop | Per item: understand · do (a bug gets the smallest fix; a Stray or refactor item gets its end state, with no-caller paths deleted) · verify with fresh eyes · commit by path · log `[x]` with an evidence row. Status flips only — never add, drop, re-rank, or re-word an item in a shared derived file. No pause between items or batches. Fold at batch boundaries; discard only what a file re-read recovers. | `references/loop.md` |
| 3 Walls | Route around, never wait: decisions go to the record's Needs you and the item is marked `[~]`; two honest attempts then revert; a stop-line goes to Needs you; three same-cause failures halt the run; budget hit stops cleanly. | `references/loop.md` |
| 4 Stop-lines | Never crossed unattended. | below |
| 4.5 Gate | The whole-project deterministic gate once, plus the never-degrade list. Green = landed. Red = held, whatever the per-item log says. | `references/ship.md` |
| 5 Ship | Green gate + clean main on the default branch + clean `--no-ff` merge → merge and push. Anything else cancels the ship and leaves the branch. Never force, never a PR. Worktree stays for the human. | `references/ship.md` |
| 6 Report | Closing sections appended to `plan/<date>-autopilot.md`, audited against `git log` and checker output first: the report, an `## Impact` section, then the fixed handoff block. Fire `/notify-nt`. | `references/report.md` |

## Phase 1 — Order the work

Skim the top of the repo's vision or roadmap doc, if any, so default decisions favour the product's direction. From a workplan or report, respect sequencing: keystone and depended-on batches first. From a prose goal, write the goal **verbatim** into this run's record as `## Goal`, then decompose it into a checkboxed queue **in that record**, never in `plan/workplan.md`. **Never edit the goal once the run starts.** Ticking your own queue is a status flip on an item this run authored; nothing else already written to the record is deleted or reworded. Front-load the items most likely to unblock others; defer the ones most likely to hit a stop-line.

## Phase 4 — The stop-lines (never cross these unattended)

Park these; never perform them:
- **Publishing, releasing, or deploying** — no release, no deploy, no CI trigger. The one sanctioned outward action is Phase 5's merge to the default branch and `git push`, only on a green final gate and clean main; never a force-push or a protected-branch override.
- **Sending anything outward** — email, messages, PR/issue comments, posts.
- **Deleting or moving data irreversibly** — hard deletes, history rewrites, `git push --force`, dropping tables, emptying trash.
- **Credentials, secrets, money, access** — creating keys/accounts/IAM, changing permissions or sharing, anything financial.
- **Destructive infra** — tearing down or recreating shared resources.
- **Breaking a caller outside the repo** — removing or reshaping a published package export, a persisted data shape (storage keys, file formats, schemas), a public URL or route, or a documented CLI flag or config key. Grep cannot see those callers.

Anything ambiguous about reversibility is a stop-line. Standing global stop-signs apply on top of this list.

## Impact declaration

`plan/<date>-autopilot.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).

Here the handoff block follows it. Status flips on existing items are applied during the run (W3) and listed here. Every Needs-you item is an `add` line: a question to `pending.md/Open questions`, a stop-lined action to `pending.md/Now`. A held branch adds `pending.md/Now — add: review/merge autopilot/<date>`. Assumptions stay in the record; `/replan-nt` folds them into `history.md` Decisions.
