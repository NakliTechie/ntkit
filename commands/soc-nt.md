---
description: "Stream-of-consciousness capture — append a timestamped raw thought to gitignored plan/soc.md and keep working; /replan-nt triages the stream later."
argument-hint: "<the thought, e.g. \"login feels slow — maybe preload the session\">"
entry: "any state — especially mid-build"
exit: "timestamped entry appended to plan/soc.md; the work continues"
writes: "plan/soc.md"
---

Log a passing thought while the build keeps moving. `/decide-nt` records a load-bearing *decision*, curated, into history — soc takes **everything else** as a raw stream: ideas, observations, hunches, gripes, "park it / not now" deferrals. Unsure which → soc. `/replan-nt` triages the stream later (decisions → `history.md`, ideas → backlog, deferrals → `pending.md` Parked, questions → Open questions).

The contract: **capture, don't process.** No analysis, no follow-up questions, no acting on it now.

1. **Get the text** — `$ARGUMENTS`, or ask *"What's on your mind?"* and use the next message. Near-verbatim: strip dictation filler, fix nothing else, never paraphrase — the entry reads in the user's voice. Multiple distinct thoughts → multiple entries.
2. **Locate** — must be inside a git repo (else ask which project — don't guess). Create `plan/` if missing, verify it's gitignored, create `plan/soc.md` with a `# Stream` header if missing.
3. **Append at the top** (newest first), timestamped to the minute: `- YYYY-MM-DD HH:MM — <entry>`
4. **Confirm in one line and get out of the way** — `Logged to plan/soc.md: <the entry>`. If it's obviously a decision you may append `(sounds like a /decide-nt — say the word)` — but never promote on your own, never ask a follow-up. The build has the floor. Don't commit or push — plan/ is gitignored.
