# Phases 2, 4, 5: stop, assemble and gate, close

## run.md

`$RUN/run.md` is the run's status page over its record files (`spec.md`, `sections/`,
`fetch-log.jsonl`, `verify.json`). Rewrite it whole at every state change, with one rule: keep every
earlier `## Log` line and append one. Line 3 is always `State: <STATE>`; `status` and the `go` guard
read it. Times come from `date '+%Y-%m-%d %H:%M %Z'`.

```markdown
# Research run: <slug>

State: <SPEC-READY | VERIFIED | FLAGGED | BUDGET | BLOCKED>
Question: <question, verbatim>
Layer: L1 (one planner; no critic, editor or claim check; G3 skipped)
Updated: <time>

## Summary
<one to three sentences: what this state means, in numbers>

## Units
| Unit | Title | Status |
|---|---|---|
| S1.1 | <title> | <planned · passes check · failed check · missing> |

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
   `spec.md`), and the `go` command. End the turn. Do not start Phase 3.

## Phase 4: assemble and gate

```bash
python3 "$SKILL/bin/check.py" assemble "$RUN"
cp "$RUN/draft.md" "$RUN/report.md"                      # L1 has no editor; G4 requires a byte copy
python3 "$SKILL/bin/check.py" gates "$RUN" --without g3  # writes verify.json
```

- `assemble` exits 1 → a unit has no usable section. The run ends **BUDGET**. The Units table marks
  each unit `passes check`, `failed check` or `missing`. Next: `/research-nt go <slug>` researches
  only the failing units. Skip `cp` and `gates`.
- `gates` exits 0 → **VERIFIED**. Exits 1 → **FLAGGED**. Its exit code is the only verdict. Never
  edit `report.md` to make a gate pass; the only repair pass is Phase 3's.

## Phase 5: close

1. Write `run.md` with the end state. Summary: units researched, sections passing their check,
   report words (`wc -w $RUN/report.md`), fetches (`wc -l $RUN/fetch-log.jsonl`) and the page store
   path. Gates: the lines `check.py gates` printed. Most-cited sources: from `verify.json`. Next:
   - VERIFIED: `Read report.md. Capture a source with /capture-nt <url>.`
   - FLAGGED: which gate failed, and that the report is not verified.
   - BLOCKED: what failed, from the researchers' `BLOCKED` lines.
2. `/notify-nt "<slug>: research <STATE>, <n> units, <words> words"`.
3. Tell the user: the state, the gate table, the report path and the 5 most-cited sources. Offer
   `/capture-nt` for any of them. Do not run it.

## status

For each `plan/research/*/run.md`, print the slug, its `State:` line and its `Question:` line. Read
nothing else. Write nothing.
