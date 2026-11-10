#!/bin/sh
# supervise.sh — watch delegated work that outlives the session: cloud jobs, long scripts, other agents' CLIs.
#
#   supervise.sh register NAME KIND [--probe CMD] [--eta MIN] [--note TEXT]   KIND: cloud|agent|cli|job
#   supervise.sh checkin [NOTE]       probe every active delegation, print its state, stamp the ledger
#   supervise.sh status               the same, without stamping the ledger
#   supervise.sh done NAME [OUTCOME]  retire a delegation (a record stays under done/)
#   supervise.sh supervise [--every SEC] [--stale SEC] [--idle-exit N]
#        one looping supervisor per scope; run it detached. It alerts and exits 2 when work is running and
#        nobody has checked in for --stale seconds (default 1200), and exits 3 when a delegation passes its
#        ETA x 1.5 + 15 min. It exits 0 after N cycles with nothing running (default 2). Cycle: --every (1800).
#
# PROBE: a shell command that exits 0 while the work still runs, for example `kill -0 12345`,
#   `test ! -f /path/done.marker`, or a cloud CLI's describe call. No probe means "manual": the delegation
#   counts as running until `done`.
# ETA (required): minutes, as 45, 45m or 2h. A probe is required for cloud and job; agent and cli may run
#   without one (manual). Each probe gets NT_SUPERVISE_PROBE_TIMEOUT seconds (default 60); a probe that takes
#   longer is reported as PROBE TIMED OUT and counted as running.
# State: ${NT_SUPERVISE_HOME:-${XDG_STATE_HOME:-~/.local/state}/ntkit/supervise}/<scope>/, where scope is the
#   git repository's folder name (or $NT_SUPERVISE_SCOPE), so two repositories with the same folder name share
#   one scope. Times print in local time; set TZ to change it.
# Alerts: desktop (macOS osascript, Linux notify-send) and, when NTFY_TOPIC is set, an ntfy.sh push.
#   NT_SUPERVISE_NO_NOTIFY=1 suppresses them (tests). Exit 64 on a usage error.
set -u
ROOT=${NT_SUPERVISE_HOME:-${XDG_STATE_HOME:-$HOME/.local/state}/ntkit/supervise}
SCOPE=${NT_SUPERVISE_SCOPE:-$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")}
case $SCOPE in ''|.*|*/*) echo "bad scope '$SCOPE': no slash, no leading dot" >&2; exit 64 ;; esac
D=$ROOT/$SCOPE
mkdir -p "$D/active" "$D/done" 2>/dev/null && [ -w "$D/active" ] || { echo "cannot write state under $D" >&2; exit 73; }

now() { date +%s; }
if [ "$(date -r 0 +%Y 2>/dev/null)" = 1970 ] || [ "$(date -r 0 +%Y 2>/dev/null)" = 1969 ]; then
  stamp() { date -r "${1:-$(now)}" '+%F %H:%M'; }        # BSD: -r takes seconds
else
  stamp() { date -d "@${1:-$(now)}" '+%F %H:%M'; }       # GNU: -r takes a file name
fi
field() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }
usage() { sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 64; }
alive() {  # the pid is live and is a supervisor, so a reused pid never counts
  [ -f "$D/supervisor.pid" ] || return 1
  pid=$(cat "$D/supervisor.pid" 2>/dev/null)
  case $pid in ''|*[!0-9]*) return 1 ;; esac
  kill -0 "$pid" 2>/dev/null && ps -p "$pid" -o args= 2>/dev/null | grep -q supervise
}
put() {  # put <file> : write stdin through a temporary file, then rename; fail loudly
  tmp="$1.tmp.$$"
  cat > "$tmp" && mv "$tmp" "$1" || { rm -f "$tmp"; echo "cannot write $1" >&2; exit 73; }
}

notify() {
  msg=$1
  echo "$(stamp) ALERT $msg" >> "$D/supervisor.log"
  [ "${NT_SUPERVISE_NO_NOTIFY:-0}" = 1 ] && return 0
  if command -v osascript >/dev/null 2>&1; then
    osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"' \
      -e 'end run' "$msg" "supervise: $SCOPE" >/dev/null 2>&1 || true
  elif command -v notify-send >/dev/null 2>&1; then
    notify-send -- "supervise: $SCOPE" "$msg" 2>/dev/null || true
  fi
  if [ -n "${NTFY_TOPIC:-}" ]; then
    printf '%s' "supervise[$SCOPE]: $msg" | curl -fsS -m 10 --data-binary @- "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true
  fi
  return 0
}

running() {  # 0 = still running, 1 = ended, 2 = probe timed out (counted as running)
  probe=$(field "$1" probe)
  [ -z "$probe" ] && return 0
  sh -c "$probe" >/dev/null 2>&1 & p=$!
  ( trap 'kill "$s" 2>/dev/null; exit 0' TERM
    sleep "${NT_SUPERVISE_PROBE_TIMEOUT:-60}" & s=$!; wait "$s" && kill -USR2 "$p" 2>/dev/null ) >/dev/null 2>&1 & w=$!
  wait "$p" 2>/dev/null; rc=$?
  kill "$w" 2>/dev/null; wait "$w" 2>/dev/null
  # the watcher stops a slow probe with SIGUSR2, which no probe sends itself: exit 128 + its number
  [ "$rc" -gt 128 ] && [ "$(kill -l "$rc" 2>/dev/null)" = USR2 ] && return 2
  [ "$rc" -eq 0 ]
}

report() {  # one line per active delegation; sets LIVE to the count still running
  LIVE=0; any=0
  for f in "$D"/active/*; do
    [ -f "$f" ] || continue
    any=1
    name=$(basename "$f"); kind=$(field "$f" kind); started=$(field "$f" started); eta=$(field "$f" eta)
    age=$(( ($(now) - ${started:-$(now)}) / 60 ))
    running "$f"; rc=$?
    if [ "$rc" -ne 1 ]; then
      LIVE=$((LIVE + 1)); state=running
      [ "$rc" -eq 2 ] && state="PROBE TIMED OUT (counted as running)"
      if [ -n "$eta" ] && [ "$age" -gt $(( eta * 3 / 2 + 15 )) ]; then state="OVERDUE (eta ${eta}m)"; fi
    else
      state="ENDED per probe: run done $name"
    fi
    printf "  %-24s %-6s %4sm  %s\n" "$name" "$kind" "$age" "$state"
  done
  [ "$any" = 1 ] || echo "  (no active delegations)"
  return 0
}

minutes() {  # 45 | 45m | 2h -> a positive decimal number of minutes
  case $1 in
    *h) v=${1%h}; mult=60 ;;
    *m) v=${1%m}; mult=1 ;;
    *) v=$1; mult=1 ;;
  esac
  case $v in ''|*[!0-9]*) return 1 ;; esac
  v=$(printf '%s' "$v" | sed 's/^0*//'); [ -n "$v" ] && [ ${#v} -le 6 ] || return 1
  echo $((v * mult))
}

