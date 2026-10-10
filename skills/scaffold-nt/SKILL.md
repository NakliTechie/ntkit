---
description: "Bootstrap a new project: folder, git, remote repo, seeded plan/, first-move brief."
argument-hint: "[name | parent/name]  (attach md/zip OR describe inline)"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write", "Agent"]
entry: "fresh — no repo yet; handoff materials attached"
exit: "repo + remote exist, plan/ seeded, brief printed, top chunk underway"
writes: "plan/history.md, plan/pending.md, plan/workplan.md, git"
---

Bootstrap a new project from the handoff the user gave this session. End state: local folder, remote repo, seeded `plan/`, and a `/resume-nt`-style brief on the first move.

**Default parent dir:** `~/code` (edit to match where you keep repos). Call it `$ROOT`.

## Phase 1 — The handoff

The handoff is attached files (md, zip, or both), an inline description in `$ARGUMENTS` or the surrounding prose, or both (files primary; put the prose in the initial commit body and a `## Context` section of the README). A bare name slug (`myapp`, `research/myapp`) is a name, not a description. No files and no description → ask: *"Give me a handoff — drag md/zip into chat, or describe the project in a sentence or two."*

**Check the vault first.** If scholia's `/ask-nt` is installed, run it on the handoff's domain, stack and hard problem. Fold anything found into the Phase 7 brief as prior art, with the note slug.

## Phase 2 — Name and location

Empty `$ARGUMENTS` → derive the name from the handoff (H1, "Project:" line, README-like filename), announce it, proceed. `myapp` → `$ROOT/myapp/`; `parent/myapp` → `$ROOT/parent/myapp/`. If the target exists and isn't empty, suffix `-2`, `-3`, and announce it.

## Phase 3 — Materialize the folder

Unzip attached zips at the target root preserving structure, copy attached md files beside them, and on a name collision keep both (suffix the incoming file) and note it. For an inline description, write a starter `README.md`: H1, a one-line summary, the user's description cleaned up in their wording, and an **Install** section (README-DOCTRINE puts Install before Why) as a TODO stub, never omitted. Show a 3–5 line preview and proceed unless interrupted.

## Phase 4 — Git

`git init -b main`; `.gitignore` with OS junk and `/plan` (no trailing slash, so a symlinked `plan` is covered, MEMORY.md §0); stage by explicit path, never `git add -A`; commit `Initial commit — scaffolded from handoff`.

## Phase 5 — Remote

Default, no question: the user's own account (`gh api user --jq .login`), **private**. Announce it in the brief; the user asks for an org, public, or no remote if they want one. `gh repo create <owner>/<name> --private --source=. --remote=origin --push`. If `gh` isn't authed, continue local-only and name the owed remote in the brief.

## Phase 6 — Seed plan/

1. Create `plan/` per MEMORY.md §0: with `NT_PLAN_STORE` set, make it in the store and symlink it in; else a plain folder.
   ```bash
   if [ ! -e plan ] && [ -n "${NT_PLAN_STORE:-}" ]; then
     root="$(cd "$(dirname "$NT_PLAN_STORE")" && pwd -P)"; here="$(pwd -P)"
     rel="${here#"$root"/}"; [ "$rel" = "$here" ] && rel="$(basename "$here")"
     mkdir -p "$NT_PLAN_STORE/$rel/plan" && ln -s "$NT_PLAN_STORE/$rel/plan" plan
   fi
   mkdir -p plan
   ```
2. From the handoff, write `plan/history.md` (Decisions stated in the handoff, dated today · Log entry `Shipped: scaffolded from <handoff> at <folder> · remote: <url> · initial commit: <sha>.` · empty Dead ends) and `plan/pending.md` (next steps/todos → Now in stated order; future/later/out of scope → Parked; `?`/TBD → Open questions).
3. Tag every seeded item `[from: <handoff-filename-stem>]`, or `[from: hand]` for what the user said inline. Scaffold is one of the three sanctioned reconcile writers.
4. Write `plan/workplan.md`: one batch per handoff phase (first marked `(keystone)`), else Batch A with the top 3–5 Now items; tri-state checkboxes; `[test]` markers where runtime verification is owed. Unless the project is Throwaway tier, add two items to the keystone batch:
   - `[ ] Agent-first pass (ntkit DRIVER.md): run the driver's-seat meditation over the spec; write the project's agent contract as its §0` — runs once a spec draft exists, not now.
   - `[ ] Agent face (Build Doctrine, "two doors, one core"): declare a tool manifest for every UI-dispatchable command; mark non-delegable acts person-only explicitly, never by omission`.
5. **Verification budget (every non-Throwaway project).** Open `plan/workplan.md` with a `## Verification budget` block and copy it into the README's contributor notes or `AGENTS.md`: (a) no tests, evals or diagnostics between implementation steps; build the whole batch, then check it once at the batch boundary; (b) run only the checks that cover the changed batch, and never repeat an unchanged suite; (c) all generated test data goes to one temp directory, capped at 5,000 files and 500 MB by default, preferring one aggregate file to many, and deleted on success, failure and interrupt; (d) one diagnostic batch per failure, and no new diagnostic script without a written hypothesis; (e) no new process tooling (receipts, provenance, locks) until a feature it gates exists. SUBSTANCE.md §3 items 9 and 10 are the source. Add `.artifacts/` and `tmp/` to `.gitignore`.
6. **Systems-level projects** (engines, servers, runtimes, kernels, compilers, protocols — anything where speed is a goal): order the batches **Feature complete → Benchmark → Optimise** (Chirag, 2026-10-10: get it working first, improve later). The Feature batch ends at parity with the named reference system, written as a matrix. Benchmark compares against that reference and tunes nothing. Optimise starts only after a benchmark number exists. Put every speed idea in `## Parked` under an `Optimise` label until then. Accuracy bars still apply in every phase; optimisation never trades them away.

## Phase 7 — Brief, then start

```
Scaffolded <name>.

Folder: <absolute path>
Repo: <url> (<private|public>)
Scope (from handoff): <1–2 line summary>
Prior art (vault): <note slugs, or "none">

Top chunk — "<title>" (<size>):
  - <item>
  - <item>
  - <item>

Blocking (if any):
  - <open question>
```

End with *"Starting on **"<chunk title>"** — redirect me if you'd rather read the handoff first."* and begin. The brief is a veto window, not a questionnaire.
