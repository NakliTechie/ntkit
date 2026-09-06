## Phase 6 — The morning report

**Audit the trail before you write it.** Draft the report, then walk it against what actually happened — `git log` on the branch, the per-item checker outputs, the reverts: every claimed item maps to a real commit; every "how verified" points to evidence that resolves (a SHA, a check output, a `file:line`) and shows what the line claims; any pivot, revert, or abandoned approach that shaped the run but isn't in the draft gets added; anything aspirational or padded gets cut. **Fix the report, not the story** — if the work diverged from what a line claims, the line is wrong. Write it in plain teammate language: concrete actions, no AI-speak, no filler; a line nobody would audit doesn't earn its place.

Write `plan/$(date +%Y-%m-%d)-autopilot.md` and end with a tight handoff in this shape:

```
Autopilot ran <project-name> — <duration / "overnight"> on branch autopilot/<date>.

Final gate: <GREEN (tests · typecheck · build · lint) | RED — <what failed>>
Shipped:    <MERGED to <default branch> + pushed (<merge SHA>) | HELD on branch autopilot/<date> — <gate red | main dirty | conflict | push owed>>

Landed (fresh-eyes verified):
  - <item> — <how verified> — <SHA>
  - <item> — <how verified> — <SHA>

Parked — needs you:
  - <stop-lined action, why it needs a human>
  - <blocking question — see plan/pending.md>

Tests changed (review before trusting green):
  - <test file · which item touched it · checker's note>        [or "none"]

Assumed (reversible calls I made — see plan/history.md):
  - <default taken, and why>

Ended because: <queue done | goal met | budget hit | systemic halt: <cause>>
<if MERGED:> <default branch> is updated on the remote — pull it. Worktree left at .worktrees/<name>: git worktree remove .worktrees/<name>
<if HELD:>   Review: git diff <default branch>...autopilot/<date> — merge or discard, then git worktree remove .worktrees/<name>
Resume: cd <main checkout absolute path> and run /resume-nt (it reads this report)
```

The three lines that matter most are the **Final gate** (whether the branch is trustworthy at all), **Shipped** (merged or held, and why), and **Needs you** (so the human's scarce attention goes straight to what only they can unblock). A green run ships itself to the default branch; a red or conflicted one touches nothing outward and waits on the branch. Everything reversible was decided and logged. Finish by firing `/notify-nt "<project>: autopilot done — gate <GREEN|RED>, <shipped|held>, <N> landed, <M> need you"` so the finish is a ping, not a surprise — it degrades silently if no channel is configured. `/resume-nt` reads this report straight into the next session.
