---
description: Unattended executor — work the plan autonomously while you're away (in a meeting, overnight), in an isolated git worktree. Keeps going instead of pausing: does every reversible item, verifies each with fresh eyes, commits continuously, parks anything that needs a human decision or crosses a stop-line, runs a final whole-project gate, then ships a green run — merge to the default branch and push — or holds a red one back, and leaves a morning report /resume-nt can read.
argument-hint: "[goal or batch, e.g. \"finish the auth refactor\" | workplan | B]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
---

Run the project on autopilot while you're not watching — a meeting, a commute, overnight. Every other executor in the kit (`/execute-nt`, `/walkthrough-nt`) deliberately **pauses at boundaries** because you're there to steer. This one inverts that: it keeps working *because* you're not. The discipline that makes that safe isn't "ask before each step" — you're away, there's no one to ask — it's **run in an isolated worktree, verify every change with fresh eyes, commit continuously so nothing is ever lost, park anything you can't safely decide alone, never cross a stop-line, and ship only what a whole-project gate proves green — merge a passing run to the default branch and push it, hold a failing one back for review.** Autonomy earns its keep only if the morning review finds trustworthy work and an honest list of what it couldn't touch.

If the current directory isn't a git repo, ask which project — don't guess. This command commits and runs unattended; it must be pointed at the right place.

`$ARGUMENTS` (optional): a **goal** in prose (`"finish the auth refactor and get tests green"`), or a named batch/plan (`workplan`, `B`). Default: the keystone/top batch of the most recent report in `plan/`, else the top chunk of `plan/workplan.md`.

## Phase 0 — The launch contract (the one interactive moment)

Before going dark, state the plan back so the user can approve it *before* they walk away. Show:
- **Scope** — the ordered list of items it will attempt (from `$ARGUMENTS` or the workplan), and where it will stop (batch, goal, or "until the safe work runs out").
- **The stop-line** — the actions it will refuse to do autonomously and will park instead (Phase 4). Name them.
- **Default-decision policy** — for reversible design forks it hits, it will pick the option most consistent with the surrounding code and existing decisions in `history.md`, record the assumption, and move on rather than block.
- **Budget** — the run's hard ceiling: a wall-clock cap and/or item cap (default: the scoped batch, 6 hours — whichever ends first). A loop without a budget is the most expensive bug in unattended work.
- **Where it runs** — the worktree and branch it will create (Phase 0.5), so the user knows their own checkout stays untouched.

Then go. This is the **only** pause — everything after runs to completion. If the user isn't present to approve (e.g. this was itself scheduled), skip straight to Phase 0.5 using the safest reading of scope: the top batch only, nothing destructive, default budget.

## Phase 0.5 — Isolate in a worktree

Never run unattended on the user's live checkout. Create an isolated worktree and do all code work there:

```bash
git worktree add .worktrees/autopilot-$(date +%Y-%m-%d) -b autopilot/$(date +%Y-%m-%d)
```

(Ensure `.worktrees/` is gitignored; suffix `-2` if the branch already exists.) A worktree shares the repo's history but has its own checkout — an overnight run can't collide with anything the user does, and the morning review collapses to **one branch diff: merge or discard wholesale.** Two mechanics:
- **`plan/` stays canonical in the main checkout.** It's gitignored, so the worktree won't have it — symlink it in (`ln -s "$MAIN/plan" plan`, where `$MAIN` is the original repo root) so the plan is read from, and every log and report is written to, one place.
- **Rebuild what doesn't travel.** Run the project's install step in the worktree if the build needs it — `node_modules` and friends don't come with a worktree.

All commits from here on land on the `autopilot/<date>` branch. Don't remove the worktree at the end — the human does that after review.

## Phase 1 — Order the work

Resolve scope into an ordered queue. From a workplan/report, respect sequencing — keystone and depended-on batches first. From a prose goal, decompose it into a checkboxed list written to `plan/workplan.md` under a chunk titled after the goal, so progress survives a crash and the morning review has something to read. Front-load the items most likely to unblock others; defer the ones most likely to hit a stop-line.

