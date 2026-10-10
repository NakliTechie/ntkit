---
description: "Read plan/ and brief the current state, then pause; `go` starts the top chunk."
argument-hint: "[go — brief, then start the top chunk immediately]"
allowed-tools: ["Bash", "Glob", "Read"]
entry: "any state; plan/ preferred, degrades to git-only"
exit: "brief printed naming the current state and its legal next moves; paused for direction"
writes: "nothing"
---

Brief the user on where to pick up, from what `/windup-nt` left in `plan/`.

**Read-only briefing.** Never write to `plan/`; never invoke `/windup-nt` or `/replan-nt`. Present the brief. Then, with `go` in `$ARGUMENTS` and a clean picture (no HELD autopilot branch, no ⚠ inconsistency from Step 2.5), announce and start the top chunk; otherwise pause for direction.

## Step 1: Locate context files

Look inside `plan/` for:
- `workplan.md` — the chunked execution play (primary)
- `pending.md` — open items, especially `## Open questions`; also scan `## Parked` so deferred "not now" items resurface
- `history.md` — the recent `## Decisions`, for context
- `standing.md` — if it exists, the standing questions and their current answers ([MEMORY.md §7](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#7-standing-questions)). Print them as they stand; never recompute an answer here
- The most recent `plan/YYYY-MM-DD-summary.md` — the freshest "where we left off"
- The newest open lab campaign in `plan/lab/*/` (newest leg report has no RETIRED or GOAL-MET end-state) — name it with its `Re-arm` line; a campaign waiting on a human re-arm is a next move
- The most recent `plan/YYYY-MM-DD[-N]-autopilot.md` (latest date, then highest N) — an unattended run's report (branch · final gate · **Shipped: merged or held** · Landed / Needs you / Assumed). If it is **newer than the newest summary**, read its `Shipped:` line: **HELD** (red gate / conflict) means an unmerged `autopilot/<date>` branch is waiting, and reviewing it outranks the workplan's top chunk; **MERGED** means a green run already shipped to the default branch: pull it and glance at what landed.

None of these exist → read the README, `git log --oneline -10` and `git status`, and orient from those. Say in the brief that no `plan/` handoff is on file and suggest `/windup-nt` at the next end of session.

## Step 2: Gather quick git context

Branch, ahead/behind vs upstream, and the count of uncommitted files (`git status -sb`).

Then run `sh $SKILL/../windup-nt/bin/branches.sh` when it exists. It changes nothing and reads refs as of the last fetch. Count its `merged` lines, and keep its `hold` and `unmerged` lines for the brief.

Also count generated files, since a run that floods the disk is invisible in `git status`:

```bash
find . \( -name .git -o -name node_modules -o -name .venv -o -name .build -o -name target \) -prune -o -type f -print | wc -l
```

## Step 2.5: Determine and validate the state

Name the repo's current state per ntkit's `STATES.md` (kit doctrine, not a file in this project): `fresh` / `briefed` / `building` / `verifying` / `blocked` / `shipped`, from the evidence gathered: open workplan items, uncommitted work, unexecuted audit reports, tried-trails, HELD autopilot branches. Then flag (don't fix) anything that doesn't add up:

- workplan says mid-chunk but the tree is clean and nothing recent in `git log` — chunk state may be stale
- an audit report (`forward-pass` / `ux-review`) has open items but the workplan doesn't mention it — unexecuted findings
- the latest summary claims a clean close but there's uncommitted work — dishonest windup, trust the tree
- a HELD `autopilot/<date>` branch is waiting — reviewing it outranks the workplan
- the file count above exceeds 20,000, or `git status --ignored` shows a generated-data directory with thousands of entries — unbounded evidence (SUBSTANCE.md §3.9); name the directory and propose cleanup by name before any new run
- a systems-level workplan (engine, server, runtime, kernels) schedules Benchmark or Optimise items while Feature-complete items stay open — the build order is Feature complete → Benchmark → Optimise; flag the early optimisation work

## Step 3: Present the resumption brief

Output in this exact shape:

```
Resuming <project-name>.

Folder: <absolute path>
Branch: <branch> · <ahead/behind status> · <clean | N uncommitted files>
State: <state from Step 2.5> · legal next: <the 2–3 moves that fit this state>
Phase: <Feature complete | Benchmark | Optimise — only for a systems-level project whose workplan names phases>
[if branches.sh listed any:] Branches: <N> merged, not swept (the next /windup-nt deletes them) · <M> waiting on a call: <oldest 2–3 refs>
<⚠ one line per inconsistency found in Step 2.5, if any>

Verification: <the project's budget from workplan.md, or "no budget on file — default: check once per batch boundary, 5,000 files / 500 MB of generated data"> · generated files: <N>
Last session (<date from latest summary, or "no summary on file">):
  Shipped: <one-line bullet, or "—">
  Decisions: <one-line bullet, or "—">
  Open questions: <bullet, or "—">
  Parked (<count>): <top 2–3 deferred items, or "—"> — not abandoned, still waiting
[if an open lab campaign:]
Lab: <slug> — leg <n> ended <state> · Re-arm: <CONTINUE … | STOP …>

[if standing.md exists:]
Standing:
  <question>: <its answer bullets, one line each, tags dropped>

Next chunk — "<title from top of workplan.md>" (<size estimate>):
  - <item 1>
  - <item 2>
  - <item 3>

Blocking (if any):
  - <open questions from pending.md that relate to this chunk; or top 2-3 open questions if relevance unclear>
```

**If an autopilot run is on file** (report newer than the newest summary), insert this block right after the `Last session` lines; for a HELD run it is the most urgent thing in the brief:

```
Autopilot ran <date> — branch autopilot/<date> · gate <GREEN | RED: what> · <MERGED to <default branch> | HELD>:
  Landed: <N> items · Needs you: <top 1–2 items> · Assumed: <N>
  <if HELD:>   Review: git diff <default branch>...autopilot/<date> → merge or discard
  <if MERGED:> Already shipped — git pull; nothing to review beyond a glance
```

No `workplan.md`, or an empty one, but `pending.md` has items → show the top 3–5 items from `## Now` instead of a chunk, and note that `/replan-nt` would generate a proper workplan.

## Verification discipline (applies to the chunk this brief starts)

When the next chunk is underway, hold to the verification budget: build the whole batch, check it once at its boundary, run only the checks that cover that batch, keep generated test data in one capped temp directory, and take one diagnostic batch per failure. Do not run tests or evals between steps. A suite that already passed on unchanged code does not run again. State in the brief which checks the chunk owes and when, so the next session runs those and no others.

## Step 4: Hand off — `go` or one open-ended question

**With `go` and a clean picture:** skip the question; print `Starting "<chunk title>".` after the brief and begin. A HELD autopilot branch or a ⚠ inconsistency cancels the `go`.

Otherwise end with a single open-ended question:

> Ready to start on **"<chunk title>"**, or want to pick a different chunk / look at something else?

When a **HELD** autopilot run is on file, ask this instead:

> Review the **autopilot/<date>** branch first (merge or discard), or skip to **"<chunk title>"**?

## Step 5: After the user responds

Start executing only after the user picks a direction, and follow their pick, not necessarily the top chunk.

**When the question is about the past** ("when did we decide X", "why did we drop Y"), search the records instead of guessing from the canonical files: `scholia history <terms> --plan .` ranks every entry under `plan/`, `_archive/` included, with its date ([MEMORY.md §8](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#8-recall-over-the-records)). No scholia → `rg -n <terms> plan/`.
