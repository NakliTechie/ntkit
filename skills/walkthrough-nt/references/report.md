## Phase 5 — Report + handoff

**Write `plan/walkthrough-YYYY-MM-DD.md`** — a self-contained record, in this order:

> Plain teammate language throughout — concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.
1. **Header** — date, scope (roles × journeys covered), counts: *found / fixed / deferred*, the `Reviewer:` line (this run's model · prior run's model + date, per the rotation rule above).
2. **Role inventory + coverage map** — each role, the journeys walked, and — crucially — **what was NOT reached**: roles you couldn't authenticate, flows you couldn't drive (payment, email, native dialogs), states you couldn't reach. The blind spots.
3. **Issues** by ID, grouped Critical → High → Medium → Low — each: role · journey step · symptom · root cause · then either **FIXED: `path:line` + verification evidence** or **DEFERRED: why + what unblocks** (`→ /decide-nt`).
4. **Cross-role / authz findings** — privilege leaks and guards that held.
5. **Verification reality** — what the browser could and couldn't exercise this run, and what was stubbed.
6. **Progress log** — seed one dated entry: `- YYYY-MM-DD: walkthrough complete — N roles, M journeys; X fixed, Y deferred.`

Create `plan/` if missing and ensure it's gitignored. If today's report already exists, suffix `-2`. **Don't overwrite the canonical `workplan.md`** — this report carries its own deferred items; `/replan-nt` folds them into `pending.md` / `workplan.md`.

**Print to chat:** the counts, the issues grouped *fixed* vs. *deferred* (with one-line evidence each), and the coverage map's blind spots. Keep the full detail in the file.

The fixes are **committed locally, unpushed**. End by naming what changed (with SHAs), what's deferred (and why), and that `/windup-nt` pushes when the user is ready.
