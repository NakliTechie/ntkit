---
name: resume-nt
description: "Read plan/ and brief the current state, then pause; `go` starts the top chunk."
allowed-tools: Bash Glob Read
metadata:
  argument-hint: "[go — brief, then start the top chunk immediately]"
  entry: "any state; plan/ preferred, degrades to git-only"
  exit: "the brief contains a `State: <one of the six STATES.md states> · legal next: …` line; `git status --short` is unchanged by the run (it writes nothing)"
  writes: "nothing"
---

Brief the user on where to pick up, from what `/windup-nt` left in `plan/`.

**Read-only briefing.** Never write to `plan/`; never invoke `/windup-nt` or `/replan-nt`. Present the brief, then follow Step 4.

## Step 1: Locate context files

Look inside `plan/` for:
- `workplan.md` — the chunked execution play (primary)
- `pending.md` — open items, especially `## Open questions`; also scan `## Parked` so deferred "not now" items resurface
- `history.md` — the recent `## Decisions`, for context
- `failures.md` — if it exists, the command shapes earlier sessions saw fail, with the fix when one was found. Before running a command whose tool and command word match a line, use its fix; on a line with `fix: ?`, expect the error and check first
- `standing.md` — if it exists, the standing questions and their current answers ([MEMORY.md §7](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#7-standing-questions)). Print them as they stand; never recompute an answer here
- The most recent `plan/YYYY-MM-DD-summary.md` — the freshest "where we left off"
- The newest open lab campaign in `plan/lab/*/` (newest leg report has no RETIRED or GOAL-MET end-state) — name it with its `Re-arm` line; a campaign waiting on a human re-arm is a next move
- The most recent `plan/YYYY-MM-DD[-N]-autopilot.md` (latest date, then highest N) — an unattended run's report (branch · final gate · **Shipped: merged or held** · Landed / Needs you / Assumed). If it is **newer than the newest summary**, read its `Shipped:` line: **HELD** (red gate / conflict) means an unmerged `autopilot/<date>` branch is waiting, and reviewing it outranks the workplan's top chunk; **MERGED** means it already shipped: pull and glance at what landed.

None of these exist → read the README, `git log --oneline -10` and `git status`, and orient from those. Say in the brief that no `plan/` handoff is on file and suggest `/windup-nt` at the next end of session.

## Step 2: Gather quick git context

Branch, ahead/behind vs upstream, and the count of uncommitted files (`git status -sb`).

Then run `sh $SKILL/../windup-nt/bin/branches.sh` when it exists. It changes nothing and reads refs as of the last fetch. Count its `merged` lines, and keep its `hold` and `unmerged` lines for the brief.

Also count generated files:

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
- a systems-level workplan schedules Benchmark or Optimise items while Feature items stay open — flag the early optimisation work. For a systems-level project (engine, server, runtime, kernel, compiler, protocol), the order is Feature complete (including width) → Benchmark → Optimise, as the project's `plan/workplan.md` states. Never start Optimise while a Feature item is open. Before Benchmark, one observed speed reading per stage boundary is allowed, labelled 'observed, not a benchmark'; it never starts tuning and never gates.
- a parity matrix over ~100 rows, or with rows from another product category, and no owner-approved scope on file — scope by transcription (SUBSTANCE item 12)
- the keystone is blocked while commits land on later or peripheral chunks, or a decision waits in a doc but not in `pending.md` Open questions — periphery while blocked (item 13); surface the decision first
- uncommitted changes or new untracked source that no check has run on, beyond about one batch, or local commits not pushed after a passing boundary — unbounded batch (item 11) and unbacked work; name the branch and the count

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

Try it: <the command or URL that runs the current working build, from the README or the last handback, or "no runnable build documented">
Verification: <the project's budget from workplan.md, or "no budget on file — default: check once per batch boundary, 5,000 files / 500 MB of generated data"> · generated files: <N>
Last session (<date from latest summary, or "no summary on file">):
  Shipped: <one-line bullet, or "—">
  Decisions: <one-line bullet, or "—">
  Open questions: <bullet, or "—">
  Parked (<count>): <top 2–3 deferred items, or "—"> — not abandoned, still waiting
  Pick up: <the summary's Next action, or "—"> · last error: <its Last error, or "—">
  Transcript: <the summary's Transcript path, or "not kept"> · search: rg -n '<term>' <path>
[if plan/failures.md exists:] Known failures: <N> shapes · with a fix: <top 3 by seen, each `tool cmd → fix`> · no fix yet: <count>
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

Hold the chunk to the verification budget: build the whole batch, check it once at its boundary with only the checks that cover it, keep generated test data in one capped temp directory, and take one diagnostic batch per failure testing two to four written hypotheses. No tests or evals between steps; a suite that passed on unchanged code does not run again. State in the brief which checks the chunk owes and when.

## Step 4: Hand off — `go` or one open-ended question

**With `go` and a clean picture:** skip the question; print `Starting "<chunk title>".` after the brief and begin. A HELD autopilot branch or a ⚠ inconsistency cancels the `go`.

Otherwise end with a single open-ended question:

> Ready to start on **"<chunk title>"**, or want to pick a different chunk / look at something else?

When a **HELD** autopilot run is on file, ask this instead:

> Review the **autopilot/<date>** branch first (merge or discard), or skip to **"<chunk title>"**?

## Step 5: After the user responds

Start executing only after the user picks a direction, and follow their pick, not necessarily the top chunk.

**When the question is about the past** ("when did we decide X"), search the records instead of guessing: `scholia history <terms> --plan .` ranks every entry under `plan/`, `_archive/` included ([MEMORY.md §8](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#8-recall-over-the-records)). No scholia → `rg -n <terms> plan/`. For an exact error text, path or number from the last session, search its `Transcript:` file with `rg -n` before answering from the summary.
