---
description: "Sweep a project for orphaned model checkpoints, stale downloads, and dead artifacts; proposes deletions, read-only."
argument-hint: "[path, default current repo | apply <id>]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Write"]
entry: "a repo or directory that has accumulated build outputs, downloads, or model files"
exit: "ranked reclaim-workplan written; nothing deleted without an explicit per-item `apply`"
writes: "plan/reclaim-<date>.md; moves to the Trash only on explicit `apply <id>`, logged with bytes moved"
---

Projects quietly grow hundred-MB-to-multi-GB artifacts — a downloaded model
checkpoint, a training run's output, a sample dataset, a one-off archive
someone unzipped and forgot. `.gitignore` hides them from git, not from disk,
and over dozens of projects that's real space. A deterministic scanner sorts
the space into two tiers: the *regenerable* tier (build output, `node_modules`,
caches) that a tool writes again, and the *judge* tier (weights, worktrees,
old archives, stale experiments) that might be someone's only copy. The
judgment goes only to the second tier, which this skill proposes and never
assumes.

**READ-ONLY by default.** Finds, ranks, and writes a workplan. Removes nothing
without a per-item `apply <id>` naming the exact finding, and then only to the
Trash, through disktree's removal guards.

`$ARGUMENTS`: a path to scope the sweep (default: current repo root). `apply
<id>` trashes exactly the finding with that ID from the most recent
`plan/reclaim-*.md` in this repo — nothing else, no bulk apply.

If the current directory isn't a git repo, ask which project or path to sweep.

## Phase 0 — The scanner

The sweep runs on **`disktree-cli`**, the headless side of
[disktree](https://github.com/NakliTechie/disktree) (a fork of
`tobi/disktree` with the weights, archive and store findings this skill
needs). It measures what deleting gives back (`st_blocks`, hardlinks once,
hidden folders included, one volume), knows what a directory *is*, and
removes only through tested guards, and only to the trash.

```bash
command -v disktree-cli || cargo install --git https://github.com/NakliTechie/disktree disktree-cli --root ~/.local
```

No cargo and no binary (a bare cloud box): fall back to the `find` sweep in
`references/find-fallback.md` and say in the report that the scan ran without
disktree.

## Phase 1 — Scan

```bash
STORE=()
[ -d "$HOME/Models" ] && STORE=(--store "$HOME/Models")   # this user's canonical weight store
disktree-cli scan "$TARGET" "${STORE[@]}" --limit 200 > /tmp/reclaim-scan.json
```

The JSON carries `totals`, `space.available`, and `findings[]`, largest
first. Each finding has a `path`, `bytes`, `modified_days`, a `kind`, and a
**`tier`**:

| kind | tier | what it is |
|---|---|---|
| `reclaimable` (`reason`: build output, reinstallable, regenerable, package store, …) | `regenerable` | a tool or a build writes it again |
| `worktrees` (+ `checkouts[].git`) | `judge` | agent worktrees, each with changes / stashes / unpushed |
| `stale_experiments` | `judge` | experiment dirs untouched 30+ days |
| `weights` (+ `copies_in_store`, `copies[]`) | `judge` | a directory holding model weight files |
| `stale_archive` (+ `days`) | `judge` | an archive or disk image untouched 30+ days |

Findings never nest, and anything under `--store` is left out: the store is
kept on purpose. Findings under 64 MB are not listed.

## Phase 2 — Judge only the `judge` tier

The `regenerable` tier needs no judgment beyond one check: if the path is
**git-tracked** (`git -C "$TARGET" ls-files --error-unmatch <path>`), drop
it. Everything else in that tier goes in the report as **Regenerable**,
with its `reason`.

Spend the judgment on the `judge` tier. Check, in order of how much
confidence each buys:

- **Copy in the store** — a `weights` finding with `copies_in_store` equal
  to its `files` is drift: every weight file already sits in `~/Models`
  under the same name and size. High confidence. Partial copies: list
  which files match.
- **Worktree state** — a checkout whose `git.clean` is `true` loses nothing.
  High. Any changes, stashes or unpushed commits: Low, and name them.
- **Unreferenced** — `grep -rl` the directory or file name across the repo's
  source and config. No hit raises confidence; a hit in an active code path
  drops it to Low regardless of size or age.
- **Staleness** — `modified_days`, and the project's own last activity
  (`plan/history.md`'s latest dated entry, or `git log -1 --format=%cd`).
  90+ days untouched is a stronger candidate than this week's run output.

Rank confidence **High / Medium / Low** from these signals. Don't collapse
them into a single score; list which signals fired so the report is
checkable.

## Phase 3 — Rank and write the report

Assign stable IDs (`R1, R2, …`). Each finding: `**ID** path (size) —
tier · confidence · signals that fired · why it's likely safe or not`.
Order: Regenerable first, then the judge tier High → Medium → Low, by size
within each group.

**Write `plan/reclaim-YYYY-MM-DD.md`**, forward-pass-nt's report shape:
1. Header — target path, date, scan totals, `space.available`, total
   reclaimable per tier.
2. Findings, each with its `apply` command spelled out literally:
   `` `apply R3` `` or the raw `disktree-cli trash --root <target> <path>`
   a human could run by hand instead.
3. **Never propose** deleting anything git-tracked, anything under `.git/`,
   or anything inside the store — say so if the sweep found nothing.
4. Coverage note — `totals.unreadable_dirs`, and whether the scan ran on
   disktree or the fallback.

Print to chat: total reclaimable per tier, the top 5 findings by size, and
the confidence breakdown. Keep the full list in the file.

## Phase 4 — Apply, one item at a time

`apply <id>` re-reads the finding, shows the exact path and size once more,
then asks the guards before acting:

```bash
disktree-cli check --root "$TARGET" "<path>"     # must list it under plan.accepted
disktree-cli trash --root "$TARGET" "<path>"     # moves it to the system Trash
```

If `check` puts the path under `plan.blocked`, stop and quote the `reason`.
Never fall back to `rm`. The move is recoverable until the Trash is emptied;
say that the space returns only then, and that emptying the Trash is the
user's step. Record `available_before` / `available_after` from the `trash`
output (macOS can lag, see the diskspace README; report a lag, not a
failure), and append the result to the report under `## Applied`: ID, path,
bytes moved, timestamp. No `apply-all`; each removal is a separate,
deliberate call naming its ID.

## Impact declaration

`plan/reclaim-<date>.md` is a **record**: append-only, never rewritten. The derived files (`pending.md`, `workplan.md`, `history.md`'s `## Decisions` and `## Dead ends`) are a projection over the records, rewritten only by `/replan-nt`, `/windup-nt` and `/scaffold-nt`. (Full contract: [`MEMORY.md`](https://github.com/NakliTechie/ntkit/blob/main/MEMORY.md) in the ntkit repo.) End it with an `## Impact` section saying what should change in the derived files — or that nothing should:

```markdown
## Impact
- pending.md/Now — add: <item this run says belongs on the list>
- none — <reason nothing changes>
```

Declaring the impact is this command's job; **applying** it is `/replan-nt`'s. A High-confidence finding left un-applied by the end of the run is worth a `pending.md` line so it isn't lost between sessions.
