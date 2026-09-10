# ntkit

**The rigor layer for AI-assisted development.**

Coding agents write code well. They're bad at everything around it: remembering decisions, picking up mid-thought, auditing the whole app instead of just the diff, reporting "done" when nothing verified it.

`ntkit` is twenty-two [Claude Code](https://docs.claude.com/en/docs/claude-code) skills — slash commands — that add that discipline, across every repo you run.

<p align="center">
  <img src="assets/workflow.png" alt="ntkit workflow map — 22 Claude Code skills across six phases: start, open, build, review, ship, close, plus a daily session loop and a knowledge-vault pair" width="840">
</p>

## The convention

Most commands share one idea: a gitignored `plan/` folder per repo, three files.

- `history.md` — Decisions · Log · Dead ends
- `pending.md` — Now · Parked · Open questions
- `workplan.md` — chunked, checkboxed work

Commands read and write those files. Every session picks up where the last one left off.

> `-nt` is just the namespace (NakliTechie), so these don't collide with your own commands. Rename freely.

## Commands

| Command | When | What it does |
|---------|------|--------------|
| `/scaffold-nt` | new project | Bootstrap from a handoff: folder + git + remote + seeded `plan/` + first-move brief. |
| `/standup-nt` | start of day | Scan every repo with `plan/` — active / idle / stale, next move for each. |
| `/resume-nt` | start of session | Read the handoff, name the repo's state, wait — or `go` to start the top chunk. Read-only. |
| `/decide-nt "<why>"` | mid-session | Append a dated one-line decision to `history.md`. |
| `/soc-nt "<thought>"` | mid-build | Raw stream-of-consciousness into `plan/soc.md`. `/replan-nt` triages it later. |
| `/forward-pass-nt` | anytime | Fresh-eyes whole-app audit → a batched, checkboxed fix-workplan. |
| `/walkthrough-nt` | anytime | Drive each role's journeys in a real browser, fuzz the gaps between them, fix bugs as found, leave a rerunnable verification harness. |
| `/guide-nt` | anytime | Walk each role's features in a browser, build a single-file searchable HTML guide. |
| `/demo-nt` | live demo | Boot the app on the shared demo seed, open an interactive feature explorer. |
| `/ux-review-nt` | anytime | Cold-first-timer review: wipe state, walk it as a new user, flail like one, rank onboarding/nav failures + a11y/perf. |
| `/live-check-nt` | verifying → shipped | Drive the real deployed runtime with a real gesture; machine evidence it actually works. |
| `/harden-nt` | before "ready" | Map the paths a surface claims to support, then work the map in rounds with independent agents from different model families — constructive rounds prove a path holds, adversarial rounds find the paths the map missed. Every failure is fixed and left behind a check proven able to go red. |
| `/autopilot-nt` | anytime | The executor — works a fix-workplan or goal to completion, unattended, in its own worktree. Ships green, holds red. |
| `/lab-nt` | research | The discoverer — shapes an idea into a falsifiable contract, runs bounded experiment legs, journals every attempt. |
| `/notify-nt` | after a run | Desktop notification + optional phone push. |
| `/maintain-nt` | upkeep | Stale deps / Actions / advisories / dead links → a ranked fix-workplan; safe fixes applied automatically. |
| `/release-nt` | launch | Semver bump, CHANGELOG, tag, push, GitHub release, verify the deploy landed live. |
| `/package-nt` | launch | Ship-readiness gate, marketing screenshots, drafted launch posts. Drafts, never posts. |
| `/windup-nt` | end of session | Day summary, pending, commit/push, tomorrow's handoff. |
| `/replan-nt` | occasionally | Fold accumulated files back into the three canonical ones; archive the rest. |

They hand off in sequence: `/windup-nt` writes what `/resume-nt` reads; `/forward-pass-nt` and `/walkthrough-nt` feed `/replan-nt`; `/soc-nt` feeds `/replan-nt`'s triage.

> `/spar-nt` was renamed to `/harden-nt` in v1.3; the alias was removed in v1.5.

## The state machine

`plan/` is state. Commands are events. [`STATES.md`](STATES.md) names six session states (`fresh → briefed → building → verifying → blocked / shipped`) and which commands are legal from which.

Four rules enforce it:

- **Every command declares its contract** — `entry`, `exit`, `writes` in frontmatter. A failed entry refuses, it doesn't proceed politely. See [`AUTHORING.md`](AUTHORING.md).
- **Records append, only the reconcile pass rewrites** — [`MEMORY.md`](MEMORY.md) splits `plan/` into append-only records and derived files projected over them, so the plan can be rebuilt from the log. `plancheck` reports the drift between them.
- **"Done" is the verifier's word**, never the agent's.
- **Overrides are logged**, via `/decide-nt`. Bypassed on purpose is a decision; bypassed by drift is a bug.
- **Asks are reserved for the unanswerable.** Everything else takes the safe default and logs it.

## The report format

[`ATTEST.md`](ATTEST.md) keeps evidence standards active at every length. Full typed-block formatting applies only to designated formal reports and handbacks exceeding approximately 200 characters before formatting: audits, release-readiness gates, unattended-run handbacks, or outputs explicitly requested in ATTEST. Shorter outputs, ordinary discussion, progress updates, routine coding handbacks, and questions use natural prose. The scope ends with the designated output; reading ATTEST does not switch the whole conversation into that format. Existing approval and execution boundaries remain unchanged.

## Built for the driver

[`DRIVER.md`](DRIVER.md) governs what these commands *build*: everything ships agent-ready. A design pass — [@doodlestein](https://x.com/doodlestein)'s [prompt](https://x.com/doodlestein/status/2094288037458882668), used in toto (his agentic-development work: [github.com/Dicklesworthstone](https://github.com/Dicklesworthstone)) — run once a first spec exists; `/scaffold-nt` seeds it into every new workplan.

Ten principles: one perception act, machine-decidable outputs, one verdict per next action, bounded output, failures that name their remedy, crash-safety, the tool holding the memory, accretion by mechanism, a tower of abstractions, a fail-closed evaluator outside the loop.

[`DRIVER-HARNESS.md`](DRIVER-HARNESS.md) is the operational companion: the loop that *builds* an agent surface (DRIVER) then *hardens* it (`/harden-nt`), plus the cold-runner harness neither owns on its own — heterogeneous isolated verifiers, kill-by-port + liveness canary, explore-vs-verify rounds, a mission-brief template — and a paste-in prompt to run the whole thing in a fresh project. Distilled from one full retrofit (eighteen cold rounds).

## What the plan is made of

[`MEMORY.md`](MEMORY.md) is the memory contract for `plan/`. Records (reports, summaries, `soc.md`) are append-only; the derived files (`pending.md`, `workplan.md`) are a projection over them that only `/replan-nt`, `/windup-nt`, and `/scaffold-nt` may rewrite. Records declare an `## Impact`; derived items carry `[from: <record>]` provenance; `plancheck` compares the two and reports **orphans** (state from nowhere) and **ghosts** (work silently dropped). Untagged items mean hand-written, so every existing `plan/` folder is already valid — this is additive, not a migration.

## What counts as progress

[`SUBSTANCE.md`](SUBSTANCE.md) says what counts as delivered. No process theater — an artifact earns its place only as a real gate. Most open items must deliver runnable behavior. Never fake a test or close undone work. A refusal is honest but never counts as delivery.

## Knowledge vault

Two commands work a personal knowledge vault instead of a repo's `plan/` — plain-markdown, git-backed. One rule: sources (what *they* said) stay separate from notes (what *you* concluded).

| Command | When | What it does |
|---------|------|--------------|
| `/capture-nt <url\|file>` | save something | Orient first — already captured? what's it near? which tags exist? — then fetch, extract, write a schema'd source note, link it into a topic map, commit + push. |
| `/ask-nt <question>` | recall something | Ranked search across the vault, answer grounded only in your notes, with citations. Read-only. |

`/capture-nt` checks **before** it fetches. That ordering is the whole point: it catches the source you already have (the capture becomes an update, not a duplicate note) and offers the tags its neighbours already carry, so tag cardinality stops drifting up one novel label at a time.

Both work with nothing but `rg`. If your vault ships an optional index at `bin/vaultdb.py`, they use it instead — ranked relevance rather than an unordered file list, plus the neighbour and tag suggestions above — and fall back cleanly when it is absent. Such an index should be **derived and gitignored**, rebuilt from the markdown on every run: the notes stay canonical, and a stale index that looks authoritative is worse than no index.

Both expect a vault at `~/Code/knowledge` — edit the path in `skills/capture-nt/SKILL.md` and `skills/ask-nt/SKILL.md` if yours differs.

**The convention: check the vault before the web.** Any command that needs prior art — `/lab-nt`'s Phase 0 sweep, `/scaffold-nt` sizing up a new project, a research detour mid-build — runs `/ask-nt` first. This is not a claim that web search is weak. It is that the vault is **curated** and **opinionated**: its `sources/` are things you already decided were worth keeping, and its `notes/` are conclusions *you* reached and wrote down — including the ones that cut against the consensus a search returns. A search gives you what is true in general. The vault gives you what you concluded, on your stack, under your constraints, and no amount of searching reproduces that. `/ask-nt` is read-only and costs one command, so checking first is close to free.

Then search the web for what the vault does not have — and `/capture-nt` the result, so the next run does not have to search at all. That is the whole point of keeping one: the loop closes, and the second time a question comes up it is already answered.

No vault? These commands degrade to "search the web," and nothing else in the kit depends on it.

## Install

```bash
git clone https://github.com/NakliTechie/ntkit
cp -r ntkit/skills/* ~/.claude/skills/                 # all projects
# or:  cp -r ntkit/skills/* <project>/.claude/skills/  # one project
```

Command name = the folder name (`skills/windup-nt/` → `/windup-nt`). First run offers to gitignore `plan/`. Set your scan root at the top of `skills/standup-nt/SKILL.md` if you don't keep repos under `~/Code`.

Each skill is one `SKILL.md`. The seven largest (`autopilot`, `walkthrough`, `guide`, `forward-pass`, `capture`, `windup`, `harden`) are a short router plus a `references/` folder that Claude reads phase by phase, so a run only loads the part it is in. Descriptions are capped at 15 words: Claude Code lists every installed skill's description in context each session, and that listing has a budget.

**Upgrading from v1.3 or earlier:** the files moved from `commands/` to `skills/`. Delete your old copies (`rm ~/.claude/commands/*-nt.md`) — a skill and a command with the same name would otherwise both be listed.

## Scheduling

Two commands run without you.

- **`/maintain-nt` weekly** — read-only rot detection, ideal cron work.
- **`/autopilot-nt` nightly** — worktree-isolated, ships a green gate to main, holds a red one on its branch.

```cron
0 7 * * 1  cd ~/code/myproject && timeout 30m claude -p "/maintain-nt" --dangerously-skip-permissions >> ~/.ntkit-cron.log 2>&1
0 2 * * *  cd ~/code/myproject && timeout 6h claude -p "/autopilot-nt" --dangerously-skip-permissions >> ~/.ntkit-cron.log 2>&1
```

`--dangerously-skip-permissions` is exactly what it says — only schedule commands with their own guardrails. `timeout` is the outer budget. A scheduled run still ends at a human: the morning report is what `/resume-nt` reads next.

## The one to try first

`/forward-pass-nt`. Reads the whole app cold, hands back an ordered fix-plan with stable finding IDs — the kind of thing you actually work through.

## The name

`nt` = NakliTechie, `kit` = what it is. Started as one-off prompts in [NakliTechie/prompts](https://github.com/NakliTechie/prompts), spun out into its own repo in June 2026.

## NakliTechie

*Nakli* (नकली) is Hindi for "fake" — **NakliTechie** is the maker handle of **[Chirag Patnaik](http://www.chiragpatnaik.com)**. Mostly single-file browser apps, no accounts, no servers, no data leaving your device. Current focus: small-language-model training and distributed inference.

- 🖥️ **[NakliOS](https://naklios.dev/)** — a whole desktop in your browser
- 🗂️ **[All projects](https://naklitechie.github.io/)** · **[github.com/NakliTechie](https://github.com/NakliTechie)**
- ✍️ **[chiragpatnaik.com](http://www.chiragpatnaik.com)** · **[naklitechie.com](https://naklitechie.com)** · **[Substack](https://naklitechie.substack.com/)**

Siblings worth a look: **[LocalMind](https://naklitechie.github.io/LocalMind/)**, **[VaultMind](https://vaultmind.naklitechie.com/)**, **[Private Mesh](https://github.com/NakliTechie/private-mesh)**.

## License

MIT © Chirag Patnaik. See [LICENSE](LICENSE).
