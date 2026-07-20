---
description: Consolidate plan/ folder — fold daily summaries and scratch into history.md, restructure pending.md (Now/Parked/Open questions), refresh workplan.md, archive source files
entry: "plan/ accumulated beyond the three canonical files"
exit: "three canonical files rebuilt; replay check reported; sources archived"
writes: "plan/history.md, plan/pending.md, plan/workplan.md, plan/_archive/"
---

Consolidate the project's `plan/` folder into three canonical files. Run when plan/ has accumulated daily summaries and ad-hoc scratch and needs a reset.

If the current directory is not inside a git repo with a `plan/` folder, stop and ask the user which project to replan.

## Step 1: Inventory and classify

List everything currently in `plan/` (excluding any existing `_archive/`). Classify each file into exactly one bucket:

- **Daily summary** — matches `plan/YYYY-MM-DD-summary.md`, or a similar dated note that isn't one of the report types below. → folds into `history.md`
- **Autopilot morning report** — `plan/YYYY-MM-DD-autopilot.md` (from `/autopilot-nt`). → sweep **Parked — needs you** items into `pending.md` (questions → `Open questions`, stop-lined actions the human must perform → `Now`); fold **Assumed** entries into `history.md` Decisions, dated and marked `(autopilot default)`; carry any `[~]` items into `workplan.md`; then archive the report. If the `autopilot/<date>` branch it names is still unmerged, add one `Now` item: `Review/merge autopilot/<date>`.
- **Unnamed scratch** — generic names like `notes.md`, `scratch.md`, `thoughts.md`, untitled drafts. → folds into `history.md`
- **Forward-pass audit report** — `plan/forward-pass-YYYY-MM-DD.md` (from `/forward-pass-nt`). → sweep open (`[ ]`/`[~]`) workplan items into `pending.md`/`workplan.md`, fold its verified false-positives into `history.md` Dead ends, then archive the report
- **Walkthrough audit report** — `plan/walkthrough-YYYY-MM-DD.md` (from `/walkthrough-nt`). → same handling as a forward-pass report: sweep open (`[ ]`/`[~]`) / deferred items into `pending.md`/`workplan.md`, fold any verified non-issues into `history.md` Dead ends, then archive the report
- **UX-review report** — `plan/ux-review-YYYY-MM-DD.md` (from `/ux-review-nt`). → same handling: sweep open / deferred findings into `pending.md`/`workplan.md` (its structural recommendations are decisions — surface them for `/decide-nt`), then archive the report
- **Maintenance report** — `plan/maintenance-YYYY-MM-DD.md` (from `/maintain-nt`). → same handling: sweep open / deferred items into `pending.md`/`workplan.md` (major-bump decisions → `/decide-nt`), then archive the report
- **Canonical output** — `pending.md`, `workplan.md`, `history.md`. → gets rewritten this run
- **Named design / intentional artifact** — anything with a meaningful name: `feature-x-design.md`, `<milestone>-breakdown.md`, `pending-from-<source>.md`, charters, spec drafts. → **leave untouched**

Print the classification and proceed — no waiting. Ambiguity defaults to the safe side: if unsure whether a file is "named design" or "unnamed scratch", treat it as named (preserve untouched) and list it under `Preserved` in the Step 7 summary. A default that safe needs no question.

## Step 2: Rewrite history.md

Merge existing `plan/history.md` (if present) with the daily summaries + scratch being folded in. Final shape:

```
# History

## Decisions
- <YYYY-MM-DD> <load-bearing choice and why>
- ...

## Log
### YYYY-MM-DD
**Shipped:** ...
**Decisions:** ...
**Dead ends:** ...
**Open questions:** ...

### YYYY-MM-DD
...

## Dead ends
- <what was tried, why it didn't work>
- ...
```

Merge rules:
- Pull existing Decisions and Dead ends content forward — never overwrite blindly.
- Newest entries first in Log.
- Pull insights from the daily summaries' "Decisions" and "Dead ends" mentions into the top-level Decisions and Dead ends sections, so they're findable.
- Fold forward-pass reports' verified false-positives/non-issues into `## Dead ends` (keep the finding ID + the one-line reasoning) so a future audit doesn't re-flag them.

## Step 3: Restructure pending.md

Rewrite `plan/pending.md` into three sections, pulling from existing `pending.md`, any open items surfaced in the folded summaries, and any open (`[ ]`/`[~]`) / deferred items from forward-pass, walkthrough, ux-review, and maintenance reports:

```
# Pending

## Now
- <actionable, top priority>
- ...

## Parked
- <deferred, not in scope right now but not abandoned>
- ...

## Open questions
- <question that needs an answer before it can become a task>
- ...
```

Existing pending.md items are categorized by best judgment. Items pulled from the daily summaries' "Open questions" sections land in Open questions. If something's genuinely unclear, leave it in Now and flag in the summary at the end.

## Step 4: Refresh workplan.md

Regenerate `plan/workplan.md` from the freshly restructured pending Now. Same shape as /windup-nt produces: each chunk gets a short title, 2–5 items from Now, and a rough size estimate ("30 min", "half day", "1–2 hours"). Items that don't yet cluster go under `## Unbatched`.

**Preserve in-flight chunks:** If a chunk in the existing workplan still has all its items in pending Now, copy it through verbatim. Don't shuffle chunks for no reason — the user may be mid-execution.

## Step 4.5: Replay check

`history.md` is the event log; `pending.md` is derived state. Before archiving anything, replay the log — read the rebuilt `## Decisions` + `## Log` in order and ask of each item now in `pending.md`: does the log explain how it got there (opened, parked, resolved)? Two kinds of divergence to report:

- **Orphan** — a Now/Parked item no log entry accounts for (state drift: work happened off the record)
- **Ghost** — a log/decision thread with no closure and no pending item (dropped silently, never parked)

Don't fix silently: list divergences in the Step 7 summary (`Replay: clean` or `Replay: N orphans / M ghosts — <one line each>`) and fold the obvious ones back (an orphan gets a dated log line; a ghost gets parked or explicitly closed). Divergence found here is drift caught before it's archived — the cheap structural check that keeps the three files honest with each other.

## Step 5: Archive source files

Create `plan/_archive/` if it doesn't exist. Move (don't copy, don't delete) all files classified as "Daily summary", "Unnamed scratch", "Autopilot morning report", "Forward-pass audit report", "Walkthrough audit report", "UX-review report", or "Maintenance report" into it. Preserve filenames. (For audit reports, make sure open/deferred items landed in `pending.md`/`workplan.md` and verified non-issues landed in `history.md` Dead ends — and for autopilot reports, that Parked landed in pending and Assumed in Decisions — per Steps 2 & 3 — before archiving.)

## Step 6: Verify gitignore

Confirm `plan/` is in the repo's `.gitignore`. `_archive/` is inside `plan/` so it inherits that.

## Step 7: Print summary

Final message in this shape:

```
Replanned <project-name>.

Folded into history.md: <N> daily summaries, <M> scratch files
pending.md: <X> Now / <Y> Parked / <Z> Open questions
workplan.md: <N> chunks, top chunk = "<title>"
Archived to plan/_archive/: <count> files

Preserved untouched: <list of named design docs, or "none">
```

Keep tight — the user wants to see what changed without re-reading the files. Do NOT commit or push as part of /replan-nt; plan/ is gitignored, so consolidation stays local. (Push happens via /windup.)
