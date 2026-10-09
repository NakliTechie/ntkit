#!/bin/sh
# The eval fixture works: a broken fixture makes every eval that uses it grade the app,
# not the skill. Serves evals/fixtures/tally and drives it in the installed Chrome.
set -eu
python3 -c 'import playwright' 2>/dev/null && [ -d "/Applications/Google Chrome.app" ] \
  || { echo "needs python playwright and Google Chrome"; exit 77; }
dir=$(cd "$(dirname "$0")/.." && pwd)/evals/fixtures/tally
DIR="$dir" python3 - <<'PY'
import functools, http.server, os, sys, threading
from playwright.sync_api import sync_playwright
class Quiet(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass
handler = functools.partial(Quiet, directory=os.environ["DIR"])
srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
threading.Thread(target=srv.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{srv.server_address[1]}"
def check(ok, msg):
    if not ok:
        sys.exit("FAIL: " + msg)
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome")
    pg = b.new_page()
    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.goto(base + "/")
    check("Count anything" in pg.inner_text("h1"), "landing headline missing")
    pg.click("text=Open Tally")
    pg.wait_for_url("**/app.html")
    check(pg.is_visible("#empty"), "first run does not show the empty state")
    pg.fill("#name", "Tea")
    pg.click("text=Add counter")
    pg.click("li.counter button")
    check(pg.inner_text("li.counter .total") == "1", "+1 did not count")
    threw = pg.evaluate("() => { try { tally.seed([{ name: 'x' }]); return false } catch (e) { return true } }")
    check(threw, "seed() overwrote existing counters without { replace: true }")
    pg.evaluate("() => tally.seed([{ name: '<img src=x onerror=window.pwn=1>', count: 5, today: 2 }], { replace: true })")
    check(pg.evaluate("() => window.pwn") is None, "a counter name ran as HTML")
    check(pg.evaluate("() => tally.list()[0].count") == 5, "seed() did not load the counter")
    check(pg.inner_text("li.counter .today") == "2 today", "seed() did not set today's count")
    check(not errors, "page errors: " + "; ".join(errors))
    b.close()
srv.shutdown()
print("ok")
PY
