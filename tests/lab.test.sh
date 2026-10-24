#!/bin/sh
# lab-nt lab.py: sealed state, lockbox and fence (committed and uncommitted changes, ancestor fences),
# keep decisions under the joint gate, the surprise ledger (prediction before result, surprise with sign,
# kept ideas per proposer, state files written before the ledger), budget, child and fork carving, depth, legs and odometer, merge
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
cases = 0

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
    global cases
    cases += 1
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
expect("init with no lock", run("init", D, "--fence", "src/**", "--experiments", "25"), 1, "lockbox is empty")
expect("init with an empty lock glob", run("init", D, "--fence", "src/**", "--lock", "nothing/**", "--experiments", "25"), 1, "match no file")
expect("lock inside fence", run("init", D, "--fence", "src/**", "harness/**", "--lock", "harness/**", "--experiments", "25"), 1, "inside the fence")
expect("init ok", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 0, "3 locked files")
expect("init twice refused", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 1, "initialised before")
expect("zero-match lock glob refused", run("init", "plan/lab/typo", "--fence", "src/**", "--lock", "harness/**", "harnes/*.py", "--experiments", "5"), 1, "match no file (typo?): harnes/*.py")

# the seal: a hand edit to any field is refused, including the budget counter
st = Path(D, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"merge": "none"', '"merge": "auto"'))
expect("tampered grant refused", run("check", D), 1, "does not match its seal")
st.write_text(orig.replace('"spent": 0', '"spent": -100'))
expect("tampered budget refused", run("spend", D, "--n", "50"), 1, "does not match its seal")
st.write_text(orig)

# deleting the state file and re-initialising with a merge grant is refused, twice over
R = "plan/lab/reinit"
run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "2")
Path(R, "lab.json").unlink()
expect("deleted state noticed", run("check", R), 1, "initialised before and its state file is gone")
expect("re-init refused", run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "99", "--merge", "auto"), 1, "initialised before")
seal = lab.seal_path(R); seal.unlink()
expect("re-init refused by the ledger", run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "99", "--merge", "auto"), 1, "initialised before")

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
# a file hidden through .git/info/exclude is still seen
Path("outside.txt").write_text("x\n")
with open(".git/info/exclude", "a") as f: f.write("outside.txt\n")
expect("info/exclude does not hide a change", run("check", D), 1, "outside the fence: outside.txt")
Path("outside.txt").unlink()
# a rename from outside the fence into it shows both paths
subprocess.run(["git", "mv", "README.md", "src/README.md"], check=True)
expect("rename into fence refused", run("check", D), 1, "outside the fence: README.md")
subprocess.run(["git", "mv", "src/README.md", "README.md"], check=True)
# a changed contract is refused
C = "plan/lab/con"
Path(C).mkdir(parents=True); Path(C, "contract.md").write_text("metric: decode\n")
run("init", C, "--fence", "src/**", "--lock", "harness/**", "--experiments", "3")
Path(C, "contract.md").write_text("metric: something easier\n")
expect("contract change refused", run("check", C), 1, "contract changed")

# noise
expect("noise needs 3", run("noise", "1", "2"), 1, "at least 3")
expect("noise spread", run("noise", "210", "214", "212"), 0, "noise 4 mean 212")

# keep under the joint gate: KEEP exit 0, REVERT exit 4; every keep names a predicted experiment
for e in ("g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8"):
    run("predict", D, e, "--proposer", "claude-opus-5-5", "--predicted", "205")
