---
description: Scaffold a new project from attached handoff materials OR an inline description — create local folder, init git + remote repo, seed plan/, brief the first move
argument-hint: "[name | parent/name]  (attach md/zip OR describe inline)"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Task"]
entry: "fresh — no repo yet; handoff materials attached"
exit: "repo + remote exist, plan/ seeded, first-move brief printed"
writes: "plan/history.md, plan/pending.md, plan/workplan.md, git"
---

Bootstrap a new project from the handoff materials the user attached this session (md files, zip, or a combination). End state: local folder + remote repo + seeded `plan/` + a `/resume-nt`-style brief on the first move.

**Default parent dir:** `~/code` (edit this to match where you keep your repos — e.g. `~/projects`, `~/src`). Call the resolved value `$ROOT` below.

## Phase 1 — Identify the handoff source

`/scaffold-nt` accepts the handoff in three modes — pick whichever the user provided:

**A. Attached files.** Markdown handoffs, zips, or a combination.
- Markdown files → go to the project root
- Zip files → extracted at the project root, preserving structure
- Anything else → ask before including

**B. Inline description.** `$ARGUMENTS` and/or the natural-language context around the user's `/scaffold-nt` invocation IS the handoff. Examples: *"a static site tracking wage data over 50 years, Python + Pandas + Quarto"* or *"tiny CLI that watches a folder and runs pytest on change, single-file Bash for v0"*. Treat the prose as the handoff and synthesize a starter `README.md` from it in Phase 3.

**C. Both.** Attached files are primary; the inline description is context. Drop the description into the initial commit message body and/or append a `## Context` section to the synthesized README.

**Heuristic:** `$ARGUMENTS` containing only a name slug (`myapp`, `research/myapp`) is *not* a description — that's just the name. A description has multiple words / sentence-like prose.

If neither files nor a substantive description is present (e.g., bare `/scaffold-nt` or just `/scaffold-nt myapp` with no context), stop and ask: *"Give me a handoff — drag md/zip into chat, or describe the project in a sentence or two."*

## Phase 2 — Project name + location

Parse `$ARGUMENTS`:
- **Empty** → derive a name from the handoff (top `# H1` heading, "Project:" line, or filename of a README-like file). If ambiguous, ask.
- **Single token** (`myapp`) → location: `$ROOT/myapp/`.
- **Slash-separated** (`research/myapp`, `apps/myapp`, etc.) → location: `$ROOT/<parent>/<name>/`. Useful if you organize repos by category.

If the target folder exists and isn't empty, stop and ask for a different name. If the parent dir doesn't exist, create it.

## Phase 3 — Materialize the local folder

1. `mkdir -p` the target folder.
2. **For attached files** (mode A or C):
   - For each attached zip: `unzip <zip> -d <target>` — preserve structure; ask before overwriting.
   - Copy each attached md file into the target root. If a name collides with the zip's contents, ask which is authoritative or merge by renaming (`README.md` + `HANDOFF.md`).
3. **For inline description** (mode B, or to augment mode C): synthesize a starter `README.md` from the user's prose and write it to the target root. Structure it lightly:
   ```markdown
   # <name>

   > <one-line summary distilled from the description>

   <the user's description, cleaned up — preserve their wording where it's clear>

   ## Next steps
   <bulleted next-steps if the description implied them; otherwise omit>
   ```
   Show a brief preview of the synthesized README in chat (3–5 lines) so the user can flag if it's wrong before the commit. Don't block on confirmation — proceed unless they interrupt.
4. Run `ls -la <target>` to confirm what landed where.

## Phase 4 — Initial git + .gitignore

1. `git init -b main` in the new folder.
2. Write `.gitignore`: OS junk + `plan/` (per the plan-folder convention these commands share).
3. Stage everything except `plan/`. Use explicit paths — never `git add -A`.
4. Initial commit: `Initial commit — scaffolded from handoff`.

## Phase 5 — Remote repo

Ask the user (one focused question):
- **GitHub org/account** — the user's own account or any org they have push rights to. Or "skip remote" for local-only.
- **Visibility** — public or private. Default private for handoffs that may contain sensitive info.

Then:
```bash
gh repo create <org>/<name> --<private|public> --source=. --remote=origin --push
```

If `gh` isn't authed or the org doesn't have permission, surface the error and let the user fix it. Capture the repo URL on success.

## Phase 6 — Seed plan/

1. `mkdir plan` (already gitignored).
2. Read the most README-like file in the new repo carefully (the handoff). Identify: scope, milestones/phases, explicit todos, open questions, decisions stated up front, deferrals.
3. Write `plan/history.md` with the canonical three sections:
   - **Decisions** — explicit choices stated in the handoff, each dated today.
   - **Log** → today's entry: `Shipped: scaffolded from <handoff filename(s)> at <folder> · remote: <url> · initial commit: <sha>.` Verified: nothing yet. Tried then rolled back: none. Open questions: pointer to pending.
   - **Dead ends** — empty.
4. Write `plan/pending.md` (Now / Parked / Open questions). Pull from the handoff:
   - "Next steps" / "Todo" lines → Now (in stated order)
   - "Future" / "Later" / "Out of scope" → Parked
   - Anything with "?" / "TBD" / explicit Open Questions → Open questions
5. Write `plan/workplan.md`:
   - If the handoff has phases/milestones, one Batch per phase, first one tagged `(keystone)`.
   - Else, one Batch A with the top 3–5 Now items.
   - Tri-state checkboxes throughout. `[test]` markers where runtime verification is owed.

## Phase 7 — Brief + get started

Print a `/resume-nt`-style brief:

```
Scaffolded <name>.

Folder: <absolute path>
Repo: <url> (<private|public>)
Scope (from handoff): <1–2 line summary>

Top chunk — "<title>" (<size>):
  - <item>
  - <item>
  - <item>

Blocking (if any):
  - <open question>
```

End with one open-ended question:

> Ready to start on **"<chunk title>"**, or want to read the handoff first?

Do NOT start work without confirmation. /scaffold-nt's job is to set the stage; the user decides when to step on it.
