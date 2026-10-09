---
description: "Turn a research idea into a contract, then run bounded experiment legs in a worktree."
argument-hint: "[idea/question, e.g. \"can QAT recover fp16 quality at int4 in-browser\" | resume | status]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Agent", "WebSearch", "WebFetch"]
entry: "an idea in $ARGUMENTS or the conversation, or an open campaign in plan/lab/ to resume; never re-armed at an unchanged wall"
exit: "leg ended GOAL-MET (verified) | BUDGET | STAGNANT | DRY-WELL | PARKED, with journal + leg report written; never a silent end"
writes: "its own worktree, plan/lab/<slug>/ (contract.md, journal.md, <date>-leg.md)"
---

`/lab-nt` answers what isn't known yet. It shapes an idea with the user into a contract with a falsifiable finish line, then runs the `autoresearch` loop: smallest experiment → measure → keep or revert → journal → next. Same worktree isolation and stop-lines as `/autopilot-nt`, but it searches an unknown space under a budget, and the honest exit is often "best so far". Every leg is bounded, the best-so-far is always committed, and continuing is earned, never assumed.

**Experiment mode only.** The goal must reduce to a scalar a harness can read. If no real proxy metric exists, decline the launch and say so.

`$ARGUMENTS`: an **idea** in prose (starts Phase 0) · **resume** (newest open campaign in `plan/lab/`, or `resume <slug>`; skips Phase 0) · **status** (read-only: campaigns with leg count, best-so-far, end-state).

## Phase 0 — The research contract (interactive)

Work the idea with the user until it passes five gates, then write `plan/lab/<slug>/contract.md`. Never launch on a mushy goal; unfalsifiable goals are where infinite runs come from.

1. **Question** — one sentence: "can X do Y under constraint Z", not "explore X".
2. **Metric** — one scalar, chosen before the loop, fair across interventions, and read from the run's output, never the loop's prose. State the **goal threshold** (GOAL-MET when crossed), or declare the campaign open-ended so the user picks that knowingly.
3. **Scope fence** — what the loop may touch, plus explicit non-goals. A small surface keeps diffs reviewable, and "nothing left to try" only means something inside a fence.
4. **Budget ladder** — per-experiment cap (one build+bench cycle, N minutes of training); per-leg (default 4 hours or 25 experiments); per-campaign odometer (default 5 legs; exhausted ⇒ RETIRED, extendable only via `/decide-nt`).
5. **Noise floor** — before the first experiment, re-measure the unchanged baseline three times (or bootstrap its eval items) and write the spread into the contract. A gain inside the spread is noise: a +0.6 point move with a ±6 point interval is no result. When the metric is computed over a dataset, also split off a **confirmation set** the loop never reads; it joins the lockbox.

State these defaults rather than asking: critic every 5 experiments; 8 consecutive experiments without improvement ⇒ STAGNANT. Run the **prior-art check** before any experiment: the vault first (`/ask-nt`, when scholia is installed), then the repo and its `plan/`, then the web. A question already answered ends the campaign at leg zero, GOAL-MET by citation.

## Phase 0.5 — Isolate and instrument

- **Worktree:** `git worktree add .worktrees/lab-<slug> -b lab/<slug>` (ignore `.worktrees/` via `.git/info/exclude`), `plan/` symlinked from the main checkout, rebuild what doesn't travel. All experiment commits land on `lab/<slug>`; the user's checkout is never touched.
- **Measurement lockbox.** The runner, metric extraction and contract live outside the loop's writable scope, named in the contract. A change may never modify what measures it. (Sakana's AI Scientist once raised its own timeout instead of speeding up its code.) A wrong harness is PARKED for the human, not edited.
- **Journal:** `plan/lab/<slug>/journal.md`, append-only, one row per experiment: `id · hypothesis · what ran · result (harness number, verbatim) · keep/revert · what it opened up`.

## Phase 1 — The leg loop

1. **Pick** the smallest experiment that could move the metric, after re-reading contract and journal.
2. **Dedup** against the journal. Two consecutive rejections with nothing new inside the fence ⇒ **DRY-WELL**.
3. **Run** inside the per-experiment cap. A blown cap is a failed experiment, never extended or retried with more time.
4. **Measure** — the harness's number goes in the journal verbatim.
5. **Keep or revert** — a gain larger than the noise floor commits (`lab <id>: <what> — <old → new>`); for a dataset metric, score candidate and best-so-far on the same items and keep only when the paired 95 % interval excludes zero. Anything else reverts clean. The branch tip is always the best-known state.
6. **Journal** the row and go on. Budgets and thresholds are the exits.

