## Phase 7 — Report + handoff

**Write `plan/walkthrough-YYYY-MM-DD.md`** per ATTEST, in this order:

1. **Header**: date, scope (roles × journeys covered), counts *found / fixed / deferred*, the **armed invariant set** (the seven floor invariants plus any repo-specific ones), the chaos seed, and the `Reviewer:` line.
2. **Role inventory + coverage map**: each role and the journeys walked, and **what was not reached** (roles you couldn't authenticate, flows you couldn't drive, states you couldn't reach).
3. **Issues** by ID, Critical → High → Medium → Low. Each: role · journey step · symptom · root cause · the action index it replays from · then **FIXED: `path:line` + verification evidence** or **DEFERRED: why + what unblocks** (`→ /decide-nt`). Mark each as scripted walk or chaos leg.
3b. **Chaos leg**: budget spent (actions and minutes, per role), yield, and the **unreproduced** list, each with its action prefix, counted separately from findings. If skipped, the reason.
4. **Cross-role / authz findings**: privilege leaks and guards that held.
5. **Verification reality**: what the browser could and couldn't exercise, and what was stubbed.
6. **Progress log**: one dated entry, `- YYYY-MM-DD: walkthrough complete — N roles, M journeys; X fixed, Y deferred; chaos N actions, Z found.`

Create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`. If today's report exists, suffix `-2`. Don't overwrite `workplan.md`; this report carries its own deferred items.

**Stale captures.** A fix that changes how a surface looks stales committed screenshots and guides. Run the repo's regenerator (`make screens`, `make guide`, a capture script) and commit the result, or name the stale captures and their regenerator in the report. Zero changed files can be correct (gitignored captures, a text-only guide); confirm which case you are in.

**Hand back the recording.** Send it with `SendUserFile` and say whether it is a video or a screenshot contact sheet. Without `SendUserFile` (a subagent, a non-interactive run), print the absolute paths of `plan/walkthrough-<date>-run/` and its `recordings.md`.
