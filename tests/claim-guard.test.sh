#!/bin/sh
# claim-guard: blocks a "done" reply with no check after the last edit; passes in the other cases.
set -u
here=$(cd "$(dirname "$0")" && pwd)
hook="$here/../hooks/claim-guard.py"
command -v python3 >/dev/null 2>&1 || { echo "python3 missing"; exit 77; }
tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT INT TERM

user='{"type":"user","message":{"content":[{"type":"text","text":"fix it"}]}}'
edit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"a.py"}}]}}'
check='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pytest -q"}}]}}'
list='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls"}}]}}'
done_='{"type":"assistant","message":{"content":[{"type":"text","text":"Fixed. All tests pass."}]}}'
failed='{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"c1","is_error":true,"content":"Exit code 1"}]}}'
okres='{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"c1","content":"3 passed"}]}}'
check1='{"type":"assistant","message":{"content":[{"type":"tool_use","id":"c1","name":"Bash","input":{"command":"pytest -q"}}]}}'
docedit='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Edit","input":{"file_path":"README.md"}}]}}'
plain='{"type":"assistant","message":{"content":[{"type":"text","text":"I changed a.py; not yet verified."}]}}'

run() { # name expected-exit active transcript-lines...
  name=$1; want=$2; active=$3; shift 3
  printf '%s\n' "$@" > "$tmp/t.jsonl"
  printf '{"transcript_path":"%s","stop_hook_active":%s}' "$tmp/t.jsonl" "$active" \
    | python3 -I "$hook" >/dev/null 2>"$tmp/err"; rc=$?
  [ "$rc" -eq "$want" ] || { echo "FAIL $name: exit $rc, wanted $want"; cat "$tmp/err"; exit 1; }
}

run "claim after edit, no check"        2 false "$user" "$edit" "$done_"
run "claim after edit, only ls"         2 false "$user" "$edit" "$list" "$done_"
run "claim after edit and a check"      0 false "$user" "$edit" "$check" "$done_"
run "check before the last edit"        2 false "$user" "$check" "$edit" "$done_"
run "no claim in the reply"             0 false "$user" "$edit" "$plain"
run "no edit in the turn"               0 false "$user" "$done_"
run "earlier turn's edit is ignored"    0 false "$user" "$edit" "$done_" "$user" "$done_"
run "check ran but errored"            2 false "$user" "$edit" "$check1" "$failed" "$done_"
run "check ran and succeeded"          0 false "$user" "$edit" "$check1" "$okres" "$done_"
run "only a README was edited"         0 false "$user" "$docedit" "$done_"
run "hook already fired"                0 true  "$user" "$edit" "$done_"
echo "ok"
