# Authoring a command

Every `-nt` skill (`skills/<name>/SKILL.md`) is a prompt with a contract. This file is the standard for
writing a new one — and the checklist for reviewing a change to an existing one.
It exists because twenty commands drifting apart in shape is how a kit rots; one
shape is how they stay composable. (The six-point idea is ported from the
built-in-skill standards in [osolmaz/pi-workflows](https://github.com/osolmaz/pi-workflows),
folded into ntkit's own doctrine.)

The three pillars bind what a command *does*: it transitions state per
[`STATES.md`](STATES.md), reports per [`ATTEST.md`](ATTEST.md) section 0's selective scope, and delivers
per [`SUBSTANCE.md`](SUBSTANCE.md). This file binds how a command is *written*.

## 1. Declare the contract in frontmatter

Non-negotiable — it is STATES guard #1. Every command's frontmatter carries:

- `name` matches the skill directory. Use the [Agent Skills format](https://agentskills.io/specification) so clients can discover the same files.
- `description` — **15 words or fewer**: the trigger (when to reach for it) and its side effect (read-only? drafts only? pushes?). Every installed skill's description sits in context every session under a shared budget; a long one crowds the others.
- `metadata.argument-hint` — the expected invocation text, with an example.
- `allowed-tools` — a space-separated string with the smallest set the command actually uses. A read-only command lists no `Write`.
- `metadata.entry` — the state + artifacts it requires. If they are absent the command says so and stops; it never proceeds politely.
- `metadata.exit` — the **machine-checkable** condition that means it finished. Not "did the work" — the check that proves it.
- `metadata.writes` — every `plan/` file it touches, or `nothing`.

`entry` / `exit` / `writes` are what make the state table enforceable instead of
decorative. A command that cannot state its exit as a check does not have one yet.

## 2. Document every input that changes behavior

For each input — in the invocation or an environment variable — that affects **scope, authority,
safety, routing, or completion**, name it in the body with its **default**. An
input whose default the reader cannot find is a trap. Prefer a safe default the
command *announces and logs* over an input it *polls the user* for (guard #4).

## 3. Authority is opt-in — default-deny

Any power to act irreversibly on the world — **push, merge, release, deploy,
delete, send, post, spend** — is granted per run and **defaults to denied when
unstated**. A command never assumes it. Reversible, in-repo work (edit, commit to
a branch, write `plan/`) needs no grant. This is the authoring face of STATES
guard #4: the safe default for outward-facing power is *off*, and the command asks
or refuses rather than assuming yes. `/reclaim-nt` models it — the sweep is
read-only, and nothing moves to the Trash without a per-item `apply`.

## 3.5 Clean up what you created

A command that creates anything outside the repo (a cloud instance, an endpoint,
a volume, a tunnel, a launchd agent, a scheduled job) ends with a teardown step
and a **what stays** list: each resource that survives the run, why, and the
command that removes it. Teardown removes only what this run created, never what
it found running. Secrets and published artefacts are listed, not deleted:
deleting them is authority (§3). `/demo-nt`'s "After a demo" section and
`/lab-nt`'s leg report are the house examples. (From the teardown phase in
[jaredpalmer/kev](https://github.com/jaredpalmer/kev) `skills/kev-finetune`, Apache-2.0.)

## 4. One complete, valid example

Give at least one invocation the reader can copy, with obvious placeholders
(`<repo>`, `<message>`), that would actually run start to finish. An example that
omits a required input teaches the wrong shape.

## 5. Assemble input before you act

Gather every required input first, validate, then execute. Do not half-run and
stop in the middle to ask for what you could have checked up front. The one time
to ask is when a required input is missing and *underivable*, or the action is
outward-facing — guard #4.

## 6. Guard the state, don't nest actors

- Declare which states the command is legal in (the STATES table) and refuse on entry-fail **with the reason**.
- Do not launch a second long-running actor (`/autopilot-nt`, `/lab-nt`) inside the same worktree — the actor rule is one run per worktree, mailbox-only. Compose by **handoff artifact**, not by nesting.
- A guard yields only to a logged `/decide-nt` override — bypassed on purpose with a reason, never by drift.

## 7. Brief by state, not by playbook

A subagent's brief carries only what its current state can act on — the item's
spec and how to check it, not the maker's reasoning; the contract and journal,
not the loop's opinions (the autopilot verifier and the lab critic are the house
examples). Gate instructions on their preconditions instead of front-loading the
full playbook, and when the subagent errs, answer with a targeted hint for a
retry — scaffolding that never enters the record. A brief the actor can't yet
use is noise now and contamination later.

**A review brief has exactly three inputs:** the diff, the requirement it claims
to meet, and the check commands the maker ran with their real output. Never the
maker's conversation, plan or self-assessment, because a reviewer that reads the
maker's reasoning follows it and misses what the maker missed. With no stated
requirement the reviewer stops and reports that, rather than inferring one. Each
finding names the problem, its `path:line`, the reason, and a severity (blocking,
should-fix, nit). Pattern from the MiniMax Code team's `independent-review` skill
(idea only).

## 8. Working memory: fold, don't discard

Long-running commands manage their own context at chosen seams (batch
boundaries, cadence points) instead of drifting into the harness's automatic
compaction — lossy, one-way, and timed by nobody. The fold is always
*recoverable*: offload detail to the run's files (report, journal, plan/),
keep the pointer, re-read on demand — discard from working context only what a
file re-read can recover. Same rule for commands that rewrite their own record
(`/replan-nt`, `/windup-nt`): fold to something searchable (archive, history),
never delete outright. Rewrites of working memory are rare, deliberate, and
reversible — they have outsized impact on everything downstream, so they happen
at seams, on purpose, not continuously by drift.

## 8.5 Write records, declare impact

`plan/` splits in two ([`MEMORY.md`](MEMORY.md)): **records** are append-only, **derived** files (`pending.md`, `workplan.md`, `history.md`'s indexes) are a projection over them. Which one your command writes decides what it may do.

- Writing a **record** (a report, a summary, a journal): append only, never edit a past entry, and end the file with an `## Impact` section saying what should change in the derived files — or `- none — <reason>`.
- Touching a **derived** file: you may flip the status of an item that already exists and append its evidence. You may not add, remove, re-rank, or re-word one. Only `/replan-nt`, `/windup-nt`, and `/scaffold-nt` hold that authority.
- Handed a goal in prose: record it verbatim and queue it **in your own record**. A command that writes its own criteria into the shared plan and then ticks them off has graded its own exam.
- Adding an item during a reconcile pass: tag it `[from: <record-slug>]` so the replay check stays a set comparison instead of a re-read.

State it in `writes:` precisely — "status flips on existing items in `plan/workplan.md`" is a different contract from "`plan/workplan.md`", and the difference is the whole rule.

## 9. Route, don't recite

A body over ~1,000 words is a router: `SKILL.md` carries the contract, the
inputs and their defaults, the guards and stop-lines, and a phase table whose
rows name the *outcome* of each phase and the `references/<phase>.md` file to
read when — and only when — the run reaches it. The detail (procedures,
gotchas, templates) lives in those references. Invoking the skill then loads
the part of the playbook the run is in, not the whole thing; the phases the
run never reaches never enter context. Safety text stays in the root — a
stop-line that lives in an unread reference is not a stop-line. Prefer stating
what a phase must produce over enumerating how; the model reads the reference
for the how when it needs it.

## 10. Keep it lean

The smallest command that fully meets the need, no speculative flags. `/notify-nt`
is the floor — one job, best-effort, never blocks. If a new capability is a
variant of an existing command, **extend it**; a twenty-second command must earn
its slot against the minimal-tooling rule.

**How a rule gets in.** A new default rule either replaces existing text, or ships
with a measured change from `evals/run.sh --without` (§11) named in its CHANGELOG
line. It lives in one file; every other file carries at most one sentence pointing
to it. Sources and credits go in `CREDITS.md`, never in skill text, because an agent
reads skill text on every run and a credit changes nothing it does.
`tests/lean.test.sh` fails on a credit phrase inside `skills/`.

## 11. Test it

A skill that ships a script ships a test for it in `tests/`. A guard that stops a run
(a blocker, a refusal, a stop-line) gets an eval case in `evals/cases/`. Two layers,
two costs:

- **`tests/run.sh`** is free and deterministic. It runs the scripts skills ship, the code
  snippets a skill tells an agent to run, and the eval checks themselves. A test exits 0
  to pass, 1 to fail, 77 to skip when a tool is missing.
- **`evals/run.sh`** makes one model run per case, in a scratch project built from a
  fixture (`evals/fixtures/`) with this checkout's skills installed. It runs under its
  own Claude config dir, because a skill in `~/.claude/skills/` loads in every run and
  beats a project skill of the same name. Log that dir in once:
  `CLAUDE_CONFIG_DIR=~/.ntkit-eval claude auth login`.
- **`evals/run.sh --runs N --without <path>`** asks whether a rule changes behaviour. It
  runs each case N times as checked out and N times with one change: a file or folder
  under `skills/` deleted, or a `.patch` applied, so one paragraph can be switched off.
  The report gives each arm's pass rate, the cases that flipped either way, and mean
  turns, tokens, time and cost. Read the transcript of every flipped case before you
  trust the rates. A rule that leaves the pass rate flat and cuts turns or tokens still
  earns its place; one that raises the rate by breaking a must-not-break check does not.
  `--dry-run` prints the cost ceiling first, and a ceiling over `NT_EVAL_MAX_USD` ($25 by
  default) is refused. Measure a new rule or skill this way before it ships when the
  question is "does it help", not "does it run": in TandemLLM's runs, injected skill text
  doubled one model's run time for no score gain.

A case is `evals/cases/<name>/` holding `prompt`, `setup.sh`, `check.sh`, and optional
`budget` (USD, default 5) and `timeout` (seconds, default 1800). The rules:

- `check.sh` is deterministic: files, git state, the final reply text. No model grades a model.
- It fails on a project the skill never touched. `tests/eval-checks.test.sh` holds every case to this.
- `setup.sh` generates secrets and other scanner bait at run time. A key-shaped string never lands in ntkit's history.

**Anchor every script path.** A skill runs its own scripts by absolute path: `$SKILL/bin/x.py`
where `$SKILL` is the absolute directory containing the loaded `SKILL.md`. Never
`bin/x.py`, `./bin/x.py`, or `$(dirname "$0")/...`. The command runs inside someone else's repo,
so a relative path runs whatever that repo put there; and `$0` in an agent's shell names the shell
(`/bin/zsh`), not the skill. `tests/anchoring.test.sh` holds every skill to this. (Borrowed from
[google/mantis](https://github.com/google/mantis) `check_skill_anchoring.py`, Apache-2.0.)

## Checklist

- [ ] Frontmatter includes the skill name, description, tool list and the workflow contract under `metadata`.
- [ ] Every scope / authority / safety / routing / completion input documented with a default
- [ ] Outward-facing authority defaults to denied; reversible work assumed
- [ ] Anything created outside the repo is torn down at the end, or named in a "what stays" list with its removal command
- [ ] One complete, copyable example with obvious placeholders
- [ ] Required input assembled up front; asks only at the unanswerable or outward-facing
- [ ] Legal states declared; entry-fail refuses; no nested actors
- [ ] Subagent briefs are state-gated and reasoning-free; scaffolding hints stay out of the record
- [ ] Long runs fold at seams to recoverable files; record rewrites archive, never delete
- [ ] `plan/` handled as a folder **or a symlink** ([MEMORY.md §0](MEMORY.md#0-where-plan-lives)): find with `\( -type d -o -type l \)`, ignore-check with `git check-ignore -q plan`, create with the §0 snippet, never replace the link
- [ ] Evidence standards at every length; full ATTEST only for designated formal outputs over approximately 200 unformatted characters; delivers per SUBSTANCE, transitions per STATES
- [ ] Description is 15 words or fewer, trigger first; a body over ~1,000 words is a router over `references/`
- [ ] Earns its place against minimal-tooling — extend before you add
- [ ] A shipped script has a test in `tests/`; a stop-line or refusal has an eval case in `evals/cases/`
- [ ] Every script the skill runs is called by an anchored path under the loaded skill directory (`$SKILL/...`)
