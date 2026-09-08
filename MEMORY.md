# The plan/ memory contract

`STATES.md` says *when* a command may run. This file says *what `plan/` means* and
*who may write which part of it*. Both are about keeping the folder honest; that one
governs the session, this one governs the memory.

The problem it solves is drift: an agent edits `pending.md`, another edits
`workplan.md`, a third writes a report, and after four sessions nobody — human or
machine — can say why an item is on the list or where it went. `/replan-nt` catches
that at fold time by reading everything and judging. This file makes most of it
checkable instead.

## 1. Two kinds of file

Every file under `plan/` is exactly one of two kinds. The distinction is the whole
contract; everything else follows from it.

| Kind | Files | Rule |
|---|---|---|
| **Record** | `soc.md` · `<type>-<date>.md` reports · `<date>-summary.md` · `lab/<slug>/journal.md` · `history.md` `## Log` · `_archive/` | Append-only. Once written, an entry is never edited or deleted. A dead end is recorded exactly like a success. |
| **Derived** | `pending.md` · `workplan.md` · `history.md` `## Decisions` · `history.md` `## Dead ends` | A projection over the record. Rewritten wholesale by the reconcile pass, and by nothing else. |

`history.md` is deliberately hybrid: its `## Log` is the record, its `## Decisions` and
`## Dead ends` are curated indexes *over* that log. Naming the split is enough; the file
does not need to be split.

**Nothing exists only in a derived file.** If a fact is in `pending.md`, some record
entry put it there. A derived file can be deleted and rebuilt from the records; that is
the test of whether this contract is being kept.

## 2. Who may write — the writer rule

**W1 — The human writes anywhere.** These rules bind *agent-authored* writes. A person
editing `pending.md` by hand is always legal and always wins. `/decide-nt` and `/soc-nt`
are the human speaking through a command, so their appends are human writes.

**W2 — An agent may append to a record. Never edit one.** Rewriting a past record entry
is the one thing that makes the log untrustworthy.

**W3 — An agent may flip the status of an item that already exists in a derived file,**
and append an evidence pointer to that item. `[ ] → [x]`, `[ ] → [~]`, plus the row
saying how it was verified. Status is the item's own lifecycle and belongs to whoever
did the work — this is also what lets progress survive a crash mid-run.

**W4 — Only the reconcile pass may add, remove, re-rank, or re-word a derived item.**
That is `/replan-nt`, `/windup-nt`'s implicit replan, and `/scaffold-nt` at seeding.
Three writers, ever.

**W5 — An agent handed a goal records it; it does not author its own checklist.**
A prose goal becomes a **record** — a dated goal entry — and the reconcile pass turns
that into workplan items. An agent that writes its own criteria and then ticks them off
has graded its own exam: it can meet the criteria by editing them. This is W4 applied to
the case that matters most, and it is why it is stated separately.

## 3. Declared impact

Every agent-written **record** file ends with an `## Impact` section saying what it
claims should change in the derived files — or explicitly that nothing should.

```markdown
## Impact
- pending.md/Now — add: review the auth refactor branch before it goes stale
- workplan.md/B2#3 — status: [ ] → [x], verified by `npm test -- auth.spec.js` exit 0
- history.md/Dead ends — add: F7 was a false positive, the guard already covers it
```

or, when a unit genuinely changes nothing:

```markdown
## Impact
- none — investigation only; the finding was already recorded in F3
```

Declaring the impact is the **recording** agent's job. Applying it is the reconcile
pass's job. They are different acts by different writers, and keeping them apart is
what makes W4 enforceable.

**Exempt:** `soc.md`. Its contract is *capture, don't process* — asking for an impact
declaration mid-flow would defeat the one thing it is for. `/replan-nt` triages the
stream instead.

## 4. Provenance

A derived item may carry a trailing provenance tag naming the record it came from:

```markdown
- [ ] Review/merge autopilot/2026-09-08  [from: 2026-09-08-autopilot]
- [x] Trigram index landed  [from: 2026-09-07-summary]
- Preload the session on login  [from: soc:2026-09-08T14:32]
- Ask legal about the data-retention line  [from: hand]
```

Tag grammar: `[from: <record-slug>]`, `[from: <report>#<finding-id>]`,
`[from: soc:<timestamp>]`, or `[from: hand]` for anything a person wrote directly.

**An untagged item means `hand`.** Every `plan/` folder written before this contract
existed is therefore already valid — provenance is additive, never a migration.

Provenance is what turns the replay check from a reading comprehension task into a set
comparison. Without it, finding an orphan means re-reading the whole log; with it, an
orphan is a tag that resolves to nothing.

## 5. The check

`bin/plancheck.py` reads a `plan/` folder and reports divergence between the records and
the derived files. It is mechanical, it never calls a model, and it never edits anything.

| Finding | Meaning |
|---|---|
| **orphan** | A derived item whose `[from:]` names a record that does not exist. State arrived from nowhere. |
| **ghost** | A record `## Impact` line whose target has no matching derived item. Work was done and silently dropped. |
| **untagged** | A derived item with no provenance tag. Reported as info, never as failure — this is the legacy case and the hand-written case. |

```
plancheck            # exit 0 clean · 1 divergence found · 2 could not run
plancheck --since 2026-09-01    # only records and items dated on or after
plancheck --json                # machine-readable, for a skill to read
```

`/replan-nt` runs it at Step 4.5 in place of judging by reading. A divergence is
**reported, never silently fixed** — an orphan gets a log line, a ghost gets parked or
explicitly closed, and both decisions are visible.

Per `SUBSTANCE.md`: the check is a real gate, not process theater. It exists because
"the plan and the log agree" is exactly the kind of claim that is easy to assert and
tedious to verify, which is what a checker is for.

## 6. What this does not do

- **It does not make the fold deterministic.** The reconcile pass is still an agent
  reading records and writing a projection. `plancheck` can prove a claimed impact
  landed somewhere; it cannot prove the wording is faithful. Spot-check by deleting a
  derived file and rebuilding it from the records — if the two differ in substance,
  either provenance is incomplete or the fold invented something.
- **It does not lock the folder.** Any rule here can be overridden the way
  `STATES.md` §Guards allows: on purpose, through `/decide-nt`, with the reason
  written down. A rule bypassed by drift is a bug; bypassed deliberately is a decision.
- **It does not add a daemon, a database, or a format.** `plan/` stays plain markdown a
  person can read and edit. Everything above is a convention plus one script.