expect("gate fail reverts", run("keep", D, "--id", "g1", "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "300"), 4, "REVERT: the gate failed")
expect("gain beats noise", run("keep", D, "--id", "g2", "--noise", "4", "--gate", "pass", "--base", "200", "202", "--cand", "210", "212"), 0, "KEEP")
expect("gain inside noise", run("keep", D, "--id", "g3", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "203"), 4, "REVERT")
expect("noise required", run("keep", D, "--id", "g4", "--gate", "pass", "--base", "200", "--cand", "203"), 2, "usage")
expect("paired gain", run("keep", D, "--id", "g5", "--gate", "pass", "--actual", "206", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2"), 0, "KEEP")
expect("paired mixed", run("keep", D, "--id", "g6", "--gate", "pass", "--actual", "199", "--paired", "1", "-2", "1.5", "-2.5", "1", "-2", "1", "-2", "1", "-2"), 4, "REVERT")
expect("paired too few", run("keep", D, "--id", "g7", "--gate", "pass", "--actual", "1", "--paired", "0.0001"), 2, "at least 10")
expect("paired needs actual", run("keep", D, "--id", "g7", "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2"), 2, "needs --actual")
expect("negative noise refused", run("keep", D, "--id", "g8", "--noise", "-5", "--gate", "pass", "--base", "10", "--cand", "7"), 2, "cannot be negative")

# gate failures already on the start commit: recorded once, never block a keep; a new failure still reverts
B = "plan/lab/base"
Path(B).mkdir(parents=True); Path(B, "contract.md").write_text("metric: decode\n")
run("init", B, "--fence", "src/**", "--lock", "harness/**", "--experiments", "6")
for e in ("k1", "k2", "k3", "k4"):
    run("predict", B, e, "--proposer", "claude-opus-5-5", "--predicted", "205")
expect("known gate needs a baseline", run("keep", B, "--id", "k1", "--noise", "4", "--gate", "known", "--failures", "olmoe/p4", "--base", "200", "--cand", "210"), 1, "no baseline recorded")
expect("baseline records start failures", run("baseline", B, "--failures", "olmoe/p4", "olmoe/p4"), 0, "1 start-commit gate failure")
expect("known failure does not block", run("keep", B, "--id", "k1", "--noise", "4", "--gate", "known", "--failures", "olmoe/p4", "--base", "200", "--cand", "210"), 0, "KEEP")
expect("new failure reverts", run("keep", B, "--id", "k2", "--noise", "4", "--gate", "known", "--failures", "olmoe/p4", "qwen/p1", "--base", "200", "--cand", "210"), 4, "not on the start commit: qwen/p1")
expect("known gate needs failures", run("keep", B, "--id", "k3", "--noise", "4", "--gate", "known", "--base", "200", "--cand", "210"), 2, "needs --failures")
expect("clean baseline", run("baseline", B), 0, "clean baseline")
expect("known against clean baseline reverts", run("keep", B, "--id", "k3", "--noise", "4", "--gate", "known", "--failures", "olmoe/p4", "--base", "200", "--cand", "210"), 4, "not on the start commit")

# surprise ledger: no prediction, no result; a prediction is written once; a result is written once
expect("keep without prediction refused", run("keep", D, "--id", "nope", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "300"), 1, "has no prediction")
expect("gate fail without prediction refused", run("keep", D, "--id", "nope", "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "300"), 1, "has no prediction")
expect("record without prediction refused", run("record", D, "nope", "--outcome", "fail"), 1, "has no prediction")
expect("keep needs an id", run("keep", D, "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "300"), 2, "--id")
expect("prediction rewrite refused", run("predict", D, "g2", "--proposer", "x", "--predicted", "211"), 1, "already has a prediction")
expect("result rewrite refused", run("keep", D, "--id", "g2", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "300"), 1, "already has a result")
expect("empty proposer refused", run("predict", D, "g9", "--proposer", " ", "--predicted", "1"), 1, "cannot be empty")
expect("nan prediction refused", run("predict", D, "g9", "--proposer", "x", "--predicted", "nan"), 1, "finite")
# surprise = actual - predicted with the sign kept: mean(210, 212) = 211 against 205 is +6
ideas = json.loads(Path(D, "lab.json").read_text())["ideas"]
if ideas["g2"]["actual"] != 211 or ideas["g2"]["surprise"] != 6 or ideas["g2"]["outcome"] != "keep":
    failures.append(f"surprise for g2 wrong: {ideas['g2']}")
if ideas["g3"]["surprise"] != -2 or ideas["g3"]["outcome"] != "revert":
    failures.append(f"surprise for g3 wrong: {ideas['g3']}")
if ideas["g1"]["outcome"] != "fail" or "actual" in ideas["g1"]:
    failures.append(f"a failed gate recorded a metric: {ideas['g1']}")
if "outcome" in ideas["g4"] or "outcome" in ideas["g7"] or "outcome" in ideas["g8"]:
    failures.append("a usage error recorded a result")
run("predict", D, "s1", "--proposer", "x", "--predicted", "100")
expect("negative surprise printed with sign", run("record", D, "s1", "--outcome", "revert", "--actual", "70"), 0, "surprise -30 (|30|, worse than predicted, HIGH)")
run("predict", D, "s2", "--proposer", "x", "--predicted", "100")
expect("revert record needs a number", run("record", D, "s2", "--outcome", "revert"), 2, "needs --actual")
expect("fail record without a number", run("record", D, "s2", "--outcome", "fail"), 0, "no surprise recorded")
expect("record twice refused", run("record", D, "s2", "--outcome", "fail"), 1, "already has a result")
st = Path(D, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"predicted": 100.0', '"predicted": 71.0', 1))
expect("edited prediction refused by the seal", run("summary", D), 1, "does not match its seal")
st.write_text(orig)

# lower is better flips the sign of the gain and of "better than predicted"; --surprise sets the threshold
L = "plan/lab/lat"
run("init", L, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--lower-is-better", "--surprise", "0.5")
run("predict", L, "l1", "--proposer", "x", "--predicted", "9"); run("predict", L, "l2", "--proposer", "x", "--predicted", "11.8")
expect("lower is better keep", run("keep", L, "--id", "l1", "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "8"), 0, "surprise -1 (|1|, better than predicted, HIGH)")
expect("lower is better revert", run("keep", L, "--id", "l2", "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "12"), 4, "worse than predicted)")
expect("negative threshold refused", run("init", "plan/lab/neg", "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--surprise", "-1"), 1, "--surprise")

# per-proposer counts over the campaign and its children, threshold 2 (default would be 10%)
P = "plan/lab/prop"
run("init", P, "--fence", "src/**", "--lock", "harness/**", "--experiments", "10", "--surprise", "2")
run("child", P, f"{P}/child-1", "--experiments", "3")
plan = [(P, "1", "qwen", 100, ["103"], "keep"),          # surprise +3, HIGH, kept
        (P, "2", "qwen", 100, ["99"], "revert"),         # -1
        (P, "3", "notes/sources/x.md", 100, ["108"], "keep"),  # +8, HIGH
        (f"{P}/child-1", "1", "qwen", 100, ["101"], "revert")]
for d_, e, who, pred, cand, _ in plan:
    run("predict", d_, e, "--proposer", who, "--predicted", str(pred))
    run("keep", d_, "--id", e, "--noise", "2", "--gate", "pass", "--base", "100", "--cand", *cand)
run("predict", P, "4", "--proposer", "glm", "--predicted", "100")
run("record", P, "4", "--outcome", "fail")
run("predict", P, "5", "--proposer", "glm", "--predicted", "100")
got = run("summary", P)
for want in ("6 predicted, 5 with a result, 4 measured",
             "surprise rate: 2 of 4 measured (50%) with |surprise| > 2",
             "  qwen · 3 · 3 · 1 · 1", "  notes/sources/x.md · 1 · 1 · 1 · 1", "  glm · 2 · 0 · 0 · 0",
             "child-1/1 · qwen · predicted 100 · actual 101", "5 · glm · predicted 100 · no metric that counts · pending"):
    expect(f"summary shows {want!r}", got, 0, want)
expect("summary for one leg", run("summary", P, "--leg", "2"), 0, "no predictions recorded")

# a state file and journal written before the surprise ledger still load, check and summarise
O = "plan/lab/old"
Path(O).mkdir(parents=True); Path(O, "contract.md").write_text("old contract\n")
run("init", O, "--fence", "src/**", "--lock", "harness/**", "--experiments", "4")
old = json.loads(Path(O, "lab.json").read_text())
del old["ideas"], old["surprise_threshold"]
lab.save(O, old)   # what lab.py 2.7.1 wrote
Path(O, "journal.md").write_text("# Lab journal\n\n- **A1 · hypothesis** · ran x · 210.0 · pass · keep · y\n")
expect("old state passes check", run("check", O), 0, "ok")
expect("old state summary", run("summary", O), 0, "no predictions recorded")
expect("old state spends", run("spend", O), 0, "1 of 4 used")
expect("old state still needs a prediction to keep", run("keep", O, "--id", "A2", "--noise", "1", "--gate", "pass", "--base", "1", "--cand", "5"), 1, "has no prediction")
expect("old state takes a prediction", run("predict", O, "A2", "--proposer", "x", "--predicted", "4"), 0, "ok")
expect("old state default threshold", run("keep", O, "--id", "A2", "--noise", "1", "--gate", "pass", "--base", "1", "--cand", "5"), 0, "surprise +1 (|1|, better than predicted, HIGH)")
expect("old state check after the ledger", run("check", O), 0, "ok")

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
expect("leg without an end refused", run("leg", B, "--experiments", "4"), 1, "no recorded end")
run("end", B, "BUDGET")
expect("odometer exhausted", run("leg", B, "--experiments", "4"), 1, "RETIRED")
run("end", D, "BUDGET")
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

# an ancestor's state is read through its seal: widening the parent's fence by hand is refused
pj = Path(D, "lab.json"); before = pj.read_text()
pj.write_text(before.replace('"src/**"', '"**"', 1))
expect("tampered ancestor refused", run("check", f"{D}/child-1"), 1, "does not match its seal")
pj.write_text(before)
# every call left a ledger row
rows = (lab.seal_dir() / "ledger.jsonl").read_text().splitlines()
if not any('"event": "init"' in r for r in rows) or not any('"event": "child"' in r for r in rows):
    failures.append("ledger missing init or child rows")
if not any('"event": "predict"' in r for r in rows) or not any('"event": "result"' in r for r in rows):
    failures.append("ledger missing predict or result rows")

if failures:
    print("\n\n".join(failures)); sys.exit(1)
print(f"all {cases} lab.py cases pass")
PY
