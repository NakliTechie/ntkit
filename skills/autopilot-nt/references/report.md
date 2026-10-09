## Phase 6 — The morning report

**Audit the trail before you append it.** Draft the closing sections, then walk the draft against `git log` on the branch, the per-item checker outputs and the reverts: every claimed item maps to a real commit; every "how verified" points to evidence that resolves (a SHA, a check output, a `file:line`) and shows what the line claims; any pivot, revert or abandoned approach that shaped the run goes in; anything aspirational or padded comes out of the draft. **Fix the report, not the story.** Nothing already written to the record is deleted or reworded; a wrong earlier line gets a correction appended below it. Write it per ATTEST.

Append to this run's record (the path fixed at Phase 0.5) the report, then the `## Impact` section, then this handoff:

```
Autopilot ran <project-name> — <duration / "overnight"> on branch autopilot/<date>.

Final gate: <GREEN (tests · typecheck · build · lint) | RED — <what failed>>
Shipped:    <MERGED to <default branch> + pushed (<merge SHA>) | HELD on branch autopilot/<date> — <gate red | main dirty | conflict | push owed>>

Landed (fresh-eyes verified):
  - <item> — <how verified> — <SHA>
  - <item> — <how verified> — <SHA>

Parked — needs you:
  - <stop-lined action, why it needs a human>
  - <blocking question, with the context to answer it cold>

Tests changed (review before trusting green):
  - <test file · which item touched it · checker's note>        [or "none"]

Assumed (reversible calls I made):
  - <default taken, and why>

Ended because: <queue done | goal met | budget hit | systemic halt: <cause>>
<if MERGED:> <default branch> is updated on the remote — pull it. Worktree left at .worktrees/<name>: git worktree remove .worktrees/<name>
<if HELD:>   Review: git diff <default branch>...autopilot/<date> — merge or discard, then git worktree remove .worktrees/<name>
Resume: cd <main checkout absolute path> and run /resume-nt (it reads this report)
```

Finish with `/notify-nt "<project>: autopilot done — gate <GREEN|RED>, <shipped|held>, <N> landed, <M> need you"`.
