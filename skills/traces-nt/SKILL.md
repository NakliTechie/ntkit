---
description: "Investigate your agent traces in the tracelens index; ranked findings with fix targets to plan/."
argument-hint: "[since=YYYY-MM-DD] [project=<name>] [signal=<name>] [top=<n>]   e.g. since=2026-09-01 project=quorum"
allowed-tools: ["Bash", "Read", "Write", "Glob"]
entry: "`tracelens` on PATH; a data home ($TRACELENS_HOME, else the cwd) holding archive/; a plan/ folder or link in the cwd"
exit: "`python3 ~/.claude/skills/traces-nt/bin/cite_check.py plan/findings-<date>.md` exits 0"
writes: "plan/findings-<date>.md only"
---

Find what keeps going wrong in your own Claude Code and Codex sessions, and name the change that would stop it. [tracelens](https://github.com/NakliTechie/tracelens) holds the evidence: an archive of every transcript, a DuckDB index, and five rule signals (`repeated_failure`, `approval_stall`, `edit_without_read`, `unverified_claim`, `user_correction`), each row citing `file:line`. This command reads that index with SQL, clusters signal rows into findings, and writes them to `plan/`. It changes nothing else.

## Inputs (defaults announced at the start of the run)

| Input | Default | Effect |
|---|---|---|
| `since=` | 28 days before today | only signal rows with `ts >= since` |
| `project=` | all projects | only rows whose `project` matches |
| `signal=` | all five | only that signal |
| `top=` | 5 | at most this many findings |
| `$TRACELENS_HOME` | the cwd, if it holds `archive/` | where `archive/` and `tracelens.duckdb` live |

## Authority

Read-only outside `plan/findings-<date>.md`. Never edit CLAUDE.md, a playbook, a skill, a settings file, an allow-rule or a scheduled task: propose the text in the finding and stop. Applying a fix is the user's call, and a later session's work.

Transcripts hold pasted tokens and personal data. Quote at most 160 characters of any transcript line. Never copy a credential-shaped string (`sk-`, `ghp_`, `AKIA`, `xox`, a 32+ character hex or base64 run) into a finding; write `[redacted]`. Read raw lines only for the citations you will use, and through `cut -c1-400`.

## Phases

1. **Perceive.** Run `tracelens status --json`.
   - `tracelens` not found → stop: "tracelens is not installed: `uv tool install git+https://github.com/NakliTechie/tracelens.git`". Write nothing.
   - No `archive/` under the data home → stop with the status `next` remedy (`tracelens archive`). Write nothing.
   - No `plan/` in the cwd → stop: "no plan/ here; run from a project with plan/". Write nothing.
   - `next` is `tracelens index` or `tracelens signals` → run it (local, idempotent, atomic), then re-read status.
2. **Measure.** Run `tracelens report --json --top 10`, then the scoped queries in [`references/queries.md`](references/queries.md): weekly rate per signal, top clusters per signal, scheduled-task attribution. Keep the numbers; they go in the findings.
3. **Cluster.** Group rows that share one cause: same tool and error prefix, same command shape, same scheduled task, same reserved word in the same project. A cluster needs at least 3 rows or 2 sessions. Rank by rows × sessions, recent weeks first. For each cluster read at most 3 cited lines (`sed -n '<line>p' archive/<file> | cut -c1-400`) to confirm the cause.
4. **Name the fix.** Each finding gets one target from a closed set: `claude-md` · `playbook` · `skill` · `allow-rule` · `task-prompt` · `tool-bug` · `none`. Write the proposed change as the exact text or rule. Write the measure: the SQL filter whose weekly count should fall, and to what. If an earlier `plan/findings-*.md` proposed the same target and the signal has not fallen, say so and cite it.
5. **Write and check.** Write `plan/findings-<YYYY-MM-DD>.md` in the format below, then run `python3 ~/.claude/skills/traces-nt/bin/cite_check.py plan/findings-<date>.md`. Fix every failure it lists and re-run until it exits 0. A finding whose citations cannot resolve is dropped, not kept.
6. **Report.** Natural prose: scope, how many findings, the top 3 with their fix targets, the file path, and the check result.

## Findings file format

```
# Trace findings — <YYYY-MM-DD>
Scope: since <date> · project <name|all> · signal <name|all> · index built <built_at>

## F1 — <one-line cause>
- Signal: <name> · rows: <n> · sessions: <n> · weeks: <first>..<last>
- Evidence: `<agent>/<archive-relative path>.jsonl:<line>`, `<…>:<line>`
- Cause (<observed|inferred>): <one or two sentences>
- Fix target: <type> — <file, rule or task name>
- Proposed change: <exact text, rule or step>
- Measure: <SQL filter on signals> — expect <n>/week → <n>/week
- Status: proposed
```

`cite_check.py` holds each `## F<n>` section to: at least one evidence pointer that exists in the archive at that line, a `Fix target:` from the closed set, and a `Measure:` line.

## Example

```
cd ~/Code/tracelens
/traces-nt since=2026-09-01 signal=approval_stall top=3
```
