---
description: "Sweep a project for orphaned model checkpoints, stale downloads, and dead artifacts; proposes deletions, read-only."
argument-hint: "[path, default current repo | apply <id>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write"]
entry: "a repo or directory that has accumulated build outputs, downloads, or model files"
exit: "ranked reclaim-workplan written; nothing deleted without an explicit per-item `apply`"
writes: "plan/reclaim-<date>.md; deletes only on explicit `apply <id>`, logged with bytes freed"
---

Projects quietly grow hundred-MB-to-multi-GB artifacts — a downloaded model
checkpoint, a training run's output, a sample dataset, a one-off archive
someone unzipped and forgot. `.gitignore` hides them from git, not from disk,
and over dozens of projects that's real space. `/maintain-nt` already sweeps
the *regenerable* class (`node_modules`, venvs) that's always safe to delete.
This is the harder class: files that might be someone's only copy, so it
proposes and never assumes.

**READ-ONLY by default.** Finds, ranks, and writes a workplan. Deletes nothing
without a per-item `apply <id>` naming the exact finding.

`$ARGUMENTS`: a path to scope the sweep (default: current repo root). `apply
<id>` deletes exactly the finding with that ID from the most recent
`plan/reclaim-*.md` in this repo — nothing else, no bulk apply.

If the current directory isn't a git repo, ask which project or path to sweep.

## Phase 1 — Find candidates

Walk the target path for files/directories ≥50MB that are **not tracked by
git** (gitignored or simply untracked) — a tracked large file is the user's
deliberate choice and out of scope here.

```bash
find "$TARGET" -type f -size +50M 2>/dev/null | while read -r f; do
  git -C "$TARGET" check-ignore -q "$f" 2>/dev/null && echo "$f"
  git -C "$TARGET" ls-files --error-unmatch "$f" >/dev/null 2>&1 || echo "$f"
done | sort -u
```

Common shapes worth naming explicitly in the report: model weights
(`.safetensors` `.gguf` `.bin` `.pt` `.ckpt` `.onnx` `.mlx`), archives (`.zip`
`.tar.gz` `.dmg` `.pkg`), datasets, rendered output (video/audio/image dumps
from a generation run), and disk images (browser profiles, emulator images).

## Phase 2 — Judge before proposing

A large orphaned file is a candidate, not yet a finding. Check, in order of
how much confidence each buys:

- **Already consolidated elsewhere** — if `~/Models` exists as this machine's
  canonical weight store (per this user's convention: symlink the real file
  in, leave a symlink at the original path), a *real* (non-symlink) weight
  file sitting in a project is drift, not a deliberate copy. High confidence.
- **Duplicate** — same filename + byte size (or a quick hash if the file is
  small enough to hash cheaply) exists elsewhere already kept. High
  confidence — the other copy survives the delete.
- **Unreferenced** — `grep -rl` the filename (and, for a checkpoint, its
  containing directory name) across the repo's source and config. No hit
  raises confidence; a hit in an active code path drops it to Low regardless
  of size or age.
- **Project staleness** — check `plan/history.md`'s latest dated entry, or
  `git log -1 --format=%cd` on the repo, against today. An artifact in a
  project untouched 90+ days is a stronger candidate than one in a project
  worked on this week.

Rank confidence **High / Medium / Low** from these signals — don't collapse
them into a single score, list which signals fired so the report is checkable.

## Phase 3 — Rank and write the report

Assign stable IDs (`R1, R2, …`). Each finding: `**ID** path (size) —
confidence · signals that fired · why it's likely safe or not`. Sort by
size descending within each confidence tier, High first.

**Write `plan/reclaim-YYYY-MM-DD.md`**, forward-pass-nt's report shape:
1. Header — target path, date, total bytes scanned, total reclaimable bytes.
2. Findings by confidence tier (High → Medium → Low), each with its `apply`
   command spelled out literally: `` `apply R3` `` or the raw `rm` a human could
   run by hand instead.
3. **Never propose** deleting anything git-tracked, anything under `.git/`,
   or anything smaller than the threshold — say so if the sweep found nothing.
4. Coverage note — paths skipped (permissions, symlink loops) if any.

Print to chat: total reclaimable, the top 5 findings by size, and the
confidence breakdown. Keep the full list in the file.

## Phase 4 — Apply, one item at a time

`apply <id>` re-reads the finding, shows the exact path and size once more,
deletes it, confirms with `df` or a re-run `du` on the parent that the space
is gone (macOS: a `du` drop can lag behind an `rm` until reboot — say so
rather than reporting a mismatch as a failure), and appends the result to the
report under `## Applied`: ID, path, bytes freed, timestamp. No `apply-all`;
each deletion is a separate, deliberate call naming its ID.

## Impact declaration

`plan/reclaim-<date>.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. A High-confidence finding left un-applied by the end of the run is worth a `pending.md` line so it isn't lost between sessions.