## Phase 2 — The autonomous loop

For each item, in order:
1. **Understand** — its precise location and the one-line "what + why". If it's really a *decision* rather than a task (a UX/structural call with no clearly-right answer), don't force code onto it — apply the default-decision policy, log the assumption to `history.md` via the `/decide-nt` shape, and move on.
2. **Do it** — the smallest change that resolves it, matching the surrounding code.
3. **Verify it — with fresh eyes.** Spawn a verification subagent (Task) whose context is only the item's spec (ID · location · what + why), the diff, and how to check — not the maker's reasoning. The model that wrote a fix is too kind to it; a checker that never saw the justification isn't. It runs the right check for *this* item — unit test / typecheck / build for logic; a **runtime or browser** check for anything UI-facing or `[test]`-marked (Chrome MCP for WebGPU/real-browser flows, never headless where it matters) — and returns pass/fail with evidence. One rule it enforces without exception: **a fix may never modify, skip, or delete the check that verifies it.** If the diff touches a test file, the item goes in the report's **Tests changed** section whatever the verdict. Autonomy without verification is how a silent break survives to morning — this step is non-negotiable.
4. **Commit it** — one focused commit per item (or tight cluster), by path, never `git add -A`. Committing continuously is what makes an overnight run safe to interrupt: a killed session loses at most the item in flight. Don't push **per item** — the single end-of-run push happens once in Phase 5, and only if the final gate is green. Per-item commits stay local on the `autopilot/<date>` branch, so the tree is always recoverable.
5. **Log it** — flip `[ ]` → `[x]` in the workplan and append a one-line progress entry: what changed · how verified · commit SHA.

Then take the next item. No pause between items, no pause between batches — that's the whole point. Between items, glance at the launch-contract budget: the clock and the item cap are exits, not suggestions.

## Phase 3 — When you hit a wall, don't wait — route around it

You're away; blocking is failing. So instead of stopping:
- **Needs a human decision** (a real judgment call, ambiguous requirement, product choice): write it to `plan/pending.md` under `Open questions` with enough context to answer cold, mark the item `[~]` with what's blocking it, and **move to the next item.**
- **A fix won't land** — two honest attempts to make an item pass verification, then stop poking it. Revert that item's uncommitted mess (`git restore`), mark it `[~]` with what you tried and where it failed, and move on. One stubborn item must never eat the whole night.
- **A stop-line** (Phase 4): never do it. Record it in the morning report's **Needs you** list and continue with everything else.
- **Systemic failure** — three consecutive items failing verification for the *same root cause* (the build is broken, a shared dependency is wrong) means the substrate is sick, not the items. Halt the run: revert the item in flight, write what broke — with the evidence — to the report, and end early. Parking forty items one by one against a broken build is burning the night, not working it.
- **Budget exhausted** — the wall-clock or item cap from the launch contract is hit: finish or revert the item in flight, then stop cleanly.

The loop ends when the queue is exhausted, the scoped goal/batch is met, only stop-lined and blocked items remain, the budget runs out, or a systemic halt fires. Then go to Phase 4.5.

## Phase 4 — The stop-lines (never cross these unattended)

These are irreversible or outward-facing; a machine running solo must not do them no matter how much they'd "finish the job." Park, don't perform:
- **Publishing, releasing, or deploying** — no release, no deploy, no CI trigger. (The *one* sanctioned outward action is the end-of-run ship in Phase 5 — merge the branch to the default branch and `git push` — and only on a green final gate + clean main. Nothing else outward, and never a force-push or a protected-branch override.)
- **Sending anything outward** — email, messages, PR/issue comments, posts.
- **Deleting or moving data irreversibly** — hard deletes, history rewrites, `git push --force`, dropping tables, emptying trash.
- **Credentials, secrets, money, access** — creating keys/accounts/IAM, changing permissions or sharing, anything financial.
- **Destructive infra** — tearing down or recreating shared resources.

