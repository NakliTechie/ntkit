#!/bin/sh
# research-nt fetch.py against a local HTTP server: text extraction, the log, the page store,
# the address guard (direct and through a redirect), the fetch cap, --stdin, and a cited fetch
# passing check.py's G1. The real guard refuses 127.0.0.1, so the test swaps the module's guard
# for one that allows only this server; nothing else reaches the network.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
BIN=$(cd "$(dirname "$0")/.." && pwd)/skills/research-nt/bin
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
PYTHONDONTWRITEBYTECODE=1 BIN="$BIN" WORK="$work" python3 - <<'PY'
import contextlib, http.server, io, json, os, shutil, sys, threading
from pathlib import Path
sys.path.insert(0, os.environ["BIN"])
import check, fetch

work = Path(os.environ["WORK"])
failures = []

PAGES = {
    "/page.html": ("text/html; charset=utf-8",
        b"<html><head><title>Markowitz &amp; the frontier</title><style>p{}</style></head><body>"
        b"<nav>Home | About</nav><script>var secret = 'SCRIPT-TEXT';</script>"
        b"<h1>Portfolio Selection</h1><p>Diversification lowers variance.</p>"
        b"<p>Second&nbsp;paragraph.</p><footer>FOOTER-TEXT</footer></body></html>"),
    "/notes.txt": ("text/plain", b"Plain notes.\nLine two."),
    "/empty.html": ("text/html", b"<html><body><script>render()</script></body></html>"),
    "/image.png": ("image/png", b"\x89PNG\r\n"),
}

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass
    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/to-private":
            self.send_response(302); self.send_header("Location", "http://10.255.255.1/secret"); self.end_headers(); return
        if path == "/to-page":
            self.send_response(301); self.send_header("Location", "/page.html"); self.end_headers(); return
        if path not in PAGES:
            self.send_response(404); self.end_headers(); return
        ctype, body = PAGES[path]
        self.send_response(200); self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body))); self.end_headers(); self.wfile.write(body)

srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=srv.serve_forever, daemon=True).start()
base = f"http://127.0.0.1:{srv.server_address[1]}"
fetch.address_guard = lambda host: None if host == "127.0.0.1" else fetch.real_address_guard(host)

store = work / "store"
def run(*argv, stdin=None):
    out = io.StringIO()
    old_stdin = sys.stdin
    if stdin is not None:
        sys.stdin = io.StringIO(stdin)
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            rc = fetch.main([str(a) for a in argv] + ["--store", str(store)])
    finally:
        sys.stdin = old_stdin
    return rc, out.getvalue()

def expect(desc, got, want_rc, want_text=""):
    rc, out = got
    if rc != want_rc or want_text not in out:
        failures.append(f"{desc}: exit {rc} (wanted {want_rc}), wanted text {want_text!r}\n{out}")

def log(d):
    p = d / "fetch-log.jsonl"
    return [json.loads(l) for l in p.read_text().splitlines()] if p.exists() else []

d = work / "run-a"; d.mkdir()

# --- a good HTML page --------------------------------------------------------
got = run(d, f"{base}/page.html", "--section", "S1.1")
expect("html page fetched", got, 0, "Diversification lowers variance.")
out = got[1]
for leaked in ("SCRIPT-TEXT", "FOOTER-TEXT", "Home | About"):
    if leaked in out:
        failures.append(f"html extraction kept {leaked!r}")
if '"Markowitz & the frontier"' not in out or "Second paragraph." not in out:
    failures.append("html title or entity decoding wrong\n" + out)
entry = log(d)[-1]
stored = Path(entry["path"])
if entry["status"] != "ok" or entry["http_status"] != 200 or entry["section"] != "S1.1" or not stored.is_file():
    failures.append(f"log entry wrong: {entry}")
elif stored.parent != store / "run-a" or "Portfolio Selection" not in stored.read_text():
    failures.append(f"page store wrong: {stored}")
if "_text" in entry or "text" in entry:
    failures.append("the log must not carry page text")

