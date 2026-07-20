# The session state machine

Every ntkit session is a state machine. It always was — `plan/` is the external
state, the commands are the events, windup→resume is a transition. This file just
names it, so legality is checkable instead of conventional. (Loops and graphs are
both state machines; agent orchestration is the actor model. Learn the primitives,
skip the hype.)

## States

A repo with a `plan/` folder is always in exactly one of six states:

| State | Meaning | Evidence on disk |
| --- | --- | --- |
| `fresh` | No handoff yet | No `plan/`, or empty of the three canonical files |
| `briefed` | Context read, nothing in flight | Canonical files present; no open batch, working tree clean |
| `building` | Mid-chunk | Open `[ ]` items in the active workplan/batch, and/or uncommitted work |
| `verifying` | Work done, verifier not yet green | Chunk items done but gate condition unmet, or an unexecuted audit report exists |
| `blocked` | Loop exited without done | A tried-trail in the latest summary/report; a Parked item naming the blocker |
| `shipped` | Gate green, released | Tag/release exists for the milestone; no open fix-workplan |

`blocked` and `shipped` are exits, not dead ends — both re-enter through
`/resume-nt`.

## Transitions

```
fresh ──/scaffold-nt──▶ briefed ──start a chunk──▶ building
building ──chunk done──▶ verifying ──gate green──▶ briefed (next chunk)
verifying ──/release-nt──▶ shipped
building | verifying ──no-progress / budget──▶ blocked
any ──/windup-nt──▶ (state persisted to plan/) ──/resume-nt──▶ same state, new session
```

`/windup-nt` and `/resume-nt` are not transitions — they persist and restore
whatever state the repo is in. The state survives the session; that's the point.

## Legal commands per state

| State | Legal | Illegal (refuse or warn) |
| --- | --- | --- |
| `fresh` | `/scaffold-nt` | Everything that reads `plan/` |
| `briefed` | audits, `/execute-nt` (if a report is open), start a chunk, `/replan-nt` | `/release-nt` with nothing verified |
| `building` | `/decide-nt`, `/idea-nt`, `/windup-nt` (warns), `/autopilot-nt` | `/release-nt`, `/package-nt` |
| `verifying` | `/execute-nt`, `/walkthrough-nt`, `/forward-pass-nt` | `/release-nt` with open items |
| `blocked` | `/resume-nt`, `/decide-nt` (unblock), `/replan-nt` | `/autopilot-nt` at the same wall |
| `shipped` | `/package-nt`, `/release-nt` (next), `/maintain-nt` | — |

Always legal, any state: `/standup-nt`, `/resume-nt`, `/decide-nt`, `/idea-nt`,
`/notify-nt`, and the vault pair (`/capture-nt`, `/ask-nt`) — they read, log, or
live outside the repo entirely.

## Guards

Four rules make the table enforceable, not decorative:

1. **Every command declares its contract in frontmatter** — `entry` (the state and
   artifacts it requires), `exit` (the machine-checkable condition that means it
   finished), `writes` (which plan files it touches). A command whose entry
   condition fails says so and stops; it does not proceed politely.
2. **"Done" is the verifier's word.** No transition out of `verifying` on an
   agent's self-report. Tests green, lint clean, replay reconstructs — a
   deterministic check, or the state doesn't advance.
3. **Deliberate override, logged.** Any guard can be overridden — this is a kit,
   not a jail — but only through an explicit `/decide-nt` entry stating why. A
   guard bypassed by drift is a bug; bypassed on purpose with a reason is a
   decision.
4. **Ask only at the unanswerable or the outward-facing.** A command asks the
   user only when the answer can't be derived (missing input, unknown
   credentials, no repo) or the action is outward-facing (publish, post,
   release, push to the world). Everything else takes the safe default,
   announces it, and logs it — the user steers by interrupting, not by being
   polled.

## Scaling — guards fire on evidence, not on ceremony

None of this adds steps to a simple project. Every guard checks for an artifact —
an open report, a failing verifier, a HELD branch, a dirty tree — and **an artifact
that doesn't exist can't fail a check**: no verifier defined means the release
guard passes vacuously (noted, not blocked); no reports means nothing to refuse; a
repo that never accumulates enough for `/replan-nt` never meets the replay check.
A single-file tool's session looks exactly as it did before this file existed. The
machinery earns its keep only where the evidence it reads exists — which is
precisely the projects complex enough to need it. Same seam as everywhere in the
doctrine: durability and reach, not ceremony.

## The actor rule (parallel runs)

Concurrent `/autopilot-nt` runs are actors: each in its own worktree, private
state, **no reading another run's worktree or plan scratch**. The only
communication is the mailbox — the morning report `plan/<date>-autopilot.md`, one
format, one location. `/standup-nt` is the sole cross-actor reader;
`/resume-nt` reads only its own repo's mailbox. Message-passing, no shared
memory — that's what makes parallel runs safe to leave alone.

## Replay check

`history.md` is the event log. Replaying it — decisions plus the daily log —
should reconstruct the current `pending.md` to within noise. `/replan-nt` runs
this check before folding; divergence means drift, and drift gets reported before
it gets archived.
