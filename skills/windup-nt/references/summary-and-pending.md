## 1. Day summary

Write `plan/<date>-summary.md` from:
- this session's conversation;
- `git log --since=midnight --oneline --all`;
- `git status` and `git diff` for uncommitted work;
- today's `plan/soc.md` entries: fold the load-bearing ones into the sections below, but leave the file in place; `/replan-nt` owns its triage and archival.

Sections, in this order:
- **Shipped** — what landed (PRs, commits, deploys), each with its commit SHA
- **Verified** — how it was checked (tests / typecheck / build / manual) and what verification is still owed. A check counts only when it ran after the last edit to the files it covers; a file edited since its check is listed as owed (`SUBSTANCE.md` §6.20)
- **Decisions** — what was chosen and why
- **Tried then rolled back** — dead ends worth not repeating
- **Open questions** — surfaced today, unresolved
- **Deferred / parked** — raised today but consciously not done now (skipped, "later", out of scope, not abandoned); seeds `## Parked` in pending.md
- **Pick up here** — three lines: `Next action:` the exact next step (a command, a `path:line` to edit, or the decision to ask for); `Last error:` the last failing command and its error text verbatim, or `none`; `Transcript:` the path of this session's transcript file when the host keeps one (Claude Code: the newest `.jsonl` under `~/.claude/projects/<project-slug>/`; Codex: the newest file under `~/.codex/sessions/`), else `not kept`

**Failures.** Merge this session's failed tool calls into `plan/failures.md`:
`python3 $SKILL/bin/failures.py <this session's transcript or session id> --write` (Claude Code transcripts; for another host, write the lines by hand in the same shape). Then fill `fix:` on each line whose fix this session found (the flag, the order, the workaround that worked), and add a line by hand for each environment quirk found without a failed call ("port 9222 is taken", "tool X needs flag Y"), using `quirk` as the tool. A line the script reports as `seen` was hit by an earlier session too: name it under **Tried then rolled back** in the summary. Never delete a line; one that no longer applies gets `fix: obsolete — <why>`.

## 2. Pending items

Write or update `plan/pending.md`. The canonical structure (shared with `/replan-nt`):

```
# Pending

## Now
- <actionable, top priority>

## Parked
- <deferred, not in scope right now but not abandoned>

## Open questions
- <question that needs answering before it can become a task>
```

Merge rules:
- **File exists with sections:** preserve them. New items go into `Now` by default, `Open questions` if phrased as a question, `Parked` if deferred this session. Remove items finished today. Move a "not now" into `Parked` rather than dropping it; leave already-parked items alone unless they came back into scope today.
- **File exists, flat (no sections):** keep it flat; add new items and remove finished ones. `/replan-nt` migrates it to sections.
- **File doesn't exist:** create it with the three sections.

Order items by priority within each section, one line each; link to a deeper `plan/` doc for more context.

**Pointers.** Every item you add or carry names where its detail is, so the next session goes to the spot instead of re-reading the record: `[at: path:line]` for code, `[at: <sha>]` for a commit, `[at: session:<id>]` for this session's transcript when the detail lives only in the conversation (MEMORY.md §4). Use the pointer beside the `[from:]` tag. A pointer you cannot give means the item is too vague to act on: sharpen it first.