Run from contract, journal and branch tip, not from recall of earlier experiments. At each critic point, confirm the journal is current enough to resume the leg from files alone, then fold finished-experiment detail out of context.

**Critic on cadence.** At each critic point, a fresh subagent sees only the contract and the journal and answers four questions: circling? drifting off-contract? gaming the metric? diminishing returns? Its verdict is a journal row. Two consecutive "diminishing" verdicts end the leg STAGNANT. One critic pass per point.

## Phase 2 — How a leg ends

First exit wins, named in the leg report:
- **GOAL-MET** — the threshold holds on a clean re-measure from the branch tip **and** on the confirmation set, read once now, output cited. Never on self-report. A confirmation miss is a finding (the loop fit its own eval), reported as BUDGET or STAGNANT, not GOAL-MET.
- **BUDGET** — clock or experiment cap reached; best-so-far is already committed.
- **STAGNANT** — the stagnation threshold or two "diminishing" verdicts; include the best hypothesis why.
- **DRY-WELL** — nothing left inside the fence; report what widening it would mean and park the decision.
- **PARKED** — a judgment call, a stop-line, or three consecutive experiments failing for the same infrastructure reason. Park and end; never idle-wait.

## Phase 3 — Stop-lines

`/autopilot-nt`'s stop-lines (no publishing, sending, deleting, credentials, money, destructive infra), plus:
- Never modify the harness, the contract, or past journal rows.
- Never spend outside the ladder: no new paid API, no bigger instance, no self-granted extra hour.
- Never arm or schedule the next leg. Only a human starts another.

## Phase 4 — Re-arm

- Every next leg is started by the user with `/lab-nt resume` after reading the leg report. Its `Re-arm` line recommends CONTINUE (what to try) or STOP (why), and says whether the gap is worth chasing: the distance to the goal measured in noise floors, and, when the last kept gains sat near the floor, how many more items or repeats would separate them (or that the gap is too small to chase with volume).
- Resuming a STAGNANT or DRY-WELL campaign with an unchanged contract is refused; say what would have to change (fence, budget, or a new hypothesis from the human).
- Odometer exhausted ⇒ RETIRED, regardless of trend; extending it is a `/decide-nt` entry.

## Phase 5 — The leg report

Tear down first. Stop or delete every outside resource this leg created (cloud instances, endpoints, volumes, tunnels, scheduled jobs) unless the contract keeps it; never touch one the leg found running. Secrets and anything published are listed, not deleted. Then audit the trail: every kept experiment maps to a commit, every number to a harness output, every revert is in the story. Write `plan/lab/<slug>/<date>-leg.md`:

```
Lab ran <slug> — leg <n> of <odometer>, <duration>, branch lab/<slug>.

Ended:        <GOAL-MET | BUDGET | STAGNANT | DRY-WELL | PARKED> — <one line why>
Metric:       <start of leg> → <best>   (goal: <threshold | open-ended>; noise floor ±<spread>)
Best-so-far:  <SHA> — <re-measured clean: harness output cited>
Confirmation: <score on the confirmation set, read once | not read (no GOAL-MET) | none (scalar metric)>

Kept (survived measurement):
  - <id> — <metric delta> — <SHA>
Reverted (tried, honest, didn't hold):
  - <id> — <what the number said>
Critic said:  <verdicts, incl. anything flagged>        [or "no cadence point reached"]

What stays:   <each surviving outside resource + the command that removes it | none>
Needs you:    <parked decisions · fence question · the stagnation hypothesis>
Re-arm:       <CONTINUE — try <next> | STOP — <why> | RETIRED (odometer)>
Resume: /lab-nt resume <slug>   ·   Promote a finding: /capture-nt plan/lab/<slug>/<date>-leg.md
```

Finish with `/notify-nt "<slug>: lab leg <n> — <state>, best <delta>"`. `/resume-nt` reads leg reports like autopilot reports.

## Impact declaration

`plan/lab/<slug>/<date>-leg.md` is a record: append-only. End it with an `## Impact` section, one line per change it implies for `pending.md`, `workplan.md` or `history.md`'s indexes (`- pending.md/Now — add: …`, `- workplan.md/B2#3 — status: [ ] → [x], verified by …`), or `- none — <reason>`. Declare it; never add, drop or reword items in `pending.md` or `workplan.md` yourself (a status flip on an existing item is allowed). `/replan-nt` applies it ([MEMORY.md §3](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#3-declared-impact)).
