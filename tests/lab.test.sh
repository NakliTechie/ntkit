#!/bin/sh
# lab-nt lab.py: sealed state, lockbox and fence (committed and uncommitted changes, ancestor fences),
# keep decisions under the joint gate, budget, child and fork carving, depth, legs and odometer, merge
# grant. A scratch git repo; no network, no model calls. Contract: skills/lab-nt/bin/lab.py docstring.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
command -v git >/dev/null || { echo "git not found"; exit 77; }
BIN=$(cd "$(dirname "$0")/.." && pwd)/skills/lab-nt/bin
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cd "$work"
g() { git -c user.name=t -c user.email=t@example.invalid "$@"; }
git init -q
mkdir -p src/attn harness
printf 'kernel v1\n' > src/kernel.metal
printf 'print(1)\n' > harness/bench.py
printf 'gate\n' > harness/gate.sh
printf 'cfg\n' > harness/.cfg
printf '# notes\n' > README.md
g add -A && g commit -qm init
PYTHONDONTWRITEBYTECODE=1 BIN="$BIN" python3 - <<'PY'
import contextlib, io, json, os, subprocess, sys
from pathlib import Path
sys.path.insert(0, os.environ["BIN"])
import lab

failures = []

def run(*argv):
    out = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
        try:
            rc = lab.main([str(a) for a in argv])
        except SystemExit as e:
            rc = e.code if isinstance(e.code, int) else 2
            if not isinstance(e.code, int): print(e.code)
    return rc, out.getvalue()

def expect(desc, got, want_rc, want_text=""):
    rc, out = got
    if rc != want_rc or want_text not in out:
        failures.append(f"{desc}: exit {rc} (wanted {want_rc}), wanted {want_text!r}\n{out}")

def commit(msg):
    subprocess.run(["git", "-c", "user.name=t", "-c", "user.email=t@example.invalid", "commit", "-qam", msg], check=True)

D = "plan/lab/k"

# matcher: ** spans zero or more segments, * stays in one segment, hidden files count
if not lab.matches("src/k.py", ["src/**/*.py"]) or lab.matches("src/a/b", ["src/*"]) or not lab.matches("src/a/b", ["src/**"]):
    failures.append("glob matcher wrong")
if "harness/.cfg" not in lab.expand(["harness/**"]):
    failures.append("expand skips hidden files")

# init refusals and success
expect("init without fence", run("init", D, "--lock", "harness/**", "--experiments", "25"), 1, "fence")
expect("init with empty lockbox", run("init", D, "--fence", "src/**", "--lock", "nothing/**", "--experiments", "25"), 1, "lockbox is empty")
expect("lock inside fence", run("init", D, "--fence", "src/**", "harness/**", "--lock", "harness/**", "--experiments", "25"), 1, "inside the fence")
expect("init ok", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 0, "3 locked files")
expect("init twice refused", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 1, "already holds")

