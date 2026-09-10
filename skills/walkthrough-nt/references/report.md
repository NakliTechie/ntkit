## Phase 7 — Report + handoff

**Write `plan/walkthrough-YYYY-MM-DD.md`** — a self-contained record, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.
1. **Header** — date, scope (roles × journeys covered), counts: *found / fixed / deferred*, the **invariant set that was armed** (the floor four plus anything repo-specific), and the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule above).
2. **Role inventory + coverage map** — each role, the journeys walked, and — crucially — **what was NOT reached**: roles you couldn't authenticate, flows you couldn't drive (payment, email, native dialogs), states you couldn't reach. The blind spots.
3. **Issues** by ID, grouped Critical → High → Medium → Low — each: role · journey step · symptom · root cause · **which action index in the log it replays from** · then either **FIXED: `path:line` + verification evidence** or **DEFERRED: why + what unblocks** (`→ /decide-nt`). Mark which came from the scripted walk and which from the chaos leg — the split is how a reader judges whether the journeys or the fuzzing are carrying the run.
3b. **Chaos leg** — the budget spent (actions and minutes, per role), what it yielded, and the **unreproduced** list: breaches that fired once and did not replay, each with its action prefix. Unreproduced entries are leads and are counted separately from findings, never folded into the totals. If the leg was skipped, the reason goes here.
4. **Cross-role / authz findings** — privilege leaks and guards that held.
5. **Verification reality** — what the browser could and couldn't exercise this run, and what was stubbed.
6. **Progress log** — seed one dated entry: `- YYYY-MM-DD: walkthrough complete — N roles, M journeys; X fixed, Y deferred; chaos N actions, Z found.`

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. **Don't overwrite the canonical `workplan.md`** — this report carries its own deferred items; `/replan-nt` folds them into `pending.md` / `workplan.md`.

**Hand back the recording, not just the report.** `plan/walkthrough-<date>-run/` holds the video and the action log. Send the recording to the user with `SendUserFile` — for a reader who doesn't read diffs, watching the walk is a strictly better artifact than a markdown summary of it, and the step narrative's timestamps are what make it navigable. Say plainly whether it is a real recording or a screenshot contact sheet.

**When `SendUserFile` is unavailable** (a subagent, a non-interactive run), print the absolute path to the run directory and to the mapping artifact instead, so the handback is one copy-paste from being watchable. The exit condition is the handback, not the tool.

**Print to chat:** the counts, the issues grouped *fixed* vs. *deferred* (with one-line evidence each), the chaos budget and yield, and the coverage map's blind spots. Keep the full detail in the file.

The fixes are **committed locally, unpushed**. End by naming what changed (with SHAs), what's deferred (and why), and that `/windup-nt` pushes when the user is ready.
