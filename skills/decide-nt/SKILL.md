---
description: "Append one dated decision line to plan/history.md."
argument-hint: <short rationale, e.g., "Chose JWT for stateless validation">
allowed-tools: ["Bash", "Read", "Write", "Edit"]
entry: "any state"
exit: "dated one-line decision appended"
writes: "plan/history.md"
---

Record a decision in the current project's `plan/history.md`. Everything that isn't a decision (ideas, observations, deferrals) goes to `/soc-nt` instead.

1. **Text** — `$ARGUMENTS` verbatim; if empty, ask *"What did you decide?"* and use the reply.
2. **Locate** — not in a git repo → ask which project. create or check `plan/` per [MEMORY.md §0](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md#0-where-plan-lives): a broken `plan` symlink is a stop; if missing, create it in `$NT_PLAN_STORE` and symlink it in when that is set, else `mkdir plan`; then `git check-ignore -q plan`, else add `/plan` (no trailing slash) to `.gitignore`. If `plan/history.md` is missing, create it with `# History`, `## Decisions`, `## Log`, `## Dead ends`.
3. **Append** at the top of `## Decisions` (newest first): `- YYYY-MM-DD <decision text>`.
4. **Confirm**, nothing more:

```
Recorded in plan/history.md:
  - <YYYY-MM-DD> <decision text>
```

Don't commit, push, or run `/windup-nt`.
