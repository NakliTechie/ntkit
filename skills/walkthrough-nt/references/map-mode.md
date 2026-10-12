## Map mode — keep the harness and feature map honest

`/walkthrough-nt map` checks every feature file in `verify/features/` against the code and against the running app, and corrects the map and harness where they have drifted. The unit of rigor is the feature: every feature file gets read from source and driven live, without proving every sentence in it.

**Stop first if there is nothing to check.** No `verify/features/` → say so and point at a full `/walkthrough-nt`, which creates it. Several candidate harnesses → ask which one.

**Edit scope.** Only the harness script, `verify/features/` and their helpers. Never product code. A feature that no longer does what its file says is one of two things: the app changed on purpose (map drift: fix the file) or the app broke (a product regression: record it in the report's Impact section for the next full walkthrough, and leave the file describing the intended behaviour).

### 1. Index

Read `verify/features/README.md` and list its sibling files. Fix missing, extra, duplicate and dead entries.

### 2. Source pass, in parallel

Launch one read-only subagent (Agent) per feature file, all at once. Each reads its feature file and the code, and returns four things: a short summary of how the feature works, the source entry points (`path:line`), likely drift with citations or "none", and one recipe for driving it live. Subagents never run the app and never edit files.

### 3. Reconcile

Check that every feature file got a summary back. Merge the recipes so the live pass needs as few app states as possible. Spot-check each cited drift against the code; do not re-prove the clean ones. Then look at the commits since the map last changed (`git log -- verify/features/` gives the date) for user-facing surfaces the map lacks: new routes, subcommands, menu items. Call one missing only with a concrete source path.

### 4. Live pass

Required even when the source pass found nothing, because the code can read right and still not run. You drive; subagents do not. Follow the harness's own launch model: one long-lived instance driven serially for a browser app or service, a fresh session per drive for a CLI or TUI. Drive every feature at least once, through `verify <feature>` where it exists. Hold three rules for the whole pass:

1. **Never drive an instance you have not checked since it last surprised you.** Run `doctor` before the first drive, on each fresh session, and after any failed drive. When the failure is one `doctor` cannot see (a wedged dialog on a healthy process), reset to the seed or relaunch.
2. **Evidence survives every teardown.** Check it at the harness's named evidence directory after each teardown; do not assume it.
3. **Nothing a drive started outlives the drive.** Clean up after failed attempts too, whatever state the session is in. On a shared instance, clean up what you did, never the instance.

A `doctor` failure caused by the harness itself is drift: fix it within the edit scope, restart only what the fix invalidated, and retry once. A second failure ends the pass as **blocked**. A feature you cannot reach is `unreachable` only with the concrete prerequisite (auth, entitlement, OS, external state) and the route you tried; if its file omits that prerequisite, that is drift too.

### 5. Triage

- A wrong or missing description from the user's side → map drift: fix the file.
- Working behaviour the harness cannot drive → harness gap: fix the harness, keep it executable with its invocation in `--help`, and drive the fix live again before committing it.
- Behaviour that is actually broken → product regression: report it, keep it out of the commit.

Tear down after the last drive of the run, re-drives included, so nothing outlives it. Evidence stays.

### 6. Outcome and report

Name one outcome:

- **clean**: every feature read from source and driven live; nothing to correct. No commit.
- **changed**: one local commit of proven corrections, message `walkthrough-nt map: <what changed>`. Read back every changed file before committing. Nothing is pushed; `/windup-nt` ships.
- **blocked**: coverage could not finish, or a correction could not be proven. Say exactly what stopped it and what would unblock it.

Write `plan/walkthrough-map-<date>.md` (create `plan/` per the Phase 7 rule): the outcome, the `Reviewer:` line, each feature with its source and live coverage (driven, `unreachable` with prerequisite and route, or not reached), each drift fixed with its evidence, each product regression with its repro, and an `## Impact` section (regressions → `pending.md/Now — add: …`, or `- none — <reason>`).
