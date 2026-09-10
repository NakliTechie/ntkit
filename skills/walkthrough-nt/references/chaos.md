## Phase 5 — The chaos leg

The scripted journey is one draw from one distribution, and the mind that wrote it is the mind that
built the app. Its blind spots are inherited, not accidental — a gap in understanding produces both a
wrong implementation *and* a journey that never probes it. Phases 1–4 cover the path a user is
*supposed* to take. This phase covers the space between those steps: **unexpected sequences of
actions, weird timings, and inputs nobody thought could be entered.**

You already have the expensive thing — a booted, seeded, authenticated app sitting in a state the
journey reached. Spend it.

### Seed it, or the replay gate is unimplementable

**Before anything else: drive the walk from a seeded PRNG, and record the seed.** The phase's whole credibility rests on replaying the action-log prefix from a cold boot, and that is only tractable if the same seed reproduces the same sequence. Without one you cannot re-drive a prefix, every breach lands in the unreproduced list, and the phase collapses into "it broke somewhere in there" — precisely the failure this design exists to prevent.

**What the seed does and does not buy you.** It reproduces the *branch choices* exactly. It does not reproduce the *alphabet*, because Phase 5 correctly enumerates what is actionable from the live page at each step — so once app state diverges (after a fix, say), the tail of the sequence diverges too: the same seed picked "json" where it had picked "docx". That is fine, and worth understanding rather than fighting: the log prefix reconstructs state **up to the breach**, which is all the gate needs. Do not expect a seed to give you a stable long sequence across code changes.

Replay also assumes the app's state is reconstructible from a cold boot plus a keystroke sequence. That holds for a locally-persisted app; it breaks where state depends on wall-clock or server responses, and there the honest move is to say replay is unavailable for that flow rather than to fake a repro.

Log the seed in the report header. `--seed=<n> --stop=<action-index>` is the shape you want: it makes replay a one-liner and lets a later run reproduce this one exactly.

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

### Three axes, in order of yield

The action sequence is the axis this phase is named for and the *least* productive of the three. Against a mature app it exhausts quickly — a single-file tool has a few dozen controls, and a shipped product with a real test gate survives random clicking by design. One run spent **246 actions across five legs and found nothing on this axis at all.** That is not a malfunction; it is what a good app should do. Budget accordingly and spend the time where findings actually live:

1. **Durability.** Act, reload, check you are where you left off with the state you left. `INV-DURABLE` from Phase 3 already watches this; the chaos leg's job is to reach states the scripted journey never did and *then* reload. Highest yield per action of anything here.
2. **Values.** Wherever the app ingests data — a file picker, a paste target, an import dialog, a URL field — hand it the wrong type, an empty file, a binary, something enormous, a hostile string. An importer that accepts the wrong file, invents rows and reports success is worse than one that crashes, and no scripted journey will ever hand it the wrong file.
3. **Action sequences and timings.** The random walk proper, below. Wherever the app
ingests data — a file picker, a paste target, an import dialog, a URL field — hand it the wrong type,
an empty file, a binary, something enormous. An importer that accepts the wrong file, invents rows,
and reports success is worse than one that crashes, and no scripted journey will ever hand it the
wrong file.

### Budget it, and declare the budget

Default: **~40 actions per role on the sequence axis**, and do not treat that as the phase's centre of gravity — spend at least as much effort on durability and values, which is where a mature app actually breaks. Count actions, not minutes — the wall-clock runs well past a naive estimate because every candidate breach needs a clean-context reproduction before it earns an ID, and that verification is the phase's whole credibility. Scale it with
`$ARGUMENTS` when a run is scoped to one flow. The budget goes in the report whether or not anything
was found — "20 minutes of chaos across 3 roles, 2 findings" and "the leg was skipped" are different
facts and the reader needs the right one.

**Skip it deliberately, never silently.** If Phase 4 deferred a Critical that blocks the app, or the
app has irreversible side effects a random walk would actually trigger (sends real email, charges a
real card, writes to a shared upstream), say so in the report and skip. That is a legitimate outcome.
Chaos against an app whose seams aren't stubbed is a way to page a stranger at 2am.

### Amplify a timing bug instead of hunting it

An intermittent failure that needs host load to appear is expensive to chase and impossible to
verify a fix against — you cannot prove a fix when the bug shows up 3 times in 40 runs. So do not
chase it. **Find the timing parameter the bug depends on and exaggerate it until the failure is
deterministic.**

A deferred re-focus running on `setTimeout(fn, 0)` loses the race only when the host is loaded.
Change that one `0` to `300` and it loses every time: one run went from 85/86 to 49/86, and a
focused repro from 3-in-40 to 6-in-6. Now the bug is a fixed point you can iterate against, and the
fix is provable — same amplifier, 8-in-8 green. Then remove the amplifier and confirm at realistic
timing.

This works for anything with a tunable delay: a debounce, a poll interval, an animation duration, a
retry backoff, a deferred callback. Change **one** constant, change nothing else, and keep the
amplified build out of the commit.

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
