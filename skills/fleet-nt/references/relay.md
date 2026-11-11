## Phase 4 — Broadcast a constraint change

A broadcast is for a change you could not foresee when you wrote the brief, such as "defer all GPU work" because another job now holds the GPU.

1. Append it to `brief.md` under `## Amendments` as `- <HH:MM> <the change, as a rule>`.
2. Send it to every live child as one message: `Fleet amendment <HH:MM>: <rule>. It is in brief.md. Stop at the next safe point if your current item breaks it, and park that item under Needs you.`
3. Headless children cannot receive it. They read it at their next batch boundary.
4. At the next check-in, look in each child's progress log for work that broke the rule before the message landed. Name each one in the digest under that project, with what the child did about it.

## Phase 5 — Harvest the questions

Each child's record is `plan/<date>[-N]-autopilot.md` in its repo's main checkout (the worktree's `plan/` links there). Read the record only, never the worktree. Collect:

- Impact lines `- pending.md/Open questions — add: …` and `- pending.md/Now — add: …`, once the report exists;
- the handoff block's `Parked — needs you:` lines;
- `deferred: needs you — …` lines in the progress log, while the run is still going.

The brief asks every child for one shape, `<question> (default: <option>; blocks: <item or nothing>)`, so each line splits into question, default and what it blocks. A line in another shape gets its default and blocker filled in by you from the record, marked as your reading.

Drop duplicates and lines already asked. Order the rest: blocks a keystone, then blocks a held merge, then everything else.

### Ask

Ask at most 4 questions at a time. Use the host's question tool when it has one, otherwise a numbered list. Each question carries:

- the repo and the question in plain words, readable without the record;
- the options, with the recommended default first and marked;
- what the answer unblocks.

In `away` mode do not ask: apply the policy in `references/unattended.md`.

### Relay

Send each answer to its child as an instruction, with the owner's words quoted:

```text
Owner's answer to "<question>": "<owner's words>".
Instruction: <the concrete step, e.g. use option B for the import format and continue with B2#3>.
```

An approval names the action exactly and starts with `approved:`, because one past child held an approved merge until the approval was restated in that form:

```text
approved: merge autopilot/<date> into main and push. Owner's words: "<owner's words>".
```

A child that has ended, or a headless child, gets the answer through a new run. Start `/autopilot-nt` in that repo with the instruction as the first line of its goal and the same brief, and register it as a new child. Log every question, answer and relay in `calls.md` as `<HH:MM> <repo> — Q: … — A (owner): … — relayed: <message or new run>`.
