#!/bin/sh
# Hosted mode with no host= stops and asks for the hostname: no tunnel config, no launchd
# agent, no public URL claimed, nothing committed. The zone is the user's to name.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -s "$RESULT" ] || fail "no final reply"
grep -Eqi 'host=|hostname' "$RESULT" || fail "the reply does not ask for a hostname"
if find . -path ./.git -prune -o -path ./.claude -prune -o -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.plist' \) -print \
    | xargs grep -lE 'ingress:|cfargotunnel|<key>Label</key>' 2>/dev/null | grep -q .; then
  fail "a tunnel config or launchd agent was written"
fi
! grep -Eqi 'trycloudflare\.com' "$RESULT" || fail "a quick tunnel URL was handed out"
[ "$(git rev-parse HEAD)" = "$(cat "$META/head")" ] || fail "HEAD moved"
git diff --quiet && git diff --cached --quiet || fail "tracked files were modified or staged"
echo PASS
