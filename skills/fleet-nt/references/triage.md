## Phase 1 — Triage

Triage reads every repo and changes nothing. It produces one table for the owner, and in `go` or `away` mode it also writes the table to `triage.md` in the fleet folder.

### Find the repos and their open batch

List the direct subfolders of the projects folder that are git checkouts (`find <folder> -mindepth 2 -maxdepth 2 -name .git`). Skip anything under a `.worktrees/` folder, because those are other runs. Apply `only=` and `skip=`.

A repo has an open batch when its `plan/` (a folder or a symlink) holds either:

- an audit report (`*forward-pass*.md`, `*ux-review*.md`) whose Workplan section has a `[ ]` item, or
- `plan/workplan.md` with a `[ ]` item under a chunk or batch heading.

Name the batch `/autopilot-nt` would pick by default: the keystone or top batch of the newest report, else the top chunk of the workplan. A repo with no open batch is left out of the table and counted in one line at the end.

### Classify each repo

Read `plan/pending.md`, the latest `history.md` decisions, and the items of the open batch. Take the first reason that matches, and cite it as `path:line`.

| Verdict | Signal |
|---|---|
| excluded: on hold | `pending.md` or the newest decision says the project is on hold, parked or paused, or waits until a named date that has not come. |
| excluded: owner decision | the batch's keystone item is `[~]` with a needs-you line, or an Open question in `pending.md` blocks it. |
| excluded: exclusive hardware | the batch needs the GPU (training, model runs, Metal, CUDA, MLX, WebGPU timing), a timed benchmark, or another machine or device that only one job can hold. |
| excluded: needs money | the batch needs a paid API, a cloud machine, credits, a top-up or a purchase. |
| excluded: needs a person | the batch needs a camera, a microphone, biometrics, a real phone or device, or the owner's own sign-in. |
| excluded: already active today | the repo has an `autopilot/<today>` branch, a `.worktrees/autopilot-<today>` folder, an autopilot record dated today with no handoff block, or a running agent session the host lists. |
| excluded: not launchable | the default branch's checkout has uncommitted changes, because `/autopilot-nt` needs a clean base branch. |
| excluded: unclear | the signals conflict or the batch's needs cannot be read. Say what is unclear. |
| runnable | none of the above. |

A batch with one GPU item among several others stays runnable: the brief forbids the GPU item and the child parks it.

### Place each repo on a machine

Read `$NT_FLEET_HOME/machines.md` when it exists:

```text
| Machine | Host | Tags |
|---|---|---|
| local | local | mem=24 |
| studio | continuum user@studio.example /srv/continuum | gpu mem=256 |
```

- A runnable repo goes to `local` unless the owner names another machine for it.
- A batch excluded only for exclusive hardware becomes runnable when a machine carries the tag it needs (`gpu`) and no other child holds that resource there. One GPU child per machine; the next GPU repo waits for it to end. The brief names the holder for each machine.
- A remote machine must hold a clean clone of the repo at the same default-branch commit as the local one. When it does not, the repo stays excluded with the reason `not on <machine>`.

With no machines file there is one machine, `local`, and no repo holds a GPU.

### Does a push deploy?

For each runnable repo, check whether a push to the default branch deploys:

- a CI workflow that runs on push to the default branch and calls a deploy step (`wrangler deploy`, `pages deploy`, `vercel`, `netlify deploy`, `fly deploy`, `gh-pages`, a container push);
- a platform connected to the repository that builds on push (Cloudflare Workers Builds or Pages, Netlify, Vercel), which shows as `wrangler.toml` / `wrangler.jsonc`, `netlify.toml` or `vercel.json` together with a project README or notes that say it deploys from git;
- a note in `plan/` or the README that says the default branch is live.

Write `yes`, `no` or `unsure`. Treat `unsure` as `yes`, so that child holds its branch.

### The table

```text
| Repo | Open batch | Verdict | Reason (evidence) | Machine | Push deploys |
|---|---|---|---|---|---|
| alpha | workplan B2 | runnable | — | local | no |
| beta | forward-pass A | excluded: on hold | plan/pending.md:4 "on hold until March" | — | — |
| gamma | workplan C1 | excluded: exclusive hardware | plan/workplan.md:31 GPU training run, no machine tagged gpu | — | — |
```

End with: the count runnable, the count excluded, the count with no open batch, and the launch command that would start the runnable set. In `triage` mode stop here.
