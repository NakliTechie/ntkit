#!/bin/sh
# lab-nt lab.py: lockbox and fence, keep decisions under the joint gate, budget, child depth and
# budget carving, fork schedule, resumed legs. A scratch git repo; no network, no model calls.
# Contract: skills/lab-nt/bin/lab.py docstring.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
command -v git >/dev/null || { echo "git not found"; exit 77; }
BIN=$(cd "$(dirname "$0")/.." && pwd)/skills/lab-nt/bin
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
cd "$work"
g() { git -c user.name=t -c user.email=t@example.invalid "$@"; }
git init -q
mkdir -p src harness
printf 'kernel v1\n' > src/kernel.metal
printf 'print(1)\n' > harness/bench.py
printf 'gate\n' > harness/gate.sh
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
            print(e.code)
    return rc, out.getvalue()

def expect(desc, got, want_rc, want_text=""):
    rc, out = got
    if rc != want_rc or want_text not in out:
        failures.append(f"{desc}: exit {rc} (wanted {want_rc}), wanted {want_text!r}\n{out}")

D = "plan/lab/k"

# init refusals and success
expect("init without fence", run("init", D, "--lock", "harness/**", "--experiments", "25"), 1, "fence")
expect("init with empty lockbox", run("init", D, "--fence", "src/**", "--lock", "nothing/**", "--experiments", "25"), 1, "lockbox is empty")
expect("lock inside fence", run("init", D, "--fence", "src/**", "harness/**", "--lock", "harness/**", "--experiments", "25"), 1, "inside the fence")
expect("init ok", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 0, "2 locked files")
s = json.loads(Path(D, "lab.json").read_text())
if s["depth"] != 0 or s["max_depth"] != 2 or s["merge"] != "none":
    failures.append(f"init defaults wrong: {s}")

# check: inside the fence passes; outside fails; locked change fails; new untracked locked file fails
Path("src/kernel.metal").write_text("kernel v2\n")
expect("change inside fence", run("check", D), 0, "lockbox intact")
Path("README.md").write_text("# edited\n")
expect("change outside fence", run("check", D), 1, "outside the fence: README.md")
subprocess.run(["git", "checkout", "-q", "README.md"], check=True)
Path("harness/bench.py").write_text("print(2)\n")
expect("locked file changed", run("check", D), 1, "locked file changed: harness/bench.py")
subprocess.run(["git", "checkout", "-q", "harness/bench.py"], check=True)
Path("harness/new.py").write_text("x\n")
expect("new file in locked glob", run("check", D), 1, "touches a locked path: harness/new.py")
Path("harness/new.py").unlink()
expect("clean again", run("check", D), 0, "ok")

# noise
expect("noise needs 3", run("noise", "1", "2"), 1, "at least 3")
expect("noise spread", run("noise", "210", "214", "212"), 0, "noise 4 mean 212")

# keep under the joint gate
expect("gate fail reverts", run("keep", D, "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "300"), 0, "REVERT: the gate failed")
expect("gain beats noise", run("keep", D, "--noise", "4", "--gate", "pass", "--base", "200", "202", "--cand", "210", "212"), 0, "KEEP")
expect("gain inside noise", run("keep", D, "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "203"), 0, "REVERT")
expect("paired gain", run("keep", D, "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2"), 0, "KEEP")
expect("paired mixed", run("keep", D, "--gate", "pass", "--paired", "1", "-2", "1.5", "-2.5", "1", "-2"), 0, "REVERT")
expect("keep usage", run("keep", D, "--gate", "pass"), 2, "usage")

# lower is better flips the sign
L = "plan/lab/lat"
run("init", L, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--lower-is-better")
expect("lower is better keep", run("keep", L, "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "8"), 0, "KEEP")
expect("lower is better revert", run("keep", L, "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "12"), 0, "REVERT")

# spend to the budget
B = "plan/lab/b"
run("init", B, "--fence", "src/**", "--lock", "harness/**", "--experiments", "2")
expect("spend 1", run("spend", B), 0, "1 of 2")
expect("spend 2 hits budget", run("spend", B), 3, "0 left")
expect("spend past budget", run("spend", B), 3, "BUDGET")

# children: budget carving, fence, depth limit
expect("child too big", run("child", D, f"{D}/child-1", "--experiments", "13"), 1, "1 to 12")
expect("child fence outside", run("child", D, f"{D}/child-1", "--experiments", "6", "--fence", "README.md"), 1, "outside the parent's")
expect("child ok", run("child", D, f"{D}/child-1", "--experiments", "6", "--fence", "src/attn/**"), 0, "depth 1 with 6")
p = json.loads(Path(D, "lab.json").read_text())
c = json.loads(Path(D, "child-1", "lab.json").read_text())
if p["spent"] != 6 or c["locked"] != p["locked"] or c["depth"] != 1 or c["merge"] != "none":
    failures.append(f"child bookkeeping wrong: parent {p}, child {c}")
expect("child exists", run("child", D, f"{D}/child-1", "--experiments", "2"), 1, "already holds")
expect("grandchild ok", run("child", f"{D}/child-1", f"{D}/child-1/child-1", "--experiments", "3"), 0, "depth 2")
expect("depth 3 refused", run("child", f"{D}/child-1/child-1", f"{D}/child-1/child-1/child-1", "--experiments", "1"), 1, "exceeds max depth 2")

# forks
expect("forks schedule", run("forks", D), 0, "fork at experiments 8 and 17")
expect("forks off for short leg", run("forks", B), 0, "off")

# a resumed leg re-checks locks and resets the counter
expect("leg ok", run("leg", B, "--experiments", "4"), 0, "new leg with 4")
if json.loads(Path(B, "lab.json").read_text())["spent"] != 0:
    failures.append("leg did not reset the counter")
Path("harness/gate.sh").write_text("changed\n")
expect("leg parked on changed lock", run("leg", B, "--experiments", "4"), 1, "PARKED")

if failures:
    print("\n\n".join(failures)); sys.exit(1)
print("all lab.py cases pass")
PY
