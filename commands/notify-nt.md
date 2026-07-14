---
description: Completion ping — send yourself a desktop notification and (optionally) a phone push via an ntfy.sh topic. The finish-line half of unattended runs — /autopilot-nt fires it; long /execute-nt batches can too. Degrades silently; a failed ping never fails the run that sent it.
argument-hint: "<message, e.g. \"myapp: autopilot done — gate GREEN, 7 landed\">"
allowed-tools: ["Bash"]
---

Send a short completion ping to the user. This is the smallest command in the kit and it must stay that way: compose one line, deliver it on every channel that's configured, never block, never fail loudly.

**Phone topic:** set the environment variable `NTFY_TOPIC` to an [ntfy.sh](https://ntfy.sh) topic name (pick something unguessable — the topic *is* the auth) and subscribe to it in the ntfy app. Leave it unset to skip the phone push. Edit this paragraph if you use a different push service.

## Step 1 — Compose the message

If `$ARGUMENTS` is non-empty, that's the message — use it verbatim. If empty, write one line summarizing what just finished in this session (command · project · outcome), e.g. `myapp: execute-nt Batch A done — 5 fixed, 1 deferred`. One line, plain text, no markdown.

## Step 2 — Deliver, best-effort, every configured channel

- **Desktop** — macOS: `osascript -e 'display notification "<msg>" with title "ntkit"'` (or `terminal-notifier` if installed). Linux: `notify-send "ntkit" "<msg>"`. Skip silently if neither exists (a headless CI box, a container).
- **Phone** — if `$NTFY_TOPIC` is set: `curl -fsS -m 10 -d "<msg>" "ntfy.sh/$NTFY_TOPIC"`.

Wrap every delivery so a failure is swallowed (`|| true`) — a notification is a courtesy, and the run that called it has already done the real work.

## Step 3 — Confirm

One line, listing where the ping went: `Pinged: desktop · ntfy (<topic>)` — or `Pinged: nowhere (no channel configured — set NTFY_TOPIC or run on a machine with a desktop)`. Nothing else. Don't write to plan/, don't commit, don't push.
