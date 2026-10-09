#!/bin/sh
# The readiness predicate in guide-nt's capture.md: false while a finite animation runs,
# true once it ends, and never blocked by an infinite spinner. Runs the snippet as written.
set -eu
python3 -c 'import playwright' 2>/dev/null && [ -d "/Applications/Google Chrome.app" ] \
  || { echo "needs python playwright and Google Chrome"; exit 77; }
doc=$(cd "$(dirname "$0")/.." && pwd)/skills/guide-nt/references/capture.md
DOC="$doc" python3 - <<'PY'
import os, re, sys
from playwright.sync_api import sync_playwright
text = open(os.environ["DOC"]).read()
m = re.search(r"```js\n(.*?)```", text, re.S)
if not m:
    sys.exit("FAIL: no ```js block in capture.md")
pred = "\n".join(l for l in m.group(1).splitlines() if not l.strip().startswith("//")).strip()
page_html = """<style>
  @keyframes rise { from { opacity: 0 } to { opacity: 1 } }
  @keyframes spin { to { transform: rotate(360deg) } }
  #a { animation: rise 1200ms ease-out; }  #s { animation: spin 1s linear infinite; }
</style><div id=a>content</div><div id=s>*</div>"""
with sync_playwright() as p:
    b = p.chromium.launch(channel="chrome")  # the installed Chrome; no browser download
    pg = b.new_page()
    pg.set_content(page_html)
    if pg.evaluate(f"({pred})()"):
        sys.exit("FAIL: predicate is true while a 1.2 s animation is still running")
    pg.wait_for_function(pred, timeout=5000)   # must turn true despite the infinite spinner
    b.close()
print("ok")
PY
