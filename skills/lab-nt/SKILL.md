---
description: "Turn a research idea into a contract, then run bounded experiment legs in a worktree."
argument-hint: "[idea/question, e.g. \"can QAT recover fp16 quality at int4 in-browser\" | resume | status]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task", "WebSearch", "WebFetch"]
entry: "an idea in $ARGUMENTS or the conversation, or an open campaign in plan/lab/ to resume; never re-armed at an unchanged wall"
exit: "leg ended GOAL-MET (verified) | BUDGET | STAGNANT | DRY-WELL | PARKED, with journal + leg report written; never a silent end"
writes: "its own worktree, plan/lab/<slug>/ (contract.md, journal.md, <date>-leg.md)"
---

`/lab-nt` is the kit's discoverer. `/forward-pass-nt` finds what's wrong, `/autopilot-nt` executes what's planned — this one answers what isn't *known* yet. It takes a research idea, shapes it with the user into a contract with a falsifiable finish line, then runs the loop Karpathy's `autoresearch` proved out: smallest experiment → measure → keep or revert → journal → next. It is `/autopilot-nt`'s close cousin — same worktree isolation, same stop-lines, same "done is the verifier's word" — but where autopilot works a *known* queue to completion, lab works an *unknown* space under a budget, and the honest exit is often "best so far," not "finished."

**Research is an anytime algorithm.** No working system — Karpathy's autoresearch, Google's co-scientist, the Deep Research products — stops on "convergence"; they stop on budget, sufficiency, or a human, with the best-known result always already persisted. `/lab-nt` adopts that posture wholesale: the campaign may be unbounded, but every *leg* is bounded, every stop point is cheap (the journal and the best-so-far commit are always current), and continuation is earned, never assumed.

**Scope: experiment mode only.** The goal must reduce to a scalar a harness can read. Work with the user to find a real proxy metric; if none exists, decline the launch and say so — metric-less research belongs in a live session, not an unattended loop.

`$ARGUMENTS`: an **idea/question** in prose (starts Phase 0), **resume** (continue the newest open campaign in `plan/lab/` — or the named one, `resume <slug>` — skipping Phase 0), or **status** (read-only: list campaigns with leg count, best-so-far, and end-state — the standup view).

## Phase 0 — Shape the idea into a research contract (the interactive phase)

This is where lab differs most from autopilot. Autopilot's Phase 0 is a veto window — state and go. Lab's Phase 0 is a genuine working conversation: iterate on the idea with the user until it survives four gates, then write `plan/lab/<slug>/contract.md`. Never launch a loop on a mushy goal — **unfalsifiable goals are where infinite runs come from.**

