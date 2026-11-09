# Calling another model family

Read this when a skill says to prefer another family's agent CLI: the rotate-the-eyes step of `/forward-pass-nt`, `/ux-review-nt` and `/walkthrough-nt`, the `/harden-nt` roster, and the `/autopilot-nt` checker.

## Rotation

1. Read only the `Reviewer:` line of the calling command's latest report in the main checkout's `plan/`, never its findings.
2. If that run used your model family, prefer another family's agent CLI on PATH (`codex`, `gemini`, checked with `which`, then one probe call), else another model of your family; never materially weaker eyes.
3. Call it by the rules below.
4. Neither reachable → run as-is and write `rotation: unavailable` in the `Reviewer:` line.
5. The report header says `Reviewer: <model> · prior: <model> (<date>)` or `prior: none`, and notes when you are the family that built most of the code.

## Rules for a call

1. **Probe before you rely on it.** `which` shows a CLI is installed, not that it answers. Send one trivial call with a known answer ("Reply with exactly: PONG") and a short timeout first. A failed probe drops that agent and is recorded.
2. **Name the model from the user's config.** Pass the model explicitly in the call. Never copy a model id from this kit; it names none.
3. **No stdin, a hard timeout, its own process group.** Run each call with `< /dev/null` so it cannot wait for input. Give a coding-agent CLI reading a whole repository at least 300 s and other calls at least 150 s. Kill the process group, not only the child, so a stalled grandchild does not outlive the run.
4. **Serialise what shares state.** CLIs that keep one local database or session store fail with lock errors when run side by side: run those one at a time, and run independent ones in parallel. Retry an error once, serially, after the others finish. Do not retry a timeout or an empty answer.
5. **Record the outcome per agent:** `ok`, `empty`, `error`, `timeout` or `probe-failed`. A failure is data about the setup, not about the code under review. `rotation: unavailable` is for the case where no other family answered.
6. **Privacy.** Every prompt, and every file the CLI reads, goes to that provider. Send a private repository only to a provider the user has cleared. Hosted free-tier models may keep or train on what they receive, so never send private code to one. A black-box round sends the surface contract and public behaviour, not the source.
7. **An answer is a claim.** Check each finding yourself before it enters the report: other families often cite the wrong file, line or version. Cluster findings that say the same thing, and count how many agents found each one independently.

If scholia's `/panel-nt` skill is installed, its runner implements 1 to 5: `python3 <panel-nt>/scripts/panel.py run --prompt <file> --out <dir> --config <providers.toml> --probe`. Its providers live in the user's own TOML file, outside this kit. Without it, apply the same rules by hand.