cmd=${1:-status}; [ $# -gt 0 ] && shift
case $cmd in
  register)
    [ $# -ge 2 ] || usage
    name=$1 kind=$2; shift 2
    case $name in ''|*[!A-Za-z0-9._-]*|.*) echo "NAME must be letters, digits, dot, dash or underscore" >&2; exit 64 ;; esac
    case $kind in cloud|agent|cli|job) ;; *) echo "KIND must be cloud|agent|cli|job (a review run by another CLI is cli)" >&2; exit 64 ;; esac
    probe="" eta="" note=""
    while [ $# -gt 0 ]; do
      case $1 in
        --probe) [ $# -ge 2 ] || usage; probe=$2; shift 2 ;;
        --eta) [ $# -ge 2 ] || usage; eta=$(minutes "$2") || { echo "--eta takes minutes: 45, 45m or 2h" >&2; exit 64; }; shift 2 ;;
        --note) [ $# -ge 2 ] || usage; note=$2; shift 2 ;;
        *) echo "unknown argument $1" >&2; exit 64 ;;
      esac
    done
    [ -n "$eta" ] || { echo "--eta is required (minutes: 45, 45m or 2h)" >&2; exit 64; }
    case $kind in cloud|job) [ -n "$probe" ] || { echo "--probe is required for $kind" >&2; exit 64; } ;; esac
    printf "name=%s\nkind=%s\nprobe=%s\neta=%s\nnote=%s\nstarted=%s\n" "$name" "$kind" "$probe" "$eta" "$note" "$(now)" | put "$D/active/$name" || exit 73
    echo "registered $name ($kind) in $SCOPE${eta:+, eta ${eta}m}${probe:+, probe: $probe}"
    alive || echo "note: no supervisor running for $SCOPE; start one detached: nohup $0 supervise >/dev/null 2>&1 &"
    ;;
  checkin|status)
    echo "== $SCOPE · $(stamp)"
    report
    if [ "$cmd" = checkin ]; then
      echo "$(now) $(stamp) checkin ${1:-}" >> "$D/ledger"
      if alive; then echo "  supervisor: pid $(cat "$D/supervisor.pid") alive"
      else echo "  supervisor: NOT RUNNING; start it detached: nohup $0 supervise >/dev/null 2>&1 &"; fi
    fi
    ;;
  done)
    [ $# -ge 1 ] || usage
    name=$1; f=$D/active/$name
    case $name in */*|.*) echo "bad NAME" >&2; exit 64 ;; esac
    [ -f "$f" ] || { echo "no active delegation $name" >&2; exit 1; }
    { cat "$f"; echo "ended=$(now)"; echo "outcome=${2:-}"; } | put "$D/done/$name.$(now)" || exit 73
    rm -f "$f"; echo "done: $name${2:+ — $2}"
    ;;
  supervise)
    every=1800 stale=1200 idle_exit=2
    while [ $# -gt 0 ]; do
      case $1 in
        --every) every=$2; shift 2 ;;
        --stale) stale=$2; shift 2 ;;
        --idle-exit) idle_exit=$2; shift 2 ;;
        *) echo "unknown argument $1" >&2; exit 64 ;;
      esac
    done
    if alive; then echo "supervisor already running for $SCOPE (pid $(cat "$D/supervisor.pid"))"; exit 0; fi
    echo $$ | put "$D/supervisor.pid" || exit 73
    trap 'rm -f "$D/supervisor.pid"' EXIT
    trap 'exit 1' HUP INT TERM
    echo "$(stamp) supervisor start every=${every}s stale=${stale}s" >> "$D/supervisor.log"
    idle=0
    while :; do
      sleep "$every"
      report > "$D/last-report.txt"
      last=$(tail -1 "$D/ledger" 2>/dev/null | cut -d' ' -f1); last=${last:-0}
      ledger_age=$(( $(now) - last ))
      echo "$(stamp) live=$LIVE ledger_age=${ledger_age}s" >> "$D/supervisor.log"
      if [ "$LIVE" -eq 0 ]; then
        idle=$((idle + 1))
        if [ "$idle" -ge "$idle_exit" ]; then echo "$(stamp) idle, exiting" >> "$D/supervisor.log"; exit 0; fi
        continue
      fi
      idle=0
      if [ "$ledger_age" -gt "$stale" ]; then
        notify "check-in lapsed $((ledger_age / 60)) min with $LIVE delegation(s) running"
        cat "$D/last-report.txt"; exit 2
      fi
      if grep -q OVERDUE "$D/last-report.txt"; then
        notify "overdue: $(grep OVERDUE "$D/last-report.txt" | awk '{print $1}' | tr '\n' ' ')"
        cat "$D/last-report.txt"; exit 3
      fi
    done
    ;;
  -h|--help|help) usage ;;
  *) usage ;;
esac
