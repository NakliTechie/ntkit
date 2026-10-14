# dibs — a shared claim ledger for scarce resources

Status: proposal, 2026-10-14. Tier: Tool (one file of code, no server). Nothing here is built yet.

## 1. The problem

Several agents run on one machine at once: Claude sessions, Codex, opencode, background jobs. They compete for things that do not share well: the GPU, download bandwidth, the one allowed Chrome debugging connection, the Mac Studio. Today each agent finds out it collided when a job runs out of memory or a download stalls.

Agents cannot message each other across vendors. Claude agents can talk to Claude agents. Codex cannot talk to either. So coordination cannot depend on messages. It must depend on something every agent can already do: run a shell command and read a file.

## 2. What already exists, and why it is not enough

| Existing piece | What it does | Why it does not cover this |
|---|---|---|
| `~/Code/infra/remote-studio/studio-lock.sh` | One lock on the Mac Studio. `mkdir` is the atomic gate. Fails fast, expires by process id or time limit, keeps a job log. | One resource, exclusive only, tied to SSH. No counted resources such as 4 of 8 download streams. |
| `mcp-agent-mail` (`acquire_build_slot`, file reservations) | Advisory slots with a time limit and an exclusive flag. | It needs an MCP client. Codex and background scripts can reach it, but only with extra setup, and a stopped server means no claims. The slot has no amount, no process id, no queue. |
| `~/Code/infra/bin/delegate` | Records what each agent or job is doing and alerts when a check-in lapses. | It supervises work. It does not decide who may use a resource. |
| `~/Code/infra/gcp/gpu-usage.csv` | Hand-kept log of cloud GPU lives and their cost. | A report, written after the fact. |

The design below keeps the good parts of `studio-lock.sh` (atomic gate, fail fast, self-healing, append-only log) and generalises them. `studio-lock.sh` becomes one adapter, not a rewrite.

## 3. The design in one paragraph

A single Python file, `dibs`, with no dependencies beyond the standard library. State lives in plain files under `~/.ntkit/dibs/`. A resource is declared once in a small config file with a kind and a capacity. An agent asks for a claim by running `dibs run <resource> -- <command>`. The tool checks capacity, starts the command if there is room, records a claim file that names the command's process, and removes it when the process ends, even if the process crashes. Every event is appended to a log. Because the claim belongs to the real process, not to the agent that started it, a crashed agent cannot leave a stuck claim.

## 4. Model

**Resource.** A name, a kind, a capacity, and an optional live probe. Three kinds:

- `exclusive`: one holder at a time (the Studio, the Chrome debugging connection, one GPU).
- `counted`: a pool with an integer capacity (8 download streams, 24 GB of VRAM). Holders ask for an amount.
- `rate`: a token bucket (API calls per minute). Later; see section 13.

**Claim.** One JSON file per holder. Fields: resource, amount, label, holder (agent program, session id, project, working directory), process id and its start time, claim time, last heartbeat, time limit, queue ticket if it waited.

**Grant.** For counted resources an agent can say `--want 8 --min 2`. The tool grants between 2 and 8 depending on what is free, and passes the result to the command as the environment variable `DIBS_GRANT`. The download script then sizes itself (`--parallel $DIBS_GRANT`). This gives fair sharing of bandwidth without any agent knowing about the others.

## 5. Storage and atomicity

```
~/.ntkit/dibs/
  resources.toml            declared resources (edited by hand)
  claims/<resource>/<id>.json
  queue/<resource>/<ticket>.json
  events.jsonl              append-only ledger
  .gate                     short-lived directory lock
```

Every change takes the gate: `mkdir .gate` is atomic on macOS and Linux, the same trick `studio-lock.sh` uses. Inside the gate the tool reads claims, applies the stale rules, decides, writes, and leaves. The gate is held for milliseconds. A gate older than 10 seconds is treated as abandoned and removed. Local disk only; network filesystems are out of scope.

## 6. The command line

```
dibs run <resource>[:<amount>] [--want N --min M] [--ttl 90m] [--wait 10m] [--label TEXT] -- <command...>
dibs status [resource]          who holds what, who waits, live probe readings, stale marks
dibs claim <resource> ...       manual claim, for work that is not one command; prints a claim id
dibs renew <id>                 extend the time limit
dibs release <id>               give it back
dibs log [n]                    tail the ledger
dibs steal <id> --force         human only; refused for a live process unless --force
```

Exit codes are fixed so any agent can branch on them: 0 ran, 10 busy (not granted, nothing started), 11 waited too long, 64 usage error. `dibs run` returns the command's own exit code once it has started.

Default is fail fast, as in `studio-lock.sh`: if the resource is busy, print the holder and the estimated time left, and exit 10. The agent then does other work. `--wait` joins a first-in first-out queue instead.

## 7. Liveness: when a claim counts as stale

The rule is chosen so that a healthy job is never evicted.

1. A claim with a process id is live while that process exists and has the recorded start time. The start time guards against a reused process id.
2. A live process is never stolen from, whatever the time limit says. When the time limit passes, the claim is marked OVERDUE. `dibs status` shows it and the supervisor in `delegate` alerts you. A person decides.
3. A claim whose process is gone is released at the next gate entry and logged as `expire`.
4. A claim with no process id (manual claims, remote resources) expires when its time limit passes without a `renew`.

Why the asymmetry: a laptop that sleeps pauses the job and the clock together. On wake, a time-based rule would evict a job that is still running. Process existence has no such flaw.

