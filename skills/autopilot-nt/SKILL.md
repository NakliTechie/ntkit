---
description: "Work a fix-workplan or goal unattended in a worktree; merges and pushes on green."
argument-hint: "[goal, report, or batch, e.g. \"finish the auth refactor\" | forward-pass | B]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "briefed or building with an open report/workplan or explicit goal; clean base branch — never launched from blocked at the same wall"
exit: "run MERGED (gate green) or HELD (gate red) with a report written; never a silent end"
writes: "its own worktree, the source report or plan/workplan.md (checkboxes), plan/<date>-autopilot.md"
---

`/autopilot-nt` is the kit's executor. It takes a batched fix-workplan (from `/forward-pass-nt`, `/ux-review-nt`, `/maintain-nt`, or `plan/workplan.md`) or a prose goal and works it: fix → verify → commit → check off → log, until the queue is done or it hits a wall. `/walkthrough-nt` is the live-runtime counterpart; this is the executor for a *static* plan.

Attended or away, the mechanics are the same. Safety comes from the mechanics, not from asking before each step: an isolated worktree, fresh-eyes verification of every change, continuous commits, parking what it cannot decide alone, never crossing a stop-line, and shipping only what a whole-project gate proves green.

If the current directory isn't a git repo, ask which project. This command commits and may run unattended; it must be pointed at the right place.

`$ARGUMENTS` (optional): a **goal** in prose (`"finish the auth refactor and get tests green"`), a **report name** to scope which audit's batch to run (`forward-pass`, `ux-review`, `maintenance`), or a **batch letter** (`B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

**Refuses cleanly, never invents a plan.** No report with open `[ ]` items, no open workplan chunk, and no goal in `$ARGUMENTS` → stop and say so: "Nothing to execute — run `/forward-pass-nt`, `/ux-review-nt`, or `/maintain-nt` first, point me at `plan/workplan.md`, or give me a goal." Finding work is an audit command's job; the maker–checker split only holds if finding and fixing stay separate runs.

## The run

Read a reference when you reach its phase, not before. Phase 0 is the only pause-shaped moment; everything after it runs to completion.

| Phase | Outcome | Detail |
|---|---|---|
| 0 Launch contract | Goal spec (done-when · because · never-degrade), stop-lines, default-decision policy, budget (default: the scoped batch or 6 hours), worktree, checker model — stated back as a veto window, then go. No user present → safest reading: top batch only, nothing destructive, default budget. | `references/launch.md` |
| 0.5 Worktree | `.worktrees/autopilot-<date>` on branch `autopilot/<date>`, `plan/` symlinked from the main checkout, install step rerun. Never on the user's live checkout. | `references/launch.md` |
| 1 Order | An ordered queue: keystone first, unblockers front-loaded, stop-line candidates last. A prose goal becomes a checkboxed chunk in `plan/workplan.md`. | below |
| 2 Loop | Per item: understand · do · verify with fresh eyes · commit by path · log `[x]` with an evidence row. No pause between items or batches. Fold at batch boundaries; discard only what a file re-read recovers. | `references/loop.md` |
| 3 Walls | Route around, never wait: decisions parked to `pending.md` and marked `[~]`; two honest attempts then revert; a stop-line goes to Needs-you; three same-cause failures halt the run; budget hit stops cleanly. | `references/loop.md` |
| 4 Stop-lines | Never crossed unattended. | below |
| 4.5 Gate | The whole-project deterministic gate once, plus the never-degrade list. Green = landed. Red = held, whatever the per-item log says. | `references/ship.md` |
| 5 Ship | Green gate + clean main on the default branch + clean `--no-ff` merge → merge and push. Anything else cancels the ship and leaves the branch. Never force, never a PR. Worktree stays for the human. | `references/ship.md` |
| 6 Report | `plan/<date>-autopilot.md`, audited against `git log` and checker output before it is written, ending in the fixed handoff block. Fire `/notify-nt`. | `references/report.md` |

## Phase 1 — Order the work

If the repo carries a Vision-and-Roadmap (or vision doc), skim its top section first — three lines of strategy in context is what lets default decisions (Phase 0's policy) land on the product's side of a fork rather than the generic side. Then resolve scope into an ordered queue. From a workplan/report, respect sequencing — keystone and depended-on batches first. From a prose goal, decompose it into a checkboxed list written to `plan/workplan.md` under a chunk titled after the goal, so progress survives a crash and the morning review has something to read. Front-load the items most likely to unblock others; defer the ones most likely to hit a stop-line.

## Phase 4 — The stop-lines (never cross these unattended)

These are irreversible or outward-facing; a machine running solo must not do them no matter how much they'd "finish the job." Park, don't perform:
- **Publishing, releasing, or deploying** — no release, no deploy, no CI trigger. (The *one* sanctioned outward action is the end-of-run ship in Phase 5 — merge the branch to the default branch and `git push` — and only on a green final gate + clean main. Nothing else outward, and never a force-push or a protected-branch override.)
- **Sending anything outward** — email, messages, PR/issue comments, posts.
- **Deleting or moving data irreversibly** — hard deletes, history rewrites, `git push --force`, dropping tables, emptying trash.
- **Credentials, secrets, money, access** — creating keys/accounts/IAM, changing permissions or sharing, anything financial.
- **Destructive infra** — tearing down or recreating shared resources.

Anything genuinely ambiguous about reversibility → treat as a stop-line and park it. (Standing global stop-signs still apply on top of this list.)
