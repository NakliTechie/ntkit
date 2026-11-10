---
name: supervise-nt
description: "Register delegated work that outlives the session; check in, alert when it stalls."
allowed-tools: Bash
metadata:
  argument-hint: "[register NAME KIND --probe CMD --eta MIN | checkin | status | done NAME]"
  entry: "any state; before launching work the harness cannot see"
  exit: "the delegation is registered, checked or retired, and a detached supervisor runs while work is active"
  writes: "state outside the repo: $NT_SUPERVISE_HOME/<scope>/ (default ~/.local/state/ntkit/supervise)"
---

Watch work that runs outside this session: a cloud job, a long script, another agent's CLI, a background job that must survive the session. In-session subagents and background shells are already tracked by the harness; register those only when they must outlive the session. The tool is `$SKILL/bin/supervise.sh`, a dependency-free shell script.

## The contract

1. **Register before launch.** `register NAME KIND --probe CMD --eta MIN`. Work that is not registered is not supervised.
2. **Every delegation has a probe and an ETA.** The probe exits 0 while the work runs (`kill -0 <pid>`, `test ! -f <done marker>`, a cloud CLI's describe call). No probe is possible for a subagent: say so, and retire it by hand.
3. **Waiting is not watching.** A loop that waits for the work to end never replaces a check-in, because it cannot tell a stalled job from a slow one.
4. **What must outlive the session runs detached** (`nohup … &`), never as a child of the session.
5. **The remote side carries its own last line of defence:** a spend cap, a time limit, or a machine that deletes itself. The supervisor alerts; it does not stop anything.

## The run

- **Register.** `sh $SKILL/bin/supervise.sh register <name> <cloud|agent|cli|job> --probe '<cmd>' --eta <45 | 45m | 2h> --note '<what it is>'`. A review run through another model's CLI is `cli`.
- **Start the supervisor once per project, detached:** `nohup sh $SKILL/bin/supervise.sh supervise >/dev/null 2>&1 &`. It wakes every 30 minutes. It alerts on the desktop (and to `NTFY_TOPIC` when set) and exits when nobody has checked in for 20 minutes while work runs, or when a delegation passes its ETA × 1.5 + 15 minutes. It exits on its own after two idle cycles. Register prints a note when no supervisor runs.
- **Check in every 15 minutes:** `sh $SKILL/bin/supervise.sh checkin '<what you saw>'`. Then look at real evidence: is it alive, is its output growing, is it on task, what has it spent. Healthy → let it run. Stalled, looping or off task → intervene. A check-in is a look, not a kill.
- **Retire it when it ends:** `sh $SKILL/bin/supervise.sh done <name> '<outcome>'`. `checkin` lists a delegation whose probe now fails as `ENDED per probe`: read its result, then retire it.
- **Stop a supervisor by its own pidfile,** `kill "$(cat <state dir>/supervisor.pid)"`, never by a process-name pattern, because that would stop every project's supervisor.

Report in one line per delegation: name, kind, minutes running, state, and what you did about it.
