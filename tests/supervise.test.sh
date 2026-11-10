#!/bin/sh
# supervise-nt/bin/supervise.sh: register (ETA units, refused kinds and names), checkin and status,
# probe-ended and overdue states, done records, and the supervisor's three exits (idle, stale, overdue).
set -eu
S=$(cd "$(dirname "$0")/.." && pwd)/skills/supervise-nt/bin/supervise.sh
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
export NT_SUPERVISE_HOME=$t/state NT_SUPERVISE_SCOPE=proj NT_SUPERVISE_NO_NOTIFY=1
D=$t/state/proj; bad=0
fail() { echo "FAIL $*"; bad=1; }
has() { case $1 in *"$2"*) : ;; *) fail "$3: output lacks '$2': $1" ;; esac; }
rc() { set +e; out=$(sh "$S" "$@" 2>&1); code=$?; set -e; }

rc register a1 job --eta 60m --probe true; [ "$code" -eq 0 ] || fail "60m refused"
[ "$(grep '^eta=' "$D/active/a1")" = "eta=60" ] || fail "60m stored as $(grep '^eta=' "$D/active/a1")"
rc register a2 job --eta 2h --probe true; grep -q '^eta=120$' "$D/active/a2" || fail "2h not 120"
rc register a3 job --eta 45 --probe true; grep -q '^eta=45$' "$D/active/a3" || fail "45 not 45"
rc register a5 job --eta 08m --probe true; grep -q '^eta=8$' "$D/active/a5" || fail "08m not 8"
rc register a6 job --eta 0 --probe true; [ "$code" -eq 64 ] || fail "zero eta accepted"
rc register a7 agent; [ "$code" -eq 64 ] || fail "missing eta accepted"
rc register a8 cloud --eta 5; [ "$code" -eq 64 ] || fail "cloud without probe accepted"
rc register a9 cli --eta 5; [ "$code" -eq 0 ] || fail "cli without probe refused"; rm -f "$D/active/a9" "$D/active/a5"
rc register a4 job --eta 1x; [ "$code" -eq 64 ] || fail "bad eta exit $code"
rc register r1 review --eta 5; [ "$code" -eq 64 ] || fail "kind review accepted"; has "$out" "is cli" "kind hint"
rc register ../x job --eta 5; [ "$code" -eq 64 ] || fail "path name accepted"
rc register b1 agent --eta 5; has "$out" "no supervisor running" "register note"
rm -f "$D/active/a2" "$D/active/a3" "$D/active/b1"

# probe states: running, ended, overdue
sleep 300 & held=$!
trap 'kill "$held" 2>/dev/null; rm -rf "$t"' EXIT
rc register live job --probe "kill -0 $held" --eta 30
rc register gone job --probe "false" --eta 30
rc register slow job --probe "sleep 30" --eta 30
rc register late agent --eta 1
sed -i.bak "s/^started=.*/started=$(( $(date +%s) - 3600 ))/" "$D/active/late" && rm "$D/active/late.bak"
export NT_SUPERVISE_PROBE_TIMEOUT=1; rc checkin "first look"; unset NT_SUPERVISE_PROBE_TIMEOUT
has "$out" "live" "checkin lists"; has "$out" "ENDED per probe" "probe ended"; has "$out" "OVERDUE (eta 1m)" "overdue"
has "$out" "supervisor: NOT RUNNING" "no supervisor"
has "$out" "PROBE TIMED OUT" "probe timeout"; rc done slow
grep -q 'checkin first look$' "$D/ledger" || fail "ledger not stamped"
lines=$(wc -l <"$D/ledger"); rc status; [ "$(wc -l <"$D/ledger")" -eq "$lines" ] || fail "status stamped the ledger"

rc done gone "probe said it ended"; has "$out" "done: gone" "done"
ls "$D/done" | grep -q '^gone\.' || fail "no done record"; grep -q '^outcome=probe said it ended$' "$D"/done/gone.* || fail "outcome missing"
rc done nobody; [ "$code" -eq 1 ] || fail "done on unknown name exit $code"

# supervisor: overdue → exit 3 (ledger fresh)
rc checkin; rc supervise --every 1 --stale 9999; [ "$code" -eq 3 ] || fail "overdue exit $code"
grep -q 'ALERT overdue: late' "$D/supervisor.log" || fail "overdue not logged"
[ -f "$D/supervisor.pid" ] && fail "pidfile left after exit"
# stale ledger with work running → exit 2
rc done late; echo "1 old checkin" >>"$D/ledger"
rc supervise --every 1 --stale 5; [ "$code" -eq 2 ] || fail "stale exit $code"
grep -q 'ALERT check-in lapsed' "$D/supervisor.log" || fail "stale not logged"
# nothing running → idle exit 0
rc done live; rc done a1; rc supervise --every 1 --idle-exit 1; [ "$code" -eq 0 ] || fail "idle exit $code"
# a second supervisor refuses to start while one runs
sh "$S" register keep agent --eta 30 >/dev/null
sh "$S" supervise --every 30 >/dev/null 2>&1 & sup=$!
sleep 1; rc supervise; has "$out" "already running" "single supervisor"; kill "$sup" 2>/dev/null; wait "$sup" 2>/dev/null || true
[ -f "$D/supervisor.pid" ] && fail "pidfile left after kill"
# unwritable state and a bad scope stop with an error, never a false "registered"
set +e; out=$(NT_SUPERVISE_HOME=/dev/null/x sh "$S" register z agent --eta 5 2>&1); code=$?; set -e
[ "$code" -eq 73 ] || fail "unwritable home exit $code: $out"
set +e; out=$(NT_SUPERVISE_SCOPE=../up sh "$S" status 2>&1); code=$?; set -e
[ "$code" -eq 64 ] || fail "bad scope exit $code"
[ "$bad" -eq 0 ] && echo ok
