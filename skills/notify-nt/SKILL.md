---
name: notify-nt
description: "Desktop plus optional ntfy phone ping; best-effort, never fails the caller."
allowed-tools: Bash
metadata:
  argument-hint: "<message, e.g. \"myapp: autopilot done — gate GREEN, 7 landed\">"
  entry: "any state"
  exit: "ping attempted on every configured channel; never fails the caller"
  writes: "nothing"
---

Send a short completion ping to the user: one line, every configured channel, never block, never fail loudly.

**Phone topic:** `NTFY_TOPIC` names an [ntfy.sh](https://ntfy.sh) topic (unguessable; the topic *is* the auth). Unset → skip the phone push.

## Step 1 — Compose the message

If the input is non-empty, that's the message — use it verbatim. If empty, write one line summarizing what just finished in this session (command · project · outcome), e.g. `myapp: autopilot-nt Batch A done — 5 fixed, 1 deferred`. One line, plain text, no markdown.

## Step 2 — Deliver, best-effort, every configured channel

The message is untrusted text: never paste it inside a command's quotes. Read it once into a variable through a quoted heredoc, then pass only `"$msg"`:

```sh
IFS= read -r msg <<'EOF'
<msg>
EOF
```

- **Desktop** — macOS: `osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "ntkit"' -e 'end run' "$msg"`. Linux: `notify-send -- "ntkit" "$msg"`. Skip silently if neither exists.
- **Phone** — if `$NTFY_TOPIC` is set: `printf '%s' "$msg" | curl -fsS -m 10 --data-binary @- "https://ntfy.sh/$NTFY_TOPIC"`.

Wrap every delivery so a failure is swallowed (`|| true`).

## Step 3 — Confirm

One line, listing where the ping went: `Pinged: desktop · ntfy (<topic>)` — or `Pinged: nowhere (no channel configured — set NTFY_TOPIC or run on a machine with a desktop)`. Don't write to plan/, commit or push.
