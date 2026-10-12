## Terminal and service surfaces

Read this beside each phase's Detail file when the primary surface is a terminal (CLI or TUI) or a service (an HTTP or RPC API with no UI of its own). Each section below replaces the browser-only parts of that phase; everything else in the Detail file still holds (fix rules, finding IDs, the isolation matrix, commits, the report shape).

### Phase 1–2 — Roles and journeys

The two roles the code rarely names still apply. The **anonymous visitor** is the user with no credentials, token or config file: what does the tool do, and does it say how to get set up? The **brand-new zero-data user** is a first run with an empty data directory, no config and no cache. Other roles come from what the code forks on: auth scopes, config profiles, admin subcommands, API keys with different grants.

Journeys come from the surface's own index: `--help` and each subcommand's help for a CLI, the key bindings and screens a TUI shows, the router or OpenAPI document for a service. Entry points first, as in the browser walk.

### Phase 3 — Boot

- **If a harness exists, run its `doctor` first**, as on the browser.
- **CLI or TUI:** there is no server to keep alive. Build the binary or install dependencies once, then start every drive in a fresh, isolated session: its own `tmux` session (`tmux new-session -d -s walk-<role>-<n>`), its own `HOME` or config directory under the run folder, its own data directory. Seed from `demo/seed/` by copying it into that data directory; the first-run journeys start empty. Never point a drive at the user's real config or data.
- **Service:** start a production build on `127.0.0.1` and a known-free port (the browser port rules apply), with its data directory under the run folder. Readiness is a health endpoint or a real request answering, never a fixed sleep. Enter as each role with seeded tokens or the real login endpoint.
- **TUI readiness** is a prompt string or a screen region you can match in `tmux capture-pane -p`, polled with a timeout that fails loudly.
- **Arm the invariant set before the first action.** The terminal and service floor sets replace the browser's seven:

  | ID | Terminal invariant |
  |---|---|
  | `INV-CRASH` | no traceback, panic or uncaught-exception text on stderr |
  | `INV-EXIT` | a valid invocation exits `0`; a failing one exits non-zero *and* says what went wrong and what to do |
  | `INV-HANG` | every invocation finishes, or a TUI repaints, within its timeout |
  | `INV-SILENT` | every action that should change state prints or shows something |
  | `INV-DURABLE` | after anything that should persist, a fresh session reads back the same state |
  | `INV-STRAY` | no file written outside the session's `HOME`, data directory and the paths the command was told to write |

  | ID | Service invariant |
  |---|---|
  | `INV-5XX` | no 5xx response |
  | `INV-CRASH` | no traceback, panic or unhandled error in the server log |
  | `INV-HTTP` | no 4xx except the ones the journey deliberately provokes |
  | `INV-SHAPE` | every response body parses and matches the declared schema when one exists |
  | `INV-HANG` | every request answers within its timeout |
  | `INV-DURABLE` | after a write, a read through a fresh connection returns the same state; after a restart too |

  `INV-SILENT` stays a lead generator, as on the browser. Add repo invariants from the repo's own docs and locked decisions.
- **Record the run** into `plan/walkthrough-<date>-run/`. Terminal: `asciinema rec` when it is installed, else `tmux pipe-pane` to a log, plus stdout, stderr and the exit code per invocation. Service: each request and response (method, path, status, body excerpt) and the server log. The **action log** keeps the same shape as the browser's: index, time from `T0`, role, journey step, the action as prose, the literal command or request, any breach.

### Phase 4 — Walk and fix

Act through the real interface: type the command a user would type, press the keys a TUI shows, send the request a client would send. Calling an internal function or a test-only endpoint proves nothing about the surface. Observe stdout, stderr, exit code and the files or rows the action should have changed. The cross-role probe becomes: as a low-privilege token or profile, call the admin subcommand or route directly.

Stub what cannot run safely the same way: point outbound mail, payments and third-party APIs at a local fake through the config the app already reads. Note what was stubbed. When the safe path is a `--dry-run` flag, check what it skips by watching files, network and git refs; some dry-runs still write.

### Phase 5 — Chaos leg

Enumerate the alphabet from the live surface: subcommands and flags from `--help`, keys from the TUI's on-screen bindings, routes and methods from the router. The yield order holds, with ingest points read as arguments, stdin, input files and request bodies. Timing variations become: interrupt with `Ctrl-C` mid-write, run two invocations against the same data directory at once, send the same request twice.

### Phase 6 — The harness

The three entry points stay. `doctor` checks the binary is the one this checkout built (version or build hash), the data directory is the run's own, and for a service that the port answers and belongs to this checkout. `verify <feature>` starts each drive in its own session and tears that session down after it. Evidence is the transcript and the exit codes, kept in the named evidence directory.
