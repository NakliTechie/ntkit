# Phases 2 and 7: stop and close

## run.md

`$RUN/run.md` is the run's status page over its record files (`spec.md`, `sections/`,
`fetch-log.jsonl`, `verify.json`). Rewrite it whole at every state change, with one rule: keep every
earlier `## Log` line and append one. Line 3 is always `State: <STATE>`; `status` and the `go` guard
read it. Times come from `date '+%Y-%m-%d %H:%M %Z'`.

```markdown
# Research run: <slug>

State: <SPEC-READY | VERIFIED | PASSED-WITH-NOTES | FLAGGED | BUDGET | BLOCKED>
Question: <question, verbatim>
Layer: L5 (three planners, critic, editor, claim check)
Models: <actual models per role; name any host substitutions>
Updated: <time>

## Summary
<one to three sentences: what this state means, in numbers>

## Units
| Unit | Title | Status |
|---|---|---|
| S1.1 | <title> | <planned · passes check · failed check · missing> |

## Plan review
<each HP and its accepted unit or rejection reason, from revision.md>

## Gates
<final states only: the G1, G2, G2b, G4, G3 lines from `check.py gates`, with each problem>

## Most-cited sources
<final states only: the first 5 entries of verify.json `sources`, as `1. <title or url> — <url> (<n> citations)`>

## Next
<the one command or decision that moves this run forward>

## Log
- <time> · <STATE> · <one line>

## Impact
- none — a research run changes no derived plan file
```

The Summary counts come from tool output, never from reading page text: `check.py spec` for the
plan, `check.py section` per unit, `check.py gates` and `verify.json` for the result.

## Phase 2: the stop (SPEC-READY)

Skip this phase with `--go`.

1. Write `run.md` with `State: SPEC-READY`. Summary: the `check.py spec` line, and the vault result
   from `vault.md` (notes used, nothing relevant, or skipped and why). Units table: every unit,
   status `planned`. Next: `Read spec.md. Edit units, required entities or ## Run settings if
   needed, then run /research-nt go <slug>.`
2. `/notify-nt "<slug>: research spec ready, <n> units. /research-nt go <slug>"`.
3. Tell the user: the spec path, the unit table with each unit's research questions (from
   `spec.md`), and every HP outcome, and the `go` command. End the turn. Do not start Phase 3.

## Phase 7: close

1. Write `run.md` with the end state. Summary: units researched, sections passing their check,
   report words (`wc -w $RUN/report.md`), fetches (`wc -l $RUN/fetch-log.jsonl`) and the page store
   path. Record actual agent runs, elapsed time, report length and available token usage; unknown cost stays unknown. Gates: the lines `check.py gates` printed, including supported/partial/unsupported counts and any repair review outcome. Most-cited sources: from `verify.json`. Next:
   - VERIFIED: `Read report.md. Capture a source with /capture-nt <url>.`
   - PASSED-WITH-NOTES: the advisory notes (which entity G2b found missing), that blocking gates pass,
     and that the report is not VERIFIED. Then the VERIFIED next step.
   - FLAGGED: which blocking gate failed, and that the report is not verified.
   - BLOCKED: what failed, from the researchers' `BLOCKED` lines.
2. `/notify-nt "<slug>: research <STATE>, <n> units, <words> words"`.
3. Tell the user: the state, the gate table, the report path and the 5 most-cited sources. Offer
   `/capture-nt` for any of them. Do not run it.

## status

For each `plan/research/*/run.md`, print the slug, its `State:` line and its `Question:` line. Read
nothing else. Write nothing.