expect("plain text", run(d, f"{base}/notes.txt", "--section", "S1.1"), 0, "Line two.")
expect("redirect followed", run(d, f"{base}/to-page", "--section", "S1.1"), 0, "Portfolio Selection")
if not log(d)[-1]["final_url"].endswith("/page.html"):
    failures.append(f"final_url not recorded: {log(d)[-1]}")

# --- failures are logged and count ----------------------------------------------
expect("404", run(d, f"{base}/missing", "--section", "S1.2"), 1, "HTTP 404")
expect("js-only page", run(d, f"{base}/empty.html", "--section", "S1.2"), 1, "no readable text")
expect("binary type", run(d, f"{base}/image.png", "--section", "S1.2"), 1, "unsupported content type image/png")
expect("redirect to a private address", run(d, f"{base}/to-private", "--section", "S1.2"), 1, "non-public address (10.255.255.1)")
if log(d)[-1]["status"] != "refused":
    failures.append(f"refusal not logged as refused: {log(d)[-1]}")
expect("file scheme", run(d, "file:///etc/passwd", "--section", "S1.2"), 1, "only http and https")

# --- the real guard ----------------------------------------------------------
for host in ("127.0.0.1", "localhost", "169.254.169.254", "10.0.0.1", "192.168.1.1", "::1"):
    try:
        fetch.real_address_guard(host)
        failures.append(f"real guard let {host} through")
    except fetch.Refused:
        pass

# --- the cap comes from spec.md, not a flag ------------------------------------------
c = work / "run-cap"; c.mkdir()
(c / "spec.md").write_text("# ResearchSpec\n## Run settings\n- fetches_per_section: 2\n## S1 | A\n### S1.1 | B\n"
                            "#### What to cover\nx\n#### Research questions\n- q\n#### Required entities\n- none\n"
                            "#### Source leads\n- none\n")
expect("cap: 1", run(c, f"{base}/notes.txt", "--section", "S1.1"), 0)
expect("cap: 2 (a failure counts)", run(c, f"{base}/missing", "--section", "S1.1"), 1, "HTTP 404")
expect("cap: 3 refused", run(c, f"{base}/notes.txt", "--section", "S1.1"), 1, "fetch cap reached for S1.1 (2 of 2)")
if len(log(c)) != 2:
    failures.append(f"a capped call must not be logged: {len(log(c))} lines")
expect("plan cap is 3x", run(c, f"{base}/notes.txt", "--section", "plan"), 0)
expect("unknown unit refused", run(c, f"{base}/notes.txt", "--section", "S9.9"), 2, "unit id in spec.md")
expect("bad section name", run(c, f"{base}/notes.txt", "--section", "research"), 2, "must be 'plan' or a unit id")

# --- --stdin -------------------------------------------------------------------
expect("stdin", run(d, "--section", "S2.1", "--stdin", "--url", "https://paywalled.example/a", "--via", "chrome",
                    "--title", "A", stdin="Text read in the browser."), 0, "Text read in the browser.")
if log(d)[-1]["via"] != "chrome" or log(d)[-1]["status"] != "ok":
    failures.append(f"stdin entry wrong: {log(d)[-1]}")
expect("stdin empty", run(d, "--section", "S2.1", "--stdin", "--url", "https://x.example/", stdin="  "), 1, "no text on stdin")
expect("stdin needs --url", run(d, "--section", "S2.1", "--stdin", stdin="x"), 2, "--stdin with --url")
expect("no urls", run(d, "--section", "S2.1"), 2, "give URLs")

# --- the log feeds G1 ----------------------------------------------------------
ok = check.fetched_ok(log(d))
for cited in (f"{base}/page.html?utm_source=newsletter", f"{base}/page.html/", f"{base}/to-page"):
    if check.normalize_url(cited) not in ok:
        failures.append(f"G1 would not match a fetched page cited as {cited}")
if check.normalize_url(f"{base}/missing") in ok:
    failures.append("G1 would accept a failed fetch")

srv.shutdown()
if failures:
    print(f"{len(failures)} failure(s):")
    for f in failures:
        print(" - " + f.replace("\n", "\n   "))
    sys.exit(1)
print("research-nt fetch.py: all cases pass")
PY
