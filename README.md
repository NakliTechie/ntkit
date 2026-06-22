# ntkit

**The rigor layer for AI-assisted development.**

Coding agents are great at writing code and bad at everything around it — remembering what you decided last week, picking a project back up mid-thought, auditing the *whole* app instead of just the diff, shipping without leaking a secret. `ntkit` is eighteen [Claude Code](https://docs.claude.com/en/docs/claude-code) slash commands that add that operational discipline — the opposite of vibe coding — across as many repos as you run at once.

Most share one idea: a **gitignored `plan/` folder** in each repo holding three files —

- `history.md` — Decisions · Log · Dead ends
- `pending.md` — Now · Parked · Open questions
- `workplan.md` — chunked, checkboxed play

The commands read and write those files, so every session picks up exactly where the last one left off. A separate pair — `/capture-nt` and `/ask-nt` — works the other side of the desk: a personal **knowledge vault** you capture into and ask questions of (see [below](#knowledge-vault)).

> The `-nt` suffix is just the namespace (NakliTechie) — it keeps these from colliding with your own commands. Rename freely.

| Command | When | What it does |
|---------|------|--------------|
| `/scaffold-nt` | new project | Bootstrap from attached handoff materials (md/zip): local folder + git + remote repo + seeded `plan/` + a brief on the first move. |
| `/standup-nt` | start of day | Scan every repo with a `plan/` folder → active / idle / stale, each with its next move. Pick one. |
| `/resume-nt` | start of session | Read the handoff (workplan + pending + history + latest summary + git state), brief you, and wait. Read-only. |
| `/decide-nt "<why>"` | mid-session | Append a dated one-line decision to `history.md`. Captures the *why* before it evaporates. |
| `/idea-nt "<idea>"` | anytime | Park a future-work idea into the backlog (`plan/ideas.md`, or `IDEAS.md` if present) — the `/decide-nt` pattern, for ideas. Friction-free, no derailing the current task. |
| `/forward-pass-nt` | anytime | Fresh-eyes whole-app audit — bugs / security / stray code — that outputs a **batched workplan**, not a findings dump. Writes `plan/forward-pass-<date>.md`. |
| `/walkthrough-nt` | anytime | Live counterpart to `/forward-pass-nt`: identify each user role, drive the running app through their journeys **in a real browser**, catch logical errors as they surface, and **fix them**. Writes `plan/walkthrough-<date>.md`. |
| `/guide-nt` | anytime | Documentation sibling of `/walkthrough-nt`: walk each role's features **in a browser capturing screenshots**, then build a single-file **searchable HTML guide**. Regenerates from a committed generator — never hand-edits the output. |
| `/demo-nt` | live demo | Presenter mode for showing WIP to customers/execs — boot the app with the **shared demo seed** (the same asset `/walkthrough-nt` + `/guide-nt` use) and open an interactive **explorer** (features · connections · deps, drill-down + inline search), then hand you clickable links to both the live app and the explorer. |
| `/ux-review-nt` | anytime | Cold-first-timer UX review: wipe all state, walk the app **as a brand-new user**, and report where build-order accretion fails the newcomer (arrival, onboarding, nav/IA) — plus a Lighthouse a11y + perf pass. Read-only; proposes an ideal first-run + IA. Writes `plan/ux-review-<date>.md`. |
| `/execute-nt` | anytime | Work a batched fix-workplan from a `/forward-pass-nt` / `/ux-review-nt` / `/maintain-nt` report — fix + verify each item, check it off, log the SHA, pause between batches. The **executor** for static findings. |
| `/maintain-nt` | upkeep | Maintenance sweep — outdated/deprecated deps, stale GitHub Actions, security advisories, dead links, lockfile drift → a ranked fix-workplan. Read-only (offers safe quick-fixes). Writes `plan/maintenance-<date>.md`. |
| `/release-nt` | launch | Cut a release — suggest a semver bump from the commits, write `CHANGELOG.md`, draft notes, then on confirm tag + push + GitHub release + deploy. The mechanics, where `/package-nt` is the marketing. |
| `/package-nt` | launch | Ship a project to the world — the bookend to `/scaffold-nt`: a deep readiness gate (`/security-review` + `/forward-pass-nt` + a secrets + essentials check), social-framed screenshots (committed to `marketing/`), and drafted X / LinkedIn / Show HN / subreddit collateral (local). **Drafts, never posts.** |
| `/windup-nt` | end of session | Day summary + pending + workplan + push + tomorrow's handoff. |
| `/replan-nt` | occasionally | Fold accumulated summaries + scratch back into the three files; archive the rest. |

They speak one vocabulary, so each hands off to the next: `/windup-nt` writes what `/resume-nt` reads, `/forward-pass-nt` and `/walkthrough-nt` feed `/replan-nt`, `/decide-nt` feeds `history.md`.

## Knowledge vault

Two commands operate on a single Obsidian-compatible **knowledge vault** (plain-markdown, git-backed) instead of a repo's `plan/` folder — the write and read halves of a second brain. They keep one rule: **sources** (what *they* said) stay separate from **notes** (what *you* concluded).

| Command | When | What it does |
|---------|------|--------------|
| `/capture-nt <url\|file>` | save something | Fetch + extract a URL / file / PDF (full text, OCR for scans), **follow & fully index any referenced repo or arXiv paper**, write a schema'd **source note**, tag its realm (knowledge / personal / work), link it into the right topic map with backlinks, and optionally promote a distilled **note** — then commit + push. Idempotent on re-run. |
| `/ask-nt <question>` | recall something | Search + read the vault and answer **grounded only in your own notes**, with citations to the notes used. The read-side sibling of `/capture-nt` — the "search" half of your personal Google. Read-only. |

Both expect a vault at `~/Code/knowledge` (edit that path at the top of `commands/capture-nt.md` and `commands/ask-nt.md` if yours lives elsewhere).

## Install

```bash
git clone https://github.com/NakliTechie/ntkit
cp ntkit/commands/*.md ~/.claude/commands/                 # available in all projects
# or:  cp ntkit/commands/*.md <project>/.claude/commands/  # just one project
```

The command name is the filename without `.md` (`windup-nt.md` → `/windup-nt`). First run will offer to add `plan/` to your `.gitignore`. If you don't keep repos under `~/Code`, set your scan root at the top of `commands/standup-nt.md`.

## The one to try first

`/forward-pass-nt`. Every other review tool looks at your diff; this one reads the whole app cold and hands back an ordered, checkboxed fix-plan with stable finding IDs — the kind of thing you actually work through instead of skim once.

## License

MIT © Chirag Patnaik. See [LICENSE](LICENSE).
