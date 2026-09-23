<h1 align="center">ntkit</h1>

<p align="center">
  <strong>Twenty-three Claude Code skills that give an agent the discipline it's missing — remembers decisions, audits the whole app, and never says "done" without a verifier.</strong>
</p>

<p align="center">
  Plain markdown skills. No install, no server, no account — copy into <code>.claude/skills/</code>.
</p>

<p align="center">
  <a href="../../releases/latest"><img alt="latest release" src="https://img.shields.io/github/v/release/NakliTechie/ntkit?style=flat-square&color=0891b2"></a>
  <a href="LICENSE"><img alt="MIT" src="https://img.shields.io/badge/license-MIT-0891b2?style=flat-square"></a>
  <img alt="install: copy-paste" src="https://img.shields.io/badge/install-copy--paste-0891b2?style=flat-square">
  <img alt="account: none" src="https://img.shields.io/badge/account-none-0891b2?style=flat-square">
</p>

![ntkit workflow map — 23 Claude Code skills across five phases, plus a daily session loop and a knowledge vault used at every phase](assets/workflow.png)

## Install

| | |
|---|---|
| **All your projects** | `cp -r ntkit/skills/* ~/.claude/skills/` |
| **One project** | `cp -r ntkit/skills/* <project>/.claude/skills/` |

```bash
git clone https://github.com/NakliTechie/ntkit && cd ntkit
cp -r skills/* ~/.claude/skills/
```

Command name = the folder name (`skills/forward-pass-nt/` → `/forward-pass-nt`). No config file to write, no account, no restart — the next Claude Code session in any repo already sees every command. Nothing to point it at yet? Run this one first, on the repo you're in now — read-only, nothing written until you ask: `/forward-pass-nt`

## Why

Your agent forgets what it decided yesterday. It reviews the diff, never the app it sits inside. It tells you a fix is "done" when nothing ran to check, and starts cold every session because nothing wrote down where the last one stopped.

ntkit is twenty-three skills that add that discipline: a `plan/` folder each repo keeps that every command reads and writes, a cold whole-app audit that hands back a real fix-workplan, and a report format that won't let "done" through without a verifier behind it.

**Use a single `CLAUDE.md`** if your project is small enough that one file of standing instructions is the whole picture. **Use [pi-workflows](https://github.com/osolmaz/pi-workflows)** for the six-point authoring standard alone, without ntkit's `plan/` state machine and report format on top — [`AUTHORING.md`](AUTHORING.md) borrows its shape. **Use your agent's own memory** if you only need continuity inside one long session, not across days or repos.

## The convention

Most commands share one idea: a gitignored `plan/` folder per repo, three files — `history.md` (decisions · log · dead ends), `pending.md` (now · parked · open questions), `workplan.md` (chunked, checkboxed work). Commands read and write those files, so every session picks up exactly where the last one left off.

`-nt` is just the namespace (NakliTechie), so these don't collide with your own commands — rename freely. `/standup-nt` reports on every repo with a `plan/`; run it first thing, most days.

## Give it a memory

Two commands work a personal knowledge vault — plain markdown, git-backed, separate from any one repo's `plan/`. `/capture-nt <url|file>` checks what you already have before it fetches, then writes a schema'd source note and links it into the right topic map. `/ask-nt <question>` answers only from what's in the vault, with citations — a search over things you already decided were worth keeping, not the open web.

The convention: check the vault before the web. `/lab-nt`'s research phase and `/scaffold-nt` sizing up a new project both run `/ask-nt` first, then `/capture-nt` the result — so the second time a question comes up, it's already answered. No vault at `~/Code/knowledge`? Both degrade to "search the web," and nothing else in the kit depends on either existing.

## Scheduling

Two commands run without you. `/maintain-nt` weekly — read-only rot detection, ideal cron work. `/autopilot-nt` nightly — worktree-isolated, ships a green gate to main, holds a red one on its own branch.

```cron
0 7 * * 1  cd ~/code/myproject && timeout 30m claude -p "/maintain-nt" --dangerously-skip-permissions >> ~/.ntkit-cron.log 2>&1
0 2 * * *  cd ~/code/myproject && timeout 6h claude -p "/autopilot-nt" --dangerously-skip-permissions >> ~/.ntkit-cron.log 2>&1
```

`--dangerously-skip-permissions` is exactly what it says — only schedule commands with their own guardrails. A scheduled run still ends at a human: the morning report is what `/resume-nt` reads.

## Commands

```
/scaffold-nt            # new project — bootstrap folder + git + remote + seeded plan/
/standup-nt             # start of day — scan every repo with plan/, active / idle / stale
/resume-nt              # start of session — read the handoff, name the state, wait or go
/decide-nt "<why>"      # mid-session — append a dated one-line decision
/soc-nt "<thought>"     # mid-build — raw stream-of-consciousness; replan-nt triages later
/autopilot-nt           # anytime — work a fix-workplan or goal, unattended, in its own worktree
/lab-nt                 # research — shape an idea into a falsifiable contract, run bounded legs
/forward-pass-nt        # anytime — fresh-eyes whole-app audit, batched fix-workplan
/walkthrough-nt         # anytime — drive each role in a real browser, fix bugs, leave a harness
/ux-review-nt           # anytime — cold first-timer review, ranked onboarding/nav failures
/maintain-nt            # upkeep — stale deps / Actions / advisories / links; safe fixes applied
/reclaim-nt             # upkeep — orphaned checkpoints / downloads / artifacts; proposes deletions
/live-check-nt          # verifying → shipped — the real deployed runtime, machine evidence
/harden-nt              # before "ready" — map a surface's paths, harden each in rounds
/guide-nt               # anytime — walk each role, build a single-file searchable HTML guide
/demo-nt                # live demo — boot on the shared seed, open an interactive explorer
/package-nt             # launch — ship-readiness gate, screenshots, drafted launch posts
/release-nt             # launch — semver bump, CHANGELOG, tag, push, verify the deploy live
/windup-nt              # end of session — day summary, pending, commit / push, tomorrow's handoff
/replan-nt              # occasionally — fold accumulated files back into the three canonical ones
/notify-nt              # after a run — desktop notification + optional phone push
/capture-nt <url|file>  # save something into the knowledge vault; commits + pushes
/ask-nt <question>      # recall something from the vault, read-only, with citations
```

## Verify it yourself

```bash
for f in skills/*/SKILL.md; do
  for k in description entry exit writes; do
    grep -q "^$k:" "$f" || echo "missing $k: $f"
  done
done
```

Every skill's frontmatter states its contract — `entry`, `exit`, `writes` — so a run that can't satisfy `entry` refuses instead of proceeding politely, and `exit` names a check, not a vibe. The command above prints nothing when that contract holds across all 23; [`AUTHORING.md`](AUTHORING.md) is the standard it's checked against.

## License

MIT © Chirag Patnaik. See [LICENSE](LICENSE).

The doctrine: [AUTHORING](AUTHORING.md) · [STATES](STATES.md) · [ATTEST](ATTEST.md) · [SUBSTANCE](SUBSTANCE.md) · [MEMORY](MEMORY.md) · [DRIVER](DRIVER.md) — what changed: [CHANGELOG.md](CHANGELOG.md) · [github.com/NakliTechie](https://github.com/NakliTechie)
