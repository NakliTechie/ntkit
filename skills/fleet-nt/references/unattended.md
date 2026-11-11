## Phase 6 — Check-ins

Check in about every 20 minutes. Use the host's scheduler, a timed wake-up or a recurring loop; never a foreground sleep loop, because it cannot do the check-in work. Each check-in:

1. Run `sh $SKILL/../supervise-nt/bin/supervise.sh checkin '<one line of what you saw>'` with `NT_SUPERVISE_SCOPE=fleet-<date>`.
2. For each child, read its record and its branch:
   - **landed:** `git -C <repo> log --oneline <default>..autopilot/<date>` for commits on the run branch, and the merge commit on the default branch once it merges;
   - **progress:** items checked `[x]` out of the run's queue, as a percentage;
   - **ETA:** the earlier of the budget's end and the time the remaining items would take at the run's mean minutes per item so far;
   - **state:** running, idle (a session waiting for input), or ended (a handoff block exists, or the probe fails).
3. Harvest new Needs-you lines (`references/relay.md`).
4. Rewrite `digest.md` from what you read. It is derived, so a full rewrite is fine; `calls.md` is append-only.
5. A child that is stalled (no new log line or commit for two check-ins), looping, or off its batch gets one message naming what you saw. A second stall gets it parked in the digest for the owner.

### The away policy

While the owner is away, answer each new question yourself when both hold:

- the recommended default is reversible inside the repo (a code or design choice, an order, a scope cut inside the batch, holding instead of merging);
- it stays inside the brief.

Relay it as `Fleet default (owner away): <instruction>` and never as `approved:`. Append to `calls.md`: `<HH:MM> <repo> — Q: … — call: … — why: … — undo: …`.

Park everything else for the owner: deploys, releases and tags, spend, outward messages, held merges, credentials, deletions, and steps that need a person. A child that asks for one of these gets `Parked for the owner; continue with your next item.`

### The digest

```markdown
# Fleet digest — <date>
Updated <HH:MM> · mode <go|away> · stop at <HH:MM | all idle> · <N> children: <r> running, <i> idle, <e> ended

## <repo> — <running 60%, ETA 05:40 | ended: MERGED <sha> | ended: HELD <reason>>
- Landed: <sha> <subject>; <sha> <subject>
- Calls taken: <HH:MM> <call> (see calls.md)
- Needs you: <question> (default: <option>; blocks: <item>)

## Parked for you
- <repo>: <deploy | spend | message | person-only step | held merge>, with the command or step

## Excluded at triage
- <repo>: <reason>
```

Every hash and percentage comes from the record or `git log`, never from a child's message alone.

## Phase 7 — Close

Close when every child is idle or ended, or at the stop time. At the stop time, broadcast `Fleet stop: finish the current item, write your report, then stop.` and wait up to 30 minutes for the reports.

1. Rewrite `digest.md` a last time and append `## Closed <HH:MM>` with one line per child: final gate, shipped or held, landed count, Needs-you count.
2. Retire every child: `sh $SKILL/../supervise-nt/bin/supervise.sh done <repo> '<outcome>'`.
3. Stop the supervisor by its own pidfile, never by a process-name pattern, because that would stop other projects' supervisors.
4. Fire `/notify-nt` once, with the digest's absolute path.

What stays, for the owner to remove after review:

- each child's worktree and branch (`git -C <repo> worktree remove .worktrees/<name>`; the record's handoff names both);
- held branches, listed under Parked for you;
- the fleet folder with the brief, triage, calls, digest and logs (`rm -r <fleet folder>` once read);
- headless logs and pidfiles inside the fleet folder.