# the seal: a hand edit to the state file is refused
st = Path(D, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"merge": "none"', '"merge": "auto"'))
expect("tampered state refused", run("check", D), 1, "does not match its seal")
st.write_text(orig)

# check: uncommitted and committed changes against the leg's start
Path("src/kernel.metal").write_text("kernel v2\n")
expect("change inside fence", run("check", D), 0, "inside the fence")
Path("README.md").write_text("# edited\n"); commit("outside")
expect("committed change outside fence", run("check", D), 1, "outside the fence: README.md")
subprocess.run(["git", "reset", "-q", "--hard", "HEAD~1"], check=True)
Path("harness/bench.py").write_text("print(2)\n")
expect("locked file changed", run("check", D), 1, "locked file changed: harness/bench.py")
subprocess.run(["git", "checkout", "-q", "harness/bench.py"], check=True)
Path("harness/new.py").write_text("x\n")
expect("new file in locked glob", run("check", D), 1, "new file in a locked path: harness/new.py")
Path("harness/new.py").unlink()
expect("clean again", run("check", D), 0, "ok")

# noise
expect("noise needs 3", run("noise", "1", "2"), 1, "at least 3")
expect("noise spread", run("noise", "210", "214", "212"), 0, "noise 4 mean 212")

# keep under the joint gate: KEEP exit 0, REVERT exit 4
expect("gate fail reverts", run("keep", D, "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "300"), 4, "REVERT: the gate failed")
expect("gain beats noise", run("keep", D, "--noise", "4", "--gate", "pass", "--base", "200", "202", "--cand", "210", "212"), 0, "KEEP")
expect("gain inside noise", run("keep", D, "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "203"), 4, "REVERT")
expect("noise required", run("keep", D, "--gate", "pass", "--base", "200", "--cand", "203"), 2, "usage")
expect("paired gain", run("keep", D, "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2"), 0, "KEEP")
expect("paired mixed", run("keep", D, "--gate", "pass", "--paired", "1", "-2", "1.5", "-2.5", "1", "-2", "1", "-2", "1", "-2"), 4, "REVERT")
expect("paired too few", run("keep", D, "--gate", "pass", "--paired", "0.0001"), 2, "at least 10")

# lower is better flips the sign
L = "plan/lab/lat"
run("init", L, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--lower-is-better")
expect("lower is better keep", run("keep", L, "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "8"), 0, "KEEP")
expect("lower is better revert", run("keep", L, "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "12"), 4, "REVERT")

# spend books before running; a budget of N runs N experiments
B = "plan/lab/b"
Path(B).mkdir(parents=True); Path(B, "contract.md").write_text("question v1\n")
run("init", B, "--fence", "src/**", "--lock", "harness/**", "--experiments", "2", "--max-legs", "2")
expect("spend 1", run("spend", B), 0, "1 of 2 used, 1 left")
expect("spend 2", run("spend", B), 0, "2 of 2 used, 0 left")
expect("spend past budget", run("spend", B), 3, "BUDGET")
expect("negative refund refused", run("spend", B, "--n", "-5"), 1, "at least 1")

# children: budget carving, fence, depth limit, ancestor fences, no re-arm
expect("child too big", run("child", D, f"{D}/child-1", "--experiments", "13"), 1, "1 to 12")
expect("child fence outside", run("child", D, f"{D}/child-1", "--experiments", "6", "--fence", "README.md"), 1, "outside the parent's")
expect("child ok", run("child", D, f"{D}/child-1", "--experiments", "6", "--fence", "src/attn/**"), 0, "depth 1 with 6")
p = json.loads(Path(D, "lab.json").read_text()); c = json.loads(Path(D, "child-1", "lab.json").read_text())
if p["spent"] != 6 or c["locked"] != p["locked"] or c["depth"] != 1 or c["merge"] != "none":
    failures.append(f"child bookkeeping wrong: parent {p}, child {c}")
Path("src/kernel.metal").write_text("kernel v3\n")
expect("child fence enforced", run("check", f"{D}/child-1"), 1, "outside the fence: src/kernel.metal")
subprocess.run(["git", "checkout", "-q", "src/kernel.metal"], check=True)
expect("child exists", run("child", D, f"{D}/child-1", "--experiments", "2"), 1, "already holds")
expect("grandchild ok", run("child", f"{D}/child-1", f"{D}/child-1/child-1", "--experiments", "3"), 0, "depth 2")
expect("depth 3 refused", run("child", f"{D}/child-1/child-1", f"{D}/child-1/child-1/child-1", "--experiments", "1"), 1, "exceeds max depth 2")
expect("child never re-arms", run("leg", f"{D}/child-1", "--experiments", "3"), 1, "never re-arms")

# forks: same depth, carved budget, no fork of a fork
expect("forks schedule", run("forks", D), 0, "fork at experiments 8 and 17")
expect("forks off for short leg", run("forks", B), 0, "off")
expect("fork ok", run("fork", D, f"{D}/f1", "--experiments", "2"), 0, "fork at depth 0 with 2")
expect("fork of fork refused", run("fork", f"{D}/f1", f"{D}/f1/f1", "--experiments", "1"), 1, "does not fork again")

# legs: odometer, stagnant with unchanged contract, changed lock
expect("end stagnant", run("end", B, "STAGNANT"), 0, "ended STAGNANT")
expect("stagnant unchanged contract refused", run("leg", B, "--experiments", "4"), 1, "unchanged")
Path(B, "contract.md").write_text("question v2, new fence\n")
expect("leg ok after contract change", run("leg", B, "--experiments", "4"), 0, "leg 2 of 2 with 4")
if json.loads(Path(B, "lab.json").read_text())["spent"] != 0:
    failures.append("leg did not reset the counter")
expect("odometer exhausted", run("leg", B, "--experiments", "4"), 1, "RETIRED")
Path("harness/gate.sh").write_text("changed\n")
expect("leg parked on changed lock", run("leg", D, "--experiments", "4"), 1, "PARKED")
subprocess.run(["git", "checkout", "-q", "harness/gate.sh"], check=True)

# merge grant
expect("no grant", run("merge-ok", D), 1, "no merge grant")
M = "plan/lab/m"
run("init", M, "--fence", "src/**", "--lock", "harness/**", "--experiments", "3", "--merge", "auto")
expect("grant", run("merge-ok", M), 0, "merge granted")
expect("child has no grant", run("child", M, f"{M}/c1", "--experiments", "1"), 0, "")
expect("child merge refused", run("merge-ok", f"{M}/c1"), 1, "no merge grant")

if failures:
    print("\n\n".join(failures)); sys.exit(1)
print("all lab.py cases pass")
PY
