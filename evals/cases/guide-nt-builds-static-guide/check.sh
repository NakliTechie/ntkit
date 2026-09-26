#!/bin/sh
# A generated single-file guide with real captures, search, a HERO_FLOW the launch video
# can film, and a capture that waits for animations instead of a fixed sleep.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -f guide/index.html ] || fail "no guide/index.html"
cap=$(ls guide/capture.* 2>/dev/null | head -1)
[ -n "$cap" ] || fail "no guide/capture.* generator"
[ -f guide/build_index.py ] && [ -f guide/regenerate.sh ] || fail "generator incomplete (build_index.py, regenerate.sh)"
n=$(find guide/screenshots -name '*.png' -size +10k 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -ge 3 ] || fail "only $n non-blank screenshots (want >= 3)"
grep -q 'data-search' guide/index.html || fail "no data-search attributes: search cannot filter"
grep -Eqi '<input[^>]*search' guide/index.html || fail "no search input"
! grep -Eqi '<script[^>]+src=["'"'"']https?:' guide/index.html || fail "loads remote scripts; the guide must be self-contained"
grep -q 'getAnimations' "$cap" || fail "$cap does not wait for animations to finish"
CAP="$cap" python3 - <<'PY' || exit 1
import glob, os, re, sys
src = open(os.environ["CAP"]).read()
m = re.search(r"HERO_FLOW\s*(?::[^=]*)?=\s*[\[\(]([^\]\)]*)[\]\)]", src)
if not m:
    sys.exit("FAIL: no HERO_FLOW list in " + os.environ["CAP"])
ids = re.findall(r"[\"']([^\"']+)[\"']", m.group(1))
if not 2 <= len(ids) <= 3:
    sys.exit(f"FAIL: HERO_FLOW names {len(ids)} captures, want 2-3")
for i in ids:
    if not glob.glob(f"guide/screenshots/**/{os.path.basename(i)}*.png", recursive=True):
        sys.exit(f"FAIL: HERO_FLOW names {i}, which has no screenshot")
PY
git ls-files --error-unmatch guide/index.html >/dev/null 2>&1 || fail "guide/index.html is not committed"
echo PASS
