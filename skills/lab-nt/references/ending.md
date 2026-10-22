# Phases 2–4: how a leg ends, re-arm, and the leg report

## Phase 2 — How a leg ends

First exit wins, named in the leg report:
- **GOAL-MET** — the threshold holds on a clean re-measure from the branch tip, with every gate passing **and** on the confirmation set, read once now, output cited. Never on self-report. A confirmation miss is a finding (the loop fit its own eval), reported as BUDGET or STAGNANT, not GOAL-MET.
- **BUDGET** — clock, experiment, or usd cap reached (`spend` exit 3); best-so-far is already committed.
- **STAGNANT** — the stagnation threshold or two "diminishing" verdicts; include the best hypothesis why.
- **DRY-WELL** — nothing left inside the fence; report what widening it would mean and park the decision.
- **PARKED** — a judgment call, a stop-line, or three consecutive experiments failing for the same infrastructure reason. Park and end; never idle-wait.

Record the exit with `python3 $SKILL/bin/lab.py end <dir> <STATE>` before writing the report; the next `leg` reads it. A child campaign ends the same way and returns to its parent (`references/loop.md`); its end state never ends the parent's leg.

## Phase 3 — Re-arm

- Every next leg is started by the user with `/lab-nt resume` after reading the leg report. Its `Re-arm` line recommends CONTINUE (what to try) or STOP (why), and says whether the gap is worth chasing: the distance to the goal measured in noise floors, and, when the last kept gains sat near the floor, how many more items or repeats would separate them (or that the gap is too small to chase with volume).
- A resumed leg starts with `python3 $SKILL/bin/lab.py leg plan/lab/<slug> --experiments <n>`, which enforces the rest of this list: it re-checks every locked hash, resets the experiment counter, records the new start commit, and refuses a child or fork.
- A locked file that changed between legs refuses the leg (PARKED for the human).
- Resuming a STAGNANT or DRY-WELL campaign with `contract.md` unchanged is refused; say what would have to change (fence, budget, or a new hypothesis from the human).
- Odometer exhausted (`--max-legs`, default 5) ⇒ RETIRED, regardless of trend; extending it is a `/decide-nt` entry.

## Phase 4 — The leg report

Tear down first. Stop or delete every outside resource this leg created (cloud instances, endpoints, volumes, tunnels, scheduled jobs, fork and child worktrees) unless the contract keeps it; never touch one the leg found running. Secrets and anything published are listed, not deleted. Then audit the trail: every kept experiment maps to a commit, every number to a harness output, every revert is in the story, and `python3 $SKILL/bin/lab.py check plan/lab/<slug>` (diffing against the leg's start) exits 0 on the best-so-far. Write `plan/lab/<slug>/<date>-leg.md`:

```
Lab ran <slug> — leg <n> of <odometer>, <duration>, branch lab/<slug>, depth <d>.

Ended:        <GOAL-MET | BUDGET | STAGNANT | DRY-WELL | PARKED> — <one line why>
Metric:       <start of leg> → <best>   (goal: <threshold | open-ended>; noise floor ±<spread>)
Best-so-far:  <SHA> — <re-measured clean, gates passing: harness output cited>
Confirmation: <score on the confirmation set, read once | not read (no GOAL-MET) | none (scalar metric)>
Spend:        <experiments used of budget> · <usd used of cap | no paid calls>

Kept (survived measurement):
  - <id> — <metric delta> — <SHA>
Reverted (tried, honest, didn't hold):
  - <id> — <what the number said>
Forks:        <fork point → winning fork or "tip kept">            [or "off" / "leg too short"]
Children:     <c<n> — question — end state — best — merged or reverted>   [or "none"]
Merged:       <meta auto-merge SHA + revert command>                [or "none"]
Critic said:  <verdicts, incl. anything flagged>        [or "no cadence point reached"]

What stays:   <each surviving outside resource + the command that removes it | none>
Needs you:    <parked decisions · fence question · the stagnation hypothesis>
Re-arm:       <CONTINUE — try <next> | STOP — <why> | RETIRED (odometer)>
Resume: /lab-nt resume <slug>   ·   Promote a finding: /capture-nt plan/lab/<slug>/<date>-leg.md
```

Finish with `/notify-nt "<slug>: lab leg <n> — <state>, best <delta>"`. `/resume-nt` reads leg reports like autopilot reports.

## Impact declaration

`plan/lab/<slug>/<date>-leg.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