1. **The question** — one sentence, sharpened together. "Explore X" fails; "can X do Y under constraint Z" passes.
2. **The metric — the falsifiability gate.** A single scalar the harness reads — a benchmark score, a test count, a wall-clock, a bpb, a bundle size. Three rules from the systems that work: pick it *before* the loop starts, pick it fair across interventions (Karpathy chose val_bpb because it's vocab-size-independent), and the loop reads it from the run's output — never from its own prose. State the **goal threshold** (GOAL-MET when the metric crosses it) or declare the campaign open-ended hill-climbing (then only BUDGET/STAGNANT/DRY-WELL end it — say that out loud so the user chooses it knowingly).
3. **The scope fence** — what the loop may touch (Karpathy's whole design is "the agent edits exactly one file") and the explicit non-goals. Small surface = reviewable diffs = a trustworthy morning read. The fence is also the dry-well detector's denominator: "nothing left to try" is only meaningful inside a stated fence.
4. **The budget ladder** — three granularities, all first-class:
   - **per-experiment**: hard cap on one attempt (e.g. 5 min of training, one build+bench cycle, 10 fetches) — the fairness mechanism and the runaway brake;
   - **per-leg**: one run of this command (default: 4 hours or 25 experiments, whichever first) — the session budget;
   - **per-campaign — the odometer**: across all legs (default: 5 legs). Exhausted ⇒ RETIRED regardless of trend; extendable only by a logged `/decide-nt`.

Also settled here, stated not asked (veto-window style, per the STATES.md ask rule): the **critic cadence** (default: every 5 experiments), the **stagnation threshold** (default: 8 consecutive experiments without improvement ends the leg STAGNANT), and the **prior-art check** — before any experiment runs, sweep the vault (`/ask-nt`), the repo and its `plan/`, and the web for existing answers; a question already answered ends the campaign at leg zero, GOAL-MET by citation, and that's the cheapest win the command can deliver.

## Phase 0.5 — Isolate and instrument

- **Worktree, exactly as autopilot**: `git worktree add .worktrees/lab-<slug> -b lab/<slug>` (gitignore `.worktrees/`, symlink `plan/` from the main checkout, rebuild what doesn't travel). All experiment commits land on `lab/<slug>`; the user's checkout is never touched.
- **The measurement lockbox.** The harness — the runner script, the metric extraction, the contract — lives outside the loop's writable scope (own directory, named in the contract). Sakana's AI Scientist edited its own runner to extend its timeout rather than speed up its code; the defense is structural, not behavioral. The loop edits the experiment surface only, and **a change may never modify the thing that measures it** — autopilot's test rule, promoted to the whole harness. If the harness itself is wrong, that's a PARKED item for the human, not an edit.
- **The journal**: `plan/lab/<slug>/journal.md`, append-only, one row per experiment — `id · hypothesis · what ran · result (the harness's number, verbatim) · keep/revert · what it opened up`. Re-read at the top of every iteration; with the git history it *is* the lab notebook, the anti-circling device, and the cross-leg memory. Context dies between legs; files don't.

## Phase 1 — The leg loop

For each iteration:
1. **Pick** the smallest experiment that could move the metric. Re-read contract + journal first — the contract re-read is the goal-drift anchor; the journal read is the dedup source.
2. **Dedup** — if the journal already holds this attempt or a trivial variant, don't run it; pick again. Two consecutive dedup rejections with nothing genuinely new inside the fence = **DRY-WELL**; end the leg.
3. **Run** inside the per-experiment budget. A blown budget is a failed experiment, recorded as such — never extended, never retried "with a bit more time."
4. **Measure** — the harness's number goes in the journal verbatim. The loop's opinion of its own result is not data.
5. **Keep or revert** — improvement commits (`lab <id>: <what> — <metric old → new>`), regression or no-change reverts clean (`git restore` / reset). The branch tip is always the best-known state — that invariant is what makes any stop point safe and any interruption lossless.
6. **Journal** the row; next iteration. No pause between experiments — the budgets and thresholds are the exits, not the user's attention.

**Fold, don't be compacted.** Once an experiment is journaled and committed/reverted, its working detail lives in the journal row + git — reference it, don't carry it. The loop runs from contract + journal + branch tip (that's why step 1 re-reads them), never from conversational recall of earlier experiments. At each **critic-cadence point**, fold deliberately: confirm the journal is current enough that the leg could resume from files alone, then drop finished-experiment detail from working context. Context management at chosen seams beats the harness's automatic compaction firing mid-experiment; discard only what a journal or git re-read can recover.

**Critic on cadence, not inline.** Every N experiments (contract cadence), spawn a fresh-eyes subagent (Task) whose context is *only* the contract and the journal — not the loop's reasoning — to answer four questions: circling? drifting off-contract? gaming the metric? diminishing returns? Its verdict is a journal row. Two consecutive "diminishing" verdicts end the leg early (honest STAGNANT beats a ground-out BUDGET). One critic pass per cadence point — iterated self-critique without new information degrades; the cap is structural.

## Phase 2 — How a leg ends (never silently)

First exit wins; each is a named state in the leg report:
- **GOAL-MET** — the threshold holds *and the harness says so*: re-run the measurement clean from the branch tip, cite the output. Never on the loop's self-report.
- **BUDGET** — the leg's clock or experiment cap is exhausted. Anytime posture: report best-so-far, which is already committed. Not a failure; the normal end of a night.
- **STAGNANT** — the stagnation threshold hit, or two consecutive critic "diminishing" verdicts. The report includes the loop's best hypothesis *why* — that hypothesis is the first thing the next human conversation examines.
- **DRY-WELL** — nothing left to try inside the scope fence. The fence is the finding: report what widening it would mean, and park the decision.
- **PARKED** — a wall needing a human: a real judgment call, a stop-line, or a systemic failure (three consecutive experiments failing for the same *infrastructure* reason — the harness or environment is sick, not the hypotheses — autopilot's systemic-halt rule). Park and end; never idle-wait.

## Phase 3 — Stop-lines

Everything in autopilot's Phase 4 (no publishing, sending, deleting, credentials, money, destructive infra — park, don't perform), plus the lab-specific three:
- **Never modify the harness, the contract, or the journal's past rows.** Append-only memory, read-only measurement.
- **Never spend outside the ladder** — no new paid API, no bigger instance, no self-granted "one more hour." A budget the loop can raise is not a budget.
- **Never self-arm the next leg.** A leg may end; only a human starts another. This is the anti-infinity stop-line: momentum is never a reason to continue.

## Phase 4 — Re-arm: how "continue till goal is met" stays finite

The campaign continues leg-to-leg under one rule — **progress or a human, never momentum**:
- Every next leg is launched by the user — `/lab-nt resume` after reading the leg report. The report's `Re-arm` line states the recommendation (CONTINUE with what to try next / STOP with why), but the arming hand is human.
- Resuming at an **unchanged wall** is illegal, same as autopilot: a STAGNANT or DRY-WELL campaign resumed with no change to the contract (new fence, new budget, new hypothesis from the human) will grind the same ground — refuse, and say what would have to change.
- **Odometer exhausted ⇒ RETIRED** regardless of trend. Reversible — extend it — but only deliberately, on the record, via `/decide-nt`.
- Every leg is **human-armed** — the loop never schedules or re-arms its own next leg.

## Phase 5 — The leg report

Same discipline as autopilot's morning report — **audit the trail before you write it**: every kept experiment maps to a commit, every number to a harness output, every revert is in the story. Fix the report, not the story. Write `plan/lab/<slug>/<date>-leg.md`:

```
Lab ran <slug> — leg <n> of <odometer>, <duration>, branch lab/<slug>.

Ended:        <GOAL-MET | BUDGET | STAGNANT | DRY-WELL | PARKED> — <one line why>
Metric:       <start of leg> → <best>   (goal: <threshold | open-ended>)
Best-so-far:  <SHA> — <re-measured clean: harness output cited>

Kept (survived measurement):
  - <id> — <metric delta> — <SHA>
Reverted (tried, honest, didn't hold):
  - <id> — <what the number said>
Critic said:  <verdicts, incl. anything flagged>        [or "no cadence point reached"]

Needs you:    <parked decisions · fence question · the stagnation hypothesis>
Re-arm:       <CONTINUE — try <next> | STOP — <why> | RETIRED (odometer)>
Resume: /lab-nt resume <slug>   ·   Promote a finding: /capture-nt plan/lab/<slug>/<date>-leg.md
```

Finish with `/notify-nt "<slug>: lab leg <n> — <state>, best <delta>"` — degrades silently if unconfigured. `/resume-nt` reads leg reports like it reads autopilot reports; `/standup-nt` surfaces open campaigns; a GOAL-MET (or an interestingly-STAGNANT) finding promotes to the knowledge vault via `/capture-nt` — the lab's output feeds the second brain, and the vault's prior art feeds the next Phase 0.

## Impact declaration

`plan/lab/<slug>/<date>-leg.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- workplan.md/B2#3 — status: [ ] → [x], verified by <the check that proves it>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. Do not write the item into `pending.md` or `workplan.md` yourself — a record that declares its impact and a reconcile pass that folds it are what keep the plan rebuildable from the log. An `add` line with nothing later citing this record is a **ghost**, and `plancheck` reports it.
