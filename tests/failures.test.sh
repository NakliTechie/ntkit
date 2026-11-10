#!/bin/sh
# windup-nt/bin/failures.py: failed tool calls grouped by shape, rejections and bare exits left out,
# merged into plan/failures.md without double counting a session, an existing fix kept.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
F=$(cd "$(dirname "$0")/.." && pwd)/skills/windup-nt/bin/failures.py
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
bad=0
mk() { # mk <file> <session>: a transcript with 2 identical push failures, 1 rejection, 1 bare exit, 1 Read error
  python3 - "$1" "$2" <<'PY'
import json, sys
path, sid = sys.argv[1], sys.argv[2]
rows = []
def use(i, name, inp): rows.append({"sessionId": sid, "timestamp": "2026-11-10T10:00:00Z", "message": {"content": [{"type": "tool_use", "id": i, "name": name, "input": inp}]}})
def res(i, text): rows.append({"sessionId": sid, "timestamp": "2026-11-10T10:00:01Z", "message": {"content": [{"type": "tool_result", "tool_use_id": i, "is_error": True, "content": text}]}})
use("a", "Bash", {"command": "cd /repo && GIT_X=1 git push origin main"}); res("a", "Exit code 1\nTo https://github.com/x/y\n error: failed to push some refs to 'https://github.com/x/y'")
use("b", "Bash", {"command": "git push"}); res("b", "Exit code 1\n error: failed to push some refs to 'https://github.com/a/b'")
use("c", "Bash", {"command": "rm -rf build"}); res("c", "Permission to use Bash with command rm -rf build has been denied.")
use("d", "Bash", {"command": "grep -n foo bar.txt"}); res("d", "Exit code 1")
use("e", "Read", {"file_path": "/x/y.md"}); res("e", [{"type": "text", "text": "File does not exist: /x/y.md"}])
with open(path, "w") as f:
    f.write("not json\n")
    for r in rows: f.write(json.dumps(r) + "\n")
PY
}
mk "$t/s1.jsonl" sess-1; mk "$t/s2.jsonl" sess-2
L=$t/plan/failures.md
out=$(python3 "$F" "$t/s1.jsonl" --ledger "$L")
case $out in *"4 failed call(s)"*|*"3 failed call(s)"*) : ;; *) echo "FAIL count: $out"; bad=1 ;; esac
case $out in *"2 shape(s): 2 new"*) : ;; *) echo "FAIL shapes: $out"; bad=1 ;; esac
[ -e "$L" ] && { echo "FAIL dry run wrote the ledger"; bad=1; }
python3 "$F" "$t/s1.jsonl" --ledger "$L" --write >/dev/null
grep -q '^- Bash `git push` → error: failed to push some refs to .<url>. · seen 2 · last 2026-11-10 · fix: ?  \[at: session:sess-1\]$' "$L" || { echo "FAIL push line"; cat "$L"; bad=1; }
grep -q '^- Read `` → File does not exist: <path>' "$L" || { echo "FAIL read line"; cat "$L"; bad=1; }
grep -q 'rm' "$L" && { echo "FAIL a declined permission was listed"; bad=1; }
grep -q 'grep' "$L" && { echo "FAIL a bare exit code was listed"; bad=1; }
# same session again: counted once
python3 "$F" "$t/s1.jsonl" --ledger "$L" --write >/dev/null
grep -q 'seen 2 ·' "$L" || { echo "FAIL a re-merge of the same session counted twice"; cat "$L"; bad=1; }
# a person fills the fix; a second session raises the count and keeps the fix
sed -i.bak 's/fix: ?  \[at: session:sess-1\]$/fix: pull --rebase first  [at: session:sess-1]/' "$L" && rm "$L.bak"
out=$(python3 "$F" "$t/s2.jsonl" --ledger "$L" --write)
case $out in *"an earlier session hit this too"*) : ;; *) echo "FAIL known shape not flagged: $out"; bad=1 ;; esac
grep -q 'seen 4 · last 2026-11-10 · fix: pull --rebase first  \[at: session:sess-1, session:sess-2\]' "$L" || { echo "FAIL merge kept fix"; cat "$L"; bad=1; }
# a session id resolves under NT_TRANSCRIPTS
mkdir -p "$t/tx/proj"; cp "$t/s1.jsonl" "$t/tx/proj/sess-9.jsonl"
NT_TRANSCRIPTS=$t/tx python3 "$F" sess-9 --ledger "$t/other.md" >/dev/null || { echo "FAIL session id lookup"; bad=1; }
set +e; python3 "$F" nope --ledger "$t/o.md" 2>/dev/null; rc=$?; set -e
[ "$rc" -eq 2 ] || { echo "FAIL missing transcript exit $rc"; bad=1; }
[ "$bad" -eq 0 ] && echo ok
