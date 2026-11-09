---
name: soc-nt
description: "Append a timestamped raw thought to plan/soc.md and keep working."
allowed-tools: Bash Read Write Edit
metadata:
  argument-hint: "<the thought, e.g. \"login feels slow — maybe preload the session\">"
  entry: "any state — especially mid-build"
  exit: "timestamped entry appended to plan/soc.md; the work continues"
  writes: "plan/soc.md"
---

Log a passing thought while the build keeps moving. `/decide-nt` records decisions; soc takes **everything else** as a raw stream (ideas, observations, gripes, "park it" deferrals). Unsure which → soc. `/replan-nt` triages the stream later.

The contract: **capture, don't process.** No analysis, no follow-up questions, no acting on it now.

1. **Get the text** — the invocation text, or ask *"What's on your mind?"* and use the next message. Near-verbatim: strip dictation filler, fix nothing else, never paraphrase — the entry reads in the user's voice. Multiple distinct thoughts → multiple entries.
2. **Locate** — not in a git repo → ask which project. create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`; create `plan/soc.md` with a `# Stream` header if missing.
3. **Append at the top** (newest first), timestamped to the minute: `- YYYY-MM-DD HH:MM — <entry>`
4. **Confirm in one line** — `Logged to plan/soc.md: <the entry>`. If it's obviously a decision you may append `(sounds like a /decide-nt — say the word)`; never promote on your own, never ask a follow-up. Don't commit or push.
