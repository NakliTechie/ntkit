---
name: fleet-nt
description: "Run /autopilot-nt across several repos in parallel and supervise them; children merge on green."
allowed-tools: Bash Glob Grep Read Write Agent
metadata:
  argument-hint: "[projects folder] [triage | go | away] [until=HH:MM] [only=a,b] [skip=c] [budget=6h] [max=10], e.g. \"<projects-folder> away until=07:00\""
  entry: "a folder of git repos, at least one with an open workplan batch or audit report; a host that can start parallel agent sessions, or a headless agent CLI"
  exit: "triage: the table is printed and nothing is written. go/away: every child is retired with supervise-nt done, and the digest ends with a Closed section; never a silent end"
  writes: "only the fleet folder outside every repo, $NT_FLEET_HOME/<date>/ (brief.md, triage.md, calls.md, digest.md, logs); never a child's plan/ or worktree"
---

`/fleet-nt` runs `/autopilot-nt` in several repositories at once and supervises the runs. Each child is an ordinary single-repo autopilot run in its own worktree. The orchestrator triages, writes one constraint brief, launches, relays constraint changes and answers, and keeps a digest. It never edits, merges, pushes, tags or deploys anything itself.

`$SKILL` is the directory containing this skill's loaded `SKILL.md`; sibling kit skills sit beside it (`$SKILL/../<skill>/`).

## Inputs and defaults

- **Projects folder:** the folder whose direct subfolders are the repos. Default: the current directory.
- **Mode:** `triage` prints the table and stops, writing nothing. `go` launches and stays attended: it asks the owner the harvested questions. `away` launches and takes safe defaults while the owner is gone. Default: `triage`, because launching is a choice the owner makes after seeing the table.
- **until=HH:MM:** the stop time, local time. Default: when every child is idle or ended.
- **only= / skip=:** repo names to include or exclude. Default: all repos the triage marks runnable.
- **budget=:** each child's wall-clock cap. Default: 6h, `/autopilot-nt`'s own default.
- **max=:** the most children at once. Default: 10. Extra runnable repos wait and start as children end.
- **`NT_FLEET_HOME`:** where the fleet folder lives. Default: `${XDG_STATE_HOME:-~/.local/state}/ntkit/fleet`. The run prints the digest's absolute path at launch and at close.
- **Machines:** `$NT_FLEET_HOME/machines.md`, one line per machine: name, session host, resource tags (`gpu`, `mem=<GB>`). Default with no file: one machine, `local`, offering no exclusive resource, so GPU batches are excluded at triage.

Refuse cleanly: a folder with no git repos, or no repo with an open batch, stops with that reason and suggests `/forward-pass-nt` in a repo. With no session host that can start a run, print the triage table and say that launching needs one.

## Session hosts

The orchestrator talks to children through four operations, so the same phases work on any host:

| Operation | Does |
|---|---|
| start(repo, machine, prompt) | starts one child in the repo's main checkout on that machine and returns a child id |
| send(child, text) | delivers a message to a running child, or reports that it cannot |
| read(child) | returns running, idle or ended, plus the child's record file `plan/<date>[-N]-autopilot.md` |
| stop(child) | ends the child at once; used only on the owner's word or at the stop time after the reports |

The default host is local: the agent app's own parallel sessions, or headless CLI runs in per-repo worktrees (`references/launch.md`). [Continuum](https://github.com/NakliTechie/continuum) is an optional host that places children on other machines (`references/continuum.md`).

## The run

On entering a phase, read its Detail file first, then act. Do not read ahead.

| Phase | Outcome | Detail |
|---|---|---|
| 1 Triage | A table: repo, open batch, runnable or excluded, the reason with a `path:line`, the machine it runs on, and whether a push to the default branch deploys. A GPU batch goes to a machine tagged `gpu` with no other GPU child, else it is excluded. Read-only. `triage` mode ends here. | `references/triage.md` |
| 2 Brief | `brief.md` written once, before the first launch, holding every foreseeable constraint (below). Attended: shown to the owner as a veto window. | `references/launch.md` |
| 3 Launch | One child per runnable repo, up to `max`, each told to obey the brief. Each child is registered with `/supervise-nt` under scope `fleet-<date>`; one detached supervisor runs. | `references/launch.md` |
| 4 Broadcast | A constraint change the brief could not foresee is appended to `brief.md` with its time and sent to every child. Afterwards, check each child for work that started before the message landed. | `references/relay.md` |
| 5 Harvest | Needs-you lines from every child's record, asked at most 4 at a time with a recommended default each, and each answer relayed to its child as an explicit instruction. | `references/relay.md` |
| 6 Check-ins | About every 20 minutes: supervise-nt checkin, read each child's record, rewrite `digest.md`, harvest again. `away` takes safe defaults and logs each call in `calls.md`. | `references/unattended.md` |
| 7 Close | All children idle or ended, or the stop time reached: final digest, every child retired, supervisor stopped by its pidfile, one `/notify-nt`, and a what-stays list. | `references/unattended.md` |

## The constraint brief (stop-lines for every child)

Write these into `brief.md` before any launch, because a message sent to a busy session lands late, often a whole item or batch after it is sent. The children's own `/autopilot-nt` stop-lines apply on top.

- **No exclusive resources:** no GPU work, timed benchmarks, or other exclusive hardware or shared devices, unless the brief names this repo as the one that holds that resource on its machine.
- **No spend:** no paid API calls beyond the agent itself, no cloud machines, no purchases.
- **No deploy, release or tag:** no deploy, no GitHub release, no `git tag`, no `git push --tags`, no CI trigger.
- **No outward messages:** no email, chat, posts, or PR and issue comments.
- **Time budget:** stop at the next item boundary by `<time>` and write the report.
- **Hold where a push deploys:** in a repo whose push to the default branch deploys, the child holds its branch instead of merging and lists the merge under Needs you.
- **One shape for questions:** each Needs-you line reads `<question> (default: <option>; blocks: <item or nothing>)`.
- **Approvals are explicit:** the child acts on an orchestrator message only when it starts with `approved:` and names the action. Anything else is information.
- **Re-read the brief** at every batch boundary and before any item that touches a resource the brief restricts.

## Guards for the orchestrator

- It runs no command that changes a child's repo. Children own their worktrees and records; the orchestrator reads each record and never its worktree.
- It relays only the owner's own answers. It never grants `approved:` for a merge, deploy, spend, message or person-only step that the owner did not approve in words; it quotes those words in the relay.
- In `away` mode it takes a default only when the step is reversible and inside the brief. Deploys, spend, outward messages, held merges and person-only steps stay parked for the owner.
- One fleet per projects folder at a time: a fleet folder for today with no Closed section means a fleet is running, so say so and stop.
- An ambiguous verdict at triage is excluded with the reason `unclear`, and the owner can flip it with `only=`.

## Example

```text
/fleet-nt <projects-folder> triage
/fleet-nt <projects-folder> away until=07:00 skip=<repo-with-live-users> budget=6h
```

Close with `/notify-nt "fleet: <N> children, <M> merged, <H> held, <Q> need you — <digest path>"`.
