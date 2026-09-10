## Phase 5 — The chaos leg

The scripted journey is one draw from one distribution, and the mind that wrote it is the mind that
built the app. Its blind spots are inherited, not accidental — a gap in understanding produces both a
wrong implementation *and* a journey that never probes it. Phases 1–4 cover the path a user is
*supposed* to take. This phase covers the space between those steps: **unexpected sequences of
actions, weird timings, and inputs nobody thought could be entered.**

You already have the expensive thing — a booted, seeded, authenticated app sitting in a state the
journey reached. Spend it.

### The loop

From each state the scripted walk reached, run a bounded random walk:

1. **Enumerate what's actionable right now** — the interactive elements actually present and enabled
   on this screen. Not a fixed alphabet you wrote in advance; whatever is on the page.
2. **Pick one at random and drive it**, with a random value inside a plausible range where the control
   takes one. Weight the branches if you must (a destructive action every time is noise), but keep the
   weighting shallow — the whole value is that the sequence isn't yours.
3. **Check the whole invariant set** from Phase 3, plus: is the app still usable, or has it reached a
   state with no way out?
4. **Log the action** to the same append-only action log, then continue from wherever you landed.

Timings are part of the input space. Sometimes act immediately, before the previous action settles;
sometimes wait. Double-submit. Navigate mid-request. Hit back after a mutation.

### Budget it, and declare the budget

Default: **~40 actions per role**, or 5 minutes per role, whichever comes first. Scale it with
`$ARGUMENTS` when a run is scoped to one flow. The budget goes in the report whether or not anything
was found — "20 minutes of chaos across 3 roles, 2 findings" and "the leg was skipped" are different
facts and the reader needs the right one.

**Skip it deliberately, never silently.** If Phase 4 deferred a Critical that blocks the app, or the
app has irreversible side effects a random walk would actually trigger (sends real email, charges a
real card, writes to a shared upstream), say so in the report and skip. That is a legitimate outcome.
Chaos against an app whose seams aren't stubbed is a way to page a stranger at 2am.

### Replay before you believe it

**A breach found here does not earn an ID until it replays.** A random walk produces sequences you did
not intend and cannot recall, which makes "it broke somewhere in there" the default failure mode of
this phase and the reason a chaos leg is worth less than it looks.

So: take the action log's prefix up to the breach, re-drive it from a cold boot, and see it break
again. Then close the loop under Phase 4's ordinary rules — reproduce, root-cause, fix minimally,
re-verify, commit.

- **Replays cleanly** → a real finding. ID it and fix or defer it like any other.
- **Doesn't replay** → it depends on timing or on state the log doesn't capture. Log it as
  `unreproduced`, with the action prefix, in the report's own list. Do **not** fix a symptom you can't
  trigger, and do not let it inflate the finding count. An unreproduced breach is a lead, not a bug.
- **Replays only sometimes** → that flakiness *is* the finding; report it as one.

### Pin what you found

Every confirmed chaos finding becomes a **regression case in the harness** when you build it in Phase
6 — the action prefix, replayed, asserting the invariant now holds. This is the difference between a
chaos leg that pays once and one that pays every run: the random walk found the sequence, and the
harness owns it from then on so no later run has to get lucky again.

A finding that got fixed but not pinned will come back. Pin it.
