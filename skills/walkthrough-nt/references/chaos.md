## Phase 5 — The chaos leg

### Seed it

**Drive the walk from a seeded PRNG and record the seed**; without one, replaying a prefix from a cold boot is unimplementable. The seed fixes branch choices, not the alphabet: after a fix the tail of the sequence diverges, but the logged prefix still reconstructs state up to the breach. Where state depends on wall-clock or server responses, say replay is unavailable for that flow rather than faking a repro. Log the seed in the report header; `--seed=<n> --stop=<action-index>` is the shape.

### The loop

From each state the scripted walk reached: enumerate the actionable elements from the live page (not a fixed alphabet), pick one at random with a plausible value, keep any branch weighting shallow, check the whole invariant set plus "is there still a way out", and log the action to the same action log. Vary timing: act before the last action settles, double-submit, navigate mid-request, go back after a mutation.

### Yield order and budget

Spend effort in this order: **durability** (reach states the script never did, then reload), **bad values** at every ingest point (wrong type, empty file, binary, enormous, hostile string; an importer that accepts the wrong file and reports success is worse than a crash), then **action sequences and timings**. One run spent 246 sequence actions across five legs and found nothing on that axis.

Default budget: **~40 sequence actions per role**, with at least as much effort on durability and values. Count actions, not minutes. Scale it down when `$ARGUMENTS` scopes the run to one flow. Declare the budget and yield in the report, or the reason the leg was skipped under the SKILL.md side-effect stop-line.

### Amplify a timing bug instead of hunting it

For an intermittent failure, change the **one** timing constant it depends on (a `setTimeout(fn, 0)` to 300, a debounce, a poll interval, a retry backoff) until it fails every time; one repro went from 3-in-40 to 6-in-6. Iterate the fix against that, remove the amplifier, and confirm at real timing. Never commit the amplifier.

### Replay before you believe it

A breach earns an ID only after its action-log prefix re-drives it from a cold boot. Then close it under Phase 4's rules.

- **Replays cleanly** → a real finding; fix or defer it like any other, and pin it in the Phase 6 harness.
- **Doesn't replay** → log it as `unreproduced` with its action prefix, in the report's own list. Don't fix a symptom you can't trigger, and don't count it as a finding.
- **Replays only sometimes** → the flakiness is the finding; report it as one.
