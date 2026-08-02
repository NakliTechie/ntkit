---
description: "Stream-of-consciousness capture — log running commentary mid-build to plan/soc.md (timestamped, near-verbatim), zero processing, work continues. /decide-nt's sibling for everything that isn't yet a load-bearing decision — including future-work ideas. /replan-nt triages the file later."
argument-hint: "<the thought, e.g. \"login feels slow — maybe preload the session\">"
entry: "any state — especially mid-build"
exit: "timestamped entry appended to plan/soc.md; the work continues"
writes: "plan/soc.md"
---

Log a passing thought while the build keeps moving. `/soc-nt` is `/decide-nt`'s sibling: decide records a load-bearing *decision*, curated, into history — soc takes **everything else**: future-work ideas, observations, hunches, gripes, half-formed connections, and "park it / not now" deferrals — anything raised but consciously not done now — as a raw stream. Route by certainty: know it's a decision → decide; anything else, including an idea that isn't backlog-ready yet or a "skip this for now" → soc. `/replan-nt` sorts the stream out later — actionable ideas promote to the backlog, deferrals land in `pending.md` `## Parked`, load-bearing calls surface as decisions, questions land in `pending.md`.

The contract: **capture, don't process.** No analysis, no follow-up questions, no acting on it now.

## Step 1: Get the commentary

If `$ARGUMENTS` is non-empty, that's the entry. If empty, ask *"What's on your mind?"* and use the next message.

Capture **near-verbatim**: strip dictation filler ("uh", "um", false starts), fix nothing else. Never paraphrase, never expand, never interpret — the entry should read in the user's voice, not yours. Multiple distinct thoughts in one invocation → multiple entries, split at the natural seams.

## Step 2: Locate plan/soc.md

Current directory should be inside a git repo. If not, ask which project — don't guess.

If `plan/` doesn't exist, create it; verify `plan/` is gitignored (add it if missing). Create `plan/soc.md` with a `# Stream` header if missing.

## Step 3: Append

Insert at the **top** of the list (newest first), timestamped to the minute — it's a stream, and within-day order matters at triage:

```
- YYYY-MM-DD HH:MM — <entry>
```

## Step 4: Confirm and get out of the way

One line, then back to whatever was running:

```
Logged to plan/soc.md:
  - <YYYY-MM-DD HH:MM> <entry>
```

If the entry is *obviously* a load-bearing decision or a crisp future-work item, you may append one clause — `(sounds like a /decide-nt — say the word and I'll promote it)` — but never promote on your own, and never ask a follow-up. The build has the floor.

Don't commit, don't push — plan/ is gitignored. `/windup-nt` folds today's entries into the day summary; `/replan-nt` triages the file line by line (decisions → history, ideas → backlog, questions → pending) and archives it.
