---
description: "Fold accumulated plan/ files into history, pending, workplan; archives the sources."
argument-hint: "(none)"
allowed-tools: ["Bash", "Glob", "Read", "Write"]
entry: "plan/ accumulated beyond the three canonical files"
exit: "three canonical files rebuilt; replay check reported; sources archived"
writes: "plan/history.md, plan/pending.md, plan/workplan.md, plan/standing.md (answers only, if the file exists), plan/_archive/, plan/ideas.md (or IDEAS.md) from soc triage"
---

Consolidate the project's `plan/` folder into three canonical files and archive the folded sources. Never commit or push; `plan/` is gitignored. Not in a git repo with a `plan/` → ask which project.

## Step 1: Inventory and classify

List everything in `plan/` except `_archive/`. Classify each file into exactly one bucket:

- **Daily summary** — `plan/YYYY-MM-DD-summary.md`, or a similar dated note that isn't a report. → fold into `history.md`; archive.
- **Autopilot morning report** — `plan/YYYY-MM-DD[-N]-autopilot.md` (from `/autopilot-nt`). → apply its `## Impact` adds (its Needs-you items, and `Review/merge autopilot/<date>` for a held branch). An older report with no `## Impact`: **Needs you** questions → `Open questions`, stop-lined actions → `Now`, and `Review/merge` if its branch is unmerged. **Assumed** entries into `history.md` Decisions, dated and marked `(autopilot default)`; `[~]` items into `workplan.md`. Archive.
- **Unnamed scratch** — generic names like `notes.md`, `scratch.md`, `thoughts.md`, untitled drafts. → fold into `history.md`; archive.
- **Stream-of-consciousness log** — `plan/soc.md` (from `/soc-nt`). → **triage line by line**, never blanket-fold: load-bearing choices → `history.md` Decisions (dated from the entry's timestamp); actionable future work → the ideas backlog (`plan/ideas.md`, or `IDEAS.md` if the repo has one); deferred / "not now" → `pending.md` `## Parked`; questions → `pending.md` Open questions; the rest → `history.md` Log under the entry's date. Archive it as `soc-<replan-date>.md` so the next cycle's name doesn't collide.
- **Dated audit report** — any `plan/<type>-YYYY-MM-DD.md` written by a kit command. → open (`[ ]`/`[~]`) and deferred items into `pending.md`/`workplan.md`; verified false positives and non-issues into `history.md` Dead ends (finding ID + one-line reason), so a future audit doesn't re-flag them; anything that is really a *decision* (structural recommendations, major bumps) surfaces for `/decide-nt`. Archive.
- **Lab campaign** — `plan/lab/<slug>/` (from `/lab-nt`). → fold each leg report that no derived item and no `## Log` line cites yet: apply its `## Impact` lines, then append a Log line tagged `[from: <date>-leg]` so the next replan skips it. Leave the folder in place, never archive it; `/lab-nt` resumes from it.
- **Canonical output** — `pending.md`, `workplan.md`, `history.md` → rewritten this run; `standing.md` → answers only (Step 4.7).
- **Named design / intentional artifact** — anything with a meaningful name: `feature-x-design.md`, `<milestone>-breakdown.md`, `pending-from-<source>.md`, charters, spec drafts. → **leave untouched**

From every record you fold, apply each `## Impact` line not yet reflected in the derived files. A status flip the recorder already made (W3) needs nothing, and neither does a `<date>-summary`'s Impact (windup applied it). Print the classification and proceed without waiting. Unsure whether a file is named design or unnamed scratch → treat it as named, leave it untouched, and list it under `Preserved` in the Step 7 summary.

## Step 2: Rewrite history.md

Merge existing `plan/history.md` (if present) with the summaries and scratch being folded in. Final shape:

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
- Carry existing `## Log` entries through verbatim; the Log is a record (MEMORY.md §1). Newest entries first.
- Pull existing Decisions and Dead ends forward; never overwrite blindly.
- Lift the summaries' decisions and dead ends into the top-level Decisions and Dead ends sections, so they're findable.

## Step 3: Restructure pending.md

Rewrite `plan/pending.md` from existing `pending.md` plus the open and deferred items of every record folded in Step 1:

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

Existing items by judgment: actionable → `Now`, deferred but not abandoned → `Parked`, unanswered → `Open questions`. Anything genuinely unclear stays in `Now` and is flagged in the Step 7 summary.

## Step 4: Refresh workplan.md

Regenerate `plan/workplan.md` from the new pending `Now`, in the shape `/windup-nt` produces: each chunk gets a short title, 2–5 items from Now, and a rough size estimate ("30 min", "half day", "1–2 hours"). Items that don't yet cluster go under `## Unbatched`.

**Preserve in-flight chunks:** if a chunk in the existing workplan still has all its items in pending Now, copy it through verbatim. The user may be mid-execution.

## Step 4.5: Replay check

Before archiving anything, run the mechanical check rather than judging by reading:

```bash
python3 "$SKILL/bin/plancheck.py" .                  # $SKILL: this skill's base directory, printed at load
python3 ~/.claude/skills/replan-nt/bin/plancheck.py . # installed path
```

It compares provenance tags, quoted tags and `## Impact` declarations against the records ([`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) §5). Four findings:

- **orphan** — a derived item whose `[from:]` names a record that does not exist.
- **ghost** — a record declaring an `add` impact that no derived item cites.
- **misquote** — a quoted tag whose words are not in the record it names.
- **untagged** — an item with no provenance. Info, never failure.

If the script is not available, fall back to reading: replay the rebuilt `## Decisions` + `## Log` in order and ask of each item now in `pending.md` whether the log explains how it got there. Say which mode you used.

**Don't fix silently.** Report the result in the Step 7 summary (`Replay: clean` or `Replay: N orphans / M ghosts / K misquotes — <one line each>`) and fold the obvious ones back: an orphan gets a dated log line, a ghost gets parked or explicitly closed, a misquote gets its item reworded to what the record says (or its quote corrected, if the item was right and the quote careless).

## Step 4.6: Tag provenance

Every item you wrote into `pending.md` or `workplan.md` this run carries a trailing tag naming its record:

```markdown
- [ ] Fix the nil deref in parser  [from: forward-pass-2026-09-06#F3]
- Preload the session on login  [from: soc:2026-09-08T14:32]
- Ask legal about retention  [from: hand]
```

Grammar: `[from: <record-slug>]`, `[from: <report>#<finding-id>]`, `[from: soc:<timestamp>]`, or `[from: hand]`. **Quote when you can:** add the record's own words after the source, `[from: 2026-09-10-summary "parked until usage passes 10k rows"]`, a few words to one sentence, copied exactly, no `]` or `"` inside (MEMORY.md §4). Carry existing tags through untouched. **Leave pre-existing untagged items alone**: untagged means hand-written, and a back-filled tag you cannot source is invented provenance.

## Step 4.7: Refresh standing questions

Only if `plan/standing.md` exists ([MEMORY.md §7](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#7-standing-questions)). For each `##` question, rewrite the bullets under it from the records you just folded plus the canonical files: every bullet tagged, quoted where the record has the words, `- none  [from: <record>]` when the records show nothing. **Never add, remove, reorder or reword a question**; questions are the human's. Re-run `plancheck` if Step 4.5 ran before this step. No `standing.md` → skip silently; never create one.

## Step 5: Archive source files

Move (never copy or delete) every file Step 1 marked archive into `plan/_archive/`, keeping filenames (`soc.md` renamed as Step 1 says). Move a file only after its items have landed per Steps 2–4.

## Step 6: Verify gitignore

Check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives) (`git check-ignore -q plan`; add `/plan`, no trailing slash). `_archive/` inherits it.

## Step 7: Print summary

Final message in this shape:

```
Replanned <project-name>.

Folded into history.md: <N> daily summaries, <M> scratch files
pending.md: <X> Now / <Y> Parked / <Z> Open questions
workplan.md: <N> chunks, top chunk = "<title>"
[if standing.md exists:] standing.md: <N> questions refreshed
Archived to plan/_archive/: <count> files
Replay: <clean | N orphans / M ghosts / K misquotes — one line each>

Preserved untouched: <list of named design docs, or "none">
```
