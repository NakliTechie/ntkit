---
description: Unattended executor — work the plan autonomously while you're away (in a meeting, overnight). Keeps going instead of pausing: does every reversible item, verifies and commits each, parks anything that needs a human decision or crosses a stop-line, and leaves a morning report /resume-nt can read.
argument-hint: "[goal or batch, e.g. \"finish the auth refactor\" | workplan | B]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
---

Run the project on autopilot while you're not watching — a meeting, a commute, overnight. Every other executor in the kit (`/execute-nt`, `/walkthrough-nt`) deliberately **pauses at boundaries** because you're there to steer. This one inverts that: it keeps working *because* you're not. The discipline that makes that safe isn't "ask before each step" — you're away, there's no one to ask — it's **verify every change, commit continuously so nothing is ever lost, park anything you can't safely decide alone, and never cross a stop-line.** Autonomy earns its keep only if the morning review finds trustworthy work and an honest list of what it couldn't touch.

If the current directory isn't a git repo, ask which project — don't guess. This command commits and runs unattended; it must be pointed at the right place.

`$ARGUMENTS` (optional): a **goal** in prose (`"finish the auth refactor and get tests green"`), or a named batch/plan (`workplan`, `B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

## Phase 0 — The launch contract (the one interactive moment)

Before going dark, state the plan back so the user can approve it *before* they walk away. Show:
- **Scope** — the ordered list of items it will attempt (from `$ARGUMENTS` or the workplan), and where it will stop (batch, goal, or "until the safe work runs out").
- **The stop-line** — the actions it will refuse to do autonomously and will park instead (Phase 4). Name them.
- **Default-decision policy** — for reversible design forks it hits, it will pick the option most consistent with the surrounding code and existing decisions in `history.md`, record the assumption, and move on rather than block.

Then go. This is the **only** pause — everything after runs to completion. If the user isn't present to approve (e.g. this was itself scheduled), skip straight to Phase 1 using the safest reading of scope: the top batch only, nothing destructive.

## Phase 1 — Order the work

Resolve scope into an ordered queue. From a workplan/report, respect sequencing — keystone and depended-on batches first. From a prose goal, decompose it into a checkboxed list written to `plan/workplan.md` under a chunk titled after the goal, so progress survives a crash and the morning review has something to read. Front-load the items most likely to unblock others; defer the ones most likely to hit a stop-line.

## Phase 2 — The autonomous loop

For each item, in order:
1. **Understand** — its precise location and the one-line "what + why". If it's really a *decision* rather than a task (a UX/structural call with no clearly-right answer), don't force code onto it — apply the default-decision policy, log the assumption to `history.md` via the `/decide-nt` shape, and move on.
2. **Do it** — the smallest change that resolves it, matching the surrounding code.
3. **Verify it** — the right way for *this* item: unit test / typecheck / build for logic; a **runtime or browser** check for anything UI-facing or `[test]`-marked (Chrome MCP for WebGPU/real-browser flows, never headless where it matters). Autonomy without verification is how a silent break survives to morning — this step is non-negotiable.
4. **Commit it** — one focused commit per item (or tight cluster), by path, never `git add -A`. Committing continuously is what makes an overnight run safe to interrupt: a killed session loses at most the item in flight. Do **not** push (that's `/windup-nt`) — local commits keep the tree recoverable without an outward action.
5. **Log it** — flip `[ ]` → `[x]` in the workplan and append a one-line progress entry: what changed · how verified · commit SHA.

Then take the next item. No pause between items, no pause between batches — that's the whole point.

## Phase 3 — When you hit a wall, don't wait — route around it

You're away; blocking is failing. So instead of stopping:
- **Needs a human decision** (a real judgment call, ambiguous requirement, product choice): write it to `plan/pending.md` under `Open questions` with enough context to answer cold, mark the item `[~]` with what's blocking it, and **move to the next item.**
- **A fix won't land** — two honest attempts to make an item pass verification, then stop poking it. Revert that item's uncommitted mess (`git restore`), mark it `[~]` with what you tried and where it failed, and move on. One stubborn item must never eat the whole night.
- **A stop-line** (Phase 4): never do it. Record it in the morning report's **Needs you** list and continue with everything else.

The loop ends when the queue is exhausted, the scoped goal/batch is met, or only stop-lined and blocked items remain. Then go to Phase 5.

## Phase 4 — The stop-lines (never cross these unattended)

These are irreversible or outward-facing; a machine running solo must not do them no matter how much they'd "finish the job." Park, don't perform:
- **Pushing, publishing, or deploying** — no `git push`, no release, no deploy. The run produces local commits; a human ships them.
- **Sending anything outward** — email, messages, PR/issue comments, posts.
- **Deleting or moving data irreversibly** — hard deletes, history rewrites, `git push --force`, dropping tables, emptying trash.
- **Credentials, secrets, money, access** — creating keys/accounts/IAM, changing permissions or sharing, anything financial.
- **Destructive infra** — tearing down or recreating shared resources.

Anything genuinely ambiguous about reversibility → treat as a stop-line and park it. (Standing global stop-signs still apply on top of this list.)

## Phase 5 — The morning report

Write `plan/$(date +%Y-%m-%d)-autopilot.md` and end with a tight handoff in this shape:

```
Autopilot ran <project-name> — <duration / "overnight">.

Landed (verified, committed — not pushed):
  - <item> — <how verified> — <SHA>
  - <item> — <how verified> — <SHA>

Parked — needs you:
  - <stop-lined action, why it needs a human>
  - <blocking question — see plan/pending.md>

Assumed (reversible calls I made — see plan/history.md):
  - <default taken, and why>

Left in the tree: <N commits, unpushed>. Nothing pushed, sent, or deleted.
Resume: cd <absolute path> and run /resume-nt
```

The two lists that matter most are **Landed** (with SHAs, so it's auditable) and **Needs you** (so the human's scarce attention goes straight to what only they can unblock). Everything reversible was decided and logged; nothing outward was touched. If invoked with `/notify-nt`, fire the completion ping so the user knows the run finished. `/resume-nt` reads this straight into the next session.