Anything genuinely ambiguous about reversibility → treat as a stop-line and park it. (Standing global stop-signs still apply on top of this list.)

## Phase 4.5 — The final gate

Per-item checks prove each fix in isolation; they don't prove the fixes coexist — an early item can break a later one's assumptions while every individual check stays green. So before shipping, run the **whole-project deterministic gate once**: the full test suite, the typecheck, the build, the linter — whatever the project has. Green → the run is **landed**, proceed to Phase 5 to ship it. Red → the run is **not landed**, whatever the per-item log says: bisect if cheap (revert the most recent suspect commits on the branch until green, park what you reverted), otherwise **skip Phase 5** and report the branch red with the failure output front and center. "Done" is the gate's word, never the agent's — and only a green gate ships.

## Phase 5 — Ship it (green gate only)

**Only if Phase 4.5 came back GREEN**, merge the run to the project's default branch (`main`, or `master`) and push it. This is the one outward action autopilot is authorized to take, gated three ways — green gate, clean main, clean merge:

```bash
# from the main checkout ($MAIN); requires it to be on the default branch and clean
git -C "$MAIN" merge --no-ff "autopilot/$(date +%Y-%m-%d)" -m "autopilot <date>: <N> items — gate green"
git -C "$MAIN" push origin HEAD
```

Each of these **cancels the ship** and falls back to leaving the branch for review (report it in Phase 6 — the branch is the safety net):
- **Red or skipped gate** — never merge unverified work.
- **Main isn't clean, or isn't on the default branch** — the user has uncommitted work or a different branch checked out in `$MAIN`; merging on top of that isn't yours to do.
- **Non-fast-forward beyond a clean `--no-ff` merge / any conflict** — main moved under you. Don't resolve conflicts unattended; leave the branch and flag it.
- **Push rejected** — remote moved or auth failed non-interactively; the merge stays local and the push is *owed* — say so.

Never `--force`, never touch a branch-protection rule, never open or merge a PR on the user's behalf. **Leave the worktree in place regardless** — the human removes it after a glance. On a clean ship, the branch is merged into the default branch and the remote is updated.

## Phase 6 — The morning report

Write `plan/$(date +%Y-%m-%d)-autopilot.md` and end with a tight handoff in this shape:

```
Autopilot ran <project-name> — <duration / "overnight"> on branch autopilot/<date>.

Final gate: <GREEN (tests · typecheck · build · lint) | RED — <what failed>>
Shipped:    <MERGED to <default branch> + pushed (<merge SHA>) | HELD on branch autopilot/<date> — <gate red | main dirty | conflict | push owed>>

Landed (fresh-eyes verified):
  - <item> — <how verified> — <SHA>
  - <item> — <how verified> — <SHA>

Parked — needs you:
  - <stop-lined action, why it needs a human>
  - <blocking question — see plan/pending.md>

Tests changed (review before trusting green):
  - <test file · which item touched it · checker's note>        [or "none"]

Assumed (reversible calls I made — see plan/history.md):
  - <default taken, and why>

Ended because: <queue done | goal met | budget hit | systemic halt: <cause>>
<if MERGED:> <default branch> is updated on the remote — pull it. Worktree left at .worktrees/<name>: git worktree remove .worktrees/<name>
<if HELD:>   Review: git diff <default branch>...autopilot/<date> — merge or discard, then git worktree remove .worktrees/<name>
Resume: cd <main checkout absolute path> and run /resume-nt (it reads this report)
```

The three lines that matter most are the **Final gate** (whether the branch is trustworthy at all), **Shipped** (merged or held, and why), and **Needs you** (so the human's scarce attention goes straight to what only they can unblock). A green run ships itself to the default branch; a red or conflicted one touches nothing outward and waits on the branch. Everything reversible was decided and logged. Finish by firing `/notify-nt "<project>: autopilot done — gate <GREEN|RED>, <shipped|held>, <N> landed, <M> need you"` so the finish is a ping, not a surprise — it degrades silently if no channel is configured. `/resume-nt` reads this report straight into the next session.
