## Continuum as a session host (optional)

[Continuum](https://github.com/NakliTechie/continuum) runs one daemon per machine. The daemon owns terminals and coding agents and keeps their history. [Menagerie](https://github.com/NakliTechie/menagerie) is its browser console. Use this host when a child must run on another machine, for example a GPU batch on a machine tagged `gpu`. Every phase of `/fleet-nt` works without it.

### Setup the owner does once

- Continuum serves on each machine, and this machine reaches it over SSH with a trusted host key and key login.
- Each repo the fleet may place on that machine is cloned there, clean, at the default-branch commit the local triage saw.
- The machine has the agent CLI installed, signed in, and running under the permission mode the owner uses for unattended `/autopilot-nt` runs.
- `machines.md` names the host as `continuum <user@host> <remote state dir>`.

### The four operations

Every call runs `continuum` locally with `--host <user@host> --state <remote state dir> --json`, which runs the request on the owning machine over SSH.

| Operation | Continuum call |
|---|---|
| start | `open --cwd <absolute repo path on that machine> -- <agent-cli> -p "<prompt>"`. Remote `open` requires an absolute `--cwd`. Keep the returned block id as the child id. Pass a fixed `--request-id` (`fleet-<date>-<repo>`) so a retry after a dropped connection does not start a second child. |
| send | Not available for a headless `-p` run, which reads no input. The child gets broadcasts from `brief.md` only after the brief is copied to that machine, and answers through a new run. Copy the brief to the same path on the remote machine at launch and after every amendment. |
| read | `status --block <id>` for running or ended. The record is a file in the remote repo; read it with a short block, `open --cwd <repo> -- cat plan/<record>`, then `events --block <id>` for its output. |
| stop | `acquire --block <id>`, then `stop --block <id>`, then `release --block <id>`. Stop needs the 60-second control lease. |

Register each remote child with `/supervise-nt` as kind `agent`, with a probe that exits 0 while `status --block <id>` reports the block running. Give the probe the 60-second limit in mind, because each call opens an SSH connection.

Continuum structured agent sessions (ACP) end when the daemon restarts, so the fleet uses PTY blocks, which survive a restart. A daemon restart during a run shows as a gap in the block's history; note it in the digest.

### Limits today

- There is no resource report: the machine's `gpu` and `mem` tags come from `machines.md`, written by the owner.
- There is no GPU lease across machines. The fleet's rule of one GPU child per machine is the only guard, and it does not see jobs started outside the fleet.
- A running headless child cannot receive a message.
