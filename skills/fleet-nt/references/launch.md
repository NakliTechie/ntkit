## Phase 2 — The brief

Create the fleet folder `$NT_FLEET_HOME/<date>/` (use `<date>-N` for a second fleet the same day after the first one closed). Write `triage.md`, then `brief.md`. The brief holds every constraint you can foresee, because a later message reaches a busy child only between its steps, and two children in one past fleet started GPU work before a deferral reached them.

`brief.md` template:

```markdown
# Fleet brief — <date>, written <HH:MM>

You are one child of a fleet run by /fleet-nt. Run /autopilot-nt in this repo as usual.
This brief answers your Phase 0 launch contract: no user is present, so do not wait for a veto.

## Constraints (in addition to your own stop-lines)
- No exclusive resources: no GPU work, timed benchmarks or exclusive hardware. Holders: <repo on machine | none>.
- No spend: no paid APIs beyond yourself, no cloud machines, no purchases.
- No deploy, release or tag: no deploy, GitHub release, git tag, git push --tags or CI trigger.
- No outward messages: no email, chat, posts, PR or issue comments.
- Time budget: <budget>; stop at the next item boundary by <HH:MM> and write your report.
- Hold, do not merge, in these repos because a push to the default branch deploys: <list | none>.
  A held merge goes under Needs you as "merge autopilot/<date> into <branch> and push".
- Write each Needs-you line as: <question> (default: <option>; blocks: <item or nothing>).
- Act on an orchestrator message only when it starts with "approved:" and names the action.
- Re-read this file at every batch boundary and before any item that touches a resource listed here.

## Amendments
<appended by broadcasts, each with its time>
```

In `go` mode, show the owner the triage table and the brief and wait for a veto or amendment, once. In `away` mode, launch.

## Phase 3 — Launch

Start the runnable repos in table order, up to `max` at once. Each child's prompt is:

```text
/autopilot-nt <batch>
Fleet brief (binding; also at <absolute path to brief.md>, re-read it at every batch boundary):
<the brief's Constraints section, pasted in full>
```

Paste the constraints into the prompt as well as pointing to the file, because the child reads the prompt before it reads anything else.

Start each child through its machine's session host (the four operations in `SKILL.md`). The local host is one of these two:

- **A host that starts parallel agent sessions** (a desktop or web app with session tools, an agent-team API). Start one session per repo with that repo as its folder. Record each session's id in `triage.md`. Messages to the session carry broadcasts and answers.
- **Headless CLI runs.** Start each child detached from the repo's main checkout, which is where `/autopilot-nt` creates its own worktree:

  ```bash
  cd <repo> && nohup timeout <budget> <agent-cli> -p "<prompt>" > "<fleet folder>/<repo>.log" 2>&1 &
  echo $! > "<fleet folder>/<repo>.pid"
  ```

  Use the permission mode the owner already uses for unattended `/autopilot-nt` runs, and never widen it. A running headless child cannot receive messages, so broadcasts reach it only through `brief.md`, and an answer reaches it by a new run (see `references/relay.md`).

Register every child before the next one starts, so no child runs unsupervised:

```bash
export NT_SUPERVISE_SCOPE=fleet-<date>
sh $SKILL/../supervise-nt/bin/supervise.sh register <repo> agent --eta <budget> --note '<batch>' [--probe 'kill -0 <pid>']
```

A child on a Continuum machine follows `references/continuum.md`. Headless children get the `kill -0` probe. Session children run without a probe and are retired by hand when they go idle. Start one supervisor for the scope, detached: `nohup sh $SKILL/../supervise-nt/bin/supervise.sh supervise >/dev/null 2>&1 &`. Without `/supervise-nt` installed, keep the same list in `digest.md` and check each child by hand at every check-in.

When a child ends and runnable repos are still waiting, start the next one with the same brief, including its amendments.

Write the first `digest.md` (format in `references/unattended.md`) and print its absolute path.