## 8. Fairness

Waiters take a numbered ticket. When capacity frees up, the lowest ticket that fits is served first. A waiter's ticket expires if its process disappears, so the queue cannot jam. There is no preemption in version 1: a running job is never interrupted. Priorities are left out until a real case needs them.

## 9. Remote resources

The machine that owns a resource owns its state, as `studio-lock.sh` does today. In version 1, `resources.toml` can point a resource at an adapter command instead of local files:

```toml
[studio]
kind = "exclusive"
adapter = "~/Code/infra/remote-studio/studio-lock.sh"
```

The adapter must answer `acquire`, `release`, `status` with the same exit codes. Cloud GPUs launched through SkyPilot are not claimed by `dibs`; they are paid for by the hour and already have a spend cap. What `dibs` records for them is the decision to launch one, so two agents do not start the same spot GPU.

## 10. Load that nobody claimed

A claim system is advisory. Om, a browser tab, or an agent that never heard of `dibs` can use the GPU without a claim. Each resource can carry a probe, a shell command that prints a number (free VRAM from `nvidia-smi`, free memory from `vm_stat`, current download rate from `netstat`). `dibs status` prints the probe next to the claims, and a mismatch is flagged: "claims total 8 GB, probe shows 21 GB in use". This is the same idea as the memory line `studio-lock.sh` prints.

## 11. Getting agents to use it

Advisory systems work only if every agent knows to ask. Three layers, cheapest first:

1. **A shared instruction block** for `CLAUDE.md`, `AGENTS.md` and any Codex or opencode prompt: "before a GPU job, a bulk download or the Studio, run it as `dibs run ...`; on exit code 10, do other work and check `dibs status`." One short text, installed by `ntkit`.
2. **ntkit skills that call it** (section 12). Skills are the agents' own entry points, so they follow the rule without being told.
3. **A hook for Claude Code** that blocks known heavy commands (`hf download`, `sky launch`, `python train*.py`) unless wrapped in `dibs run`. Claude only. Codex has no equivalent, so layers 1 and 2 must carry it.

## 12. Where ntkit uses it

| Skill | Resource | How |
|---|---|---|
| `/lab-nt` | `gpu`, `studio` | The per-experiment cap becomes the time limit of the claim. |
| `/autopilot-nt` | `gpu`, `net` | Items that train or download run through `dibs run`. |
| `/live-check-nt` | `chrome-foreground` | Only one WebGPU replay can own the foreground tab. |
| `/research-nt` (`fetch.py`) | `net` | Parallel fetch takes `DIBS_GRANT` as its worker count. |
| `/walkthrough-nt` | `port:<n>` | Replaces "pick a known-free port" with a claim. |
| `delegate register` | any | A new `--holds` flag links a delegation to its claims, so `delegate checkin` lists them. |
| Chrome playbook | `chrome-cdp` | Enforces the existing rule: one remote-debugging connection per task. |

## 13. The ledger

`events.jsonl` has one line per event: `acquire`, `deny`, `queue`, `release`, `expire`, `overdue`, `steal`. Each carries time (with IST rendering in `dibs log`), resource, amount, holder, label and duration. This is the accounting record: GPU hours by project and agent, bytes-time of bandwidth, how long agents waited. A small `dibs report` can later feed `gpu-usage.csv`. The `rate` kind and the report are version 2.

## 14. Failure cases

| Case | What happens |
|---|---|
| Agent crashes while the job runs | The claim belongs to the job, so it stays correct. |
| Job crashes | Process gone, claim removed at the next gate entry. |
| Job hangs | OVERDUE flag and an alert. No automatic kill. |
| Laptop sleeps | Process id rule keeps the claim. |
| `dibs` itself killed mid-write | Writes use a temp file and rename; a stale gate is removed after 10 seconds. |
| Agent ignores `dibs` | Probe mismatch shows in `status`. Nothing blocks it. Stated limit. |
| Two machines | Not supported locally; use an adapter on the owning machine. |

## 15. Build order

Following the layer rule, each step ships and works before the next starts:

1. `exclusive` kind, local, `run`, `status`, `log`, process-id liveness. Tests: two concurrent `run` calls, a killed holder, a reused process id.
2. `counted` kind with `--want/--min` and `DIBS_GRANT`.
3. Queue with `--wait`.
4. Adapter for `studio-lock.sh`; probes in `status`.
5. Instruction block, then skill integrations, then the Claude hook.
6. `rate` kind, `report`, `delegate --holds`.

Non-goals: a server or daemon, a network protocol, preemption, priorities, enforcement against agents that opt out, and any cross-machine consensus.

## 16. Decisions needed

1. **Name.** `dibs` (your word) or `claim`. Recommended: `dibs`.
2. **Place in ntkit.** A skill directory `skills/dibs-nt/` with `bin/dibs` and a `SKILL.md` that agents read. Recommended, because skills are how ntkit already ships tools with an agent-facing description.
3. **Location of state.** `~/.ntkit/dibs/` (one per machine). Recommended over a per-repo directory, because the resources are per machine.
4. **First resources to declare:** `gpu` (exclusive), `net` (counted, 8 streams), `chrome-cdp` (exclusive), `studio` (exclusive, adapter). Recommended starting set.
5. **Whether `studio-lock.sh` is replaced or wrapped.** Recommended: wrapped, since it holds the real lock on the Studio and Om's side may use it.
