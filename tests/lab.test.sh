#!/bin/sh
# lab-nt lab.py: sealed state, lockbox and fence (committed and uncommitted changes, ancestor fences),
# keep decisions under the joint gate, the surprise ledger (prediction before result, surprise with sign,
# kept ideas per proposer, state files written before the ledger), budget, child and fork carving, depth, legs and odometer
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
expect("init ok", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25", "--no-judge"), 0, "3 locked files")
expect("init twice refused", run("init", D, "--fence", "src/**", "--lock", "harness/**", "--experiments", "25"), 1, "initialised before")
expect("zero-match lock glob refused", run("init", "plan/lab/typo", "--fence", "src/**", "--lock", "harness/**", "harnes/*.py", "--experiments", "5"), 1, "match no file (typo?): harnes/*.py")

# the seal: a hand edit to any field is refused, including the budget counter
st = Path(D, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"higher_is_better": true', '"higher_is_better": false'))
expect("tampered direction refused", run("check", D), 1, "does not match its seal")
st.write_text(orig.replace('"spent": 0', '"spent": -100'))
expect("tampered budget refused", run("spend", D, "--n", "50"), 1, "does not match its seal")
st.write_text(orig)

# deleting the state file and re-initialising with a fresh budget is refused, twice over
R = "plan/lab/reinit"
run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "2")
Path(R, "lab.json").unlink()
expect("deleted state noticed", run("check", R), 1, "initialised before and its state file is gone")
expect("re-init refused", run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "99"), 1, "initialised before")
seal = lab.seal_path(R); seal.unlink()
expect("re-init refused by the ledger", run("init", R, "--fence", "src/**", "--lock", "harness/**", "--experiments", "99"), 1, "initialised before")

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
for e in ("g1", "g2", "g3", "g4", "g5", "g6", "g7", "g8", "ct1", "ct2"):
    run("predict", D, e, "--proposer", "claude-opus-5-5", "--predicted", "205")
expect("gate fail reverts", run("keep", D, "--id", "g1", "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "300"), 4, "REVERT: the gate failed")
expect("gain beats noise", run("keep", D, "--id", "g2", "--noise", "4", "--gate", "pass", "--base", "200", "202", "--cand", "210", "212"), 0, "KEEP")
expect("gain inside noise", run("keep", D, "--id", "g3", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "203"), 4, "REVERT")
expect("noise required", run("keep", D, "--id", "g4", "--gate", "pass", "--base", "200", "--cand", "203"), 2, "usage")
expect("paired gain", run("keep", D, "--id", "g5", "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2", "--paired-cand", "206", "206", "206", "206", "206", "206", "206", "206", "206", "206"), 0, "KEEP")
expect("paired mixed", run("keep", D, "--id", "g6", "--gate", "pass", "--paired", "1", "-2", "1.5", "-2.5", "1", "-2", "1", "-2", "1", "-2", "--paired-cand", "199", "199", "199", "199", "199", "199", "199", "199", "199", "199"), 4, "REVERT")
expect("paired too few", run("keep", D, "--id", "g7", "--gate", "pass", "--paired", "0.0001", "--paired-cand", "1"), 2, "at least 10")
expect("paired needs per-item scores", run("keep", D, "--id", "g7", "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2"), 2, "needs --paired-cand")
expect("paired scores must match the gains", run("keep", D, "--id", "g7", "--gate", "pass", "--paired", "1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2", "--paired-cand", "206", "206"), 2, "needs --paired-cand")
expect("negative noise refused", run("keep", D, "--id", "g8", "--noise", "-5", "--gate", "pass", "--base", "10", "--cand", "7"), 2, "cannot be negative")
# simple-fix control: a gain the plain fix also reaches reverts; a gain past the control keeps
expect("control explains the gain", run("keep", D, "--id", "ct1", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "220", "--control", "218"), 4, "simple-fix control reaches it")
expect("candidate beats the control", run("keep", D, "--id", "ct2", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "230", "--control", "210", "--confirm-base", "200", "201", "199", "--confirm", "229", "231", "230"), 0, "beats the simple-fix control by 20")

# gate failures already on the start commit: recorded once, never block a keep; a new failure still reverts
B = "plan/lab/base"
Path(B).mkdir(parents=True); Path(B, "contract.md").write_text("metric: decode\n")
run("init", B, "--fence", "src/**", "--lock", "harness/**", "--experiments", "6", "--no-judge")
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
run("init", L, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--lower-is-better", "--surprise", "0.5", "--no-judge")
run("predict", L, "l1", "--proposer", "x", "--predicted", "9"); run("predict", L, "l2", "--proposer", "x", "--predicted", "11.8")
expect("lower is better keep", run("keep", L, "--id", "l1", "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "8", "--confirm-base", "10", "10.1", "9.9", "--confirm", "8.2", "8.1", "8.3"), 0, "surprise -1 (|1|, better than predicted, HIGH)")
expect("lower is better revert", run("keep", L, "--id", "l2", "--noise", "1", "--gate", "pass", "--base", "10", "--cand", "12"), 4, "worse than predicted)")
expect("negative threshold refused", run("init", "plan/lab/neg", "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--surprise", "-1"), 1, "--surprise")

# per-proposer counts over the campaign and its children, threshold 2 (default would be 10%)
P = "plan/lab/prop"
run("init", P, "--fence", "src/**", "--lock", "harness/**", "--experiments", "10", "--surprise", "2", "--no-judge")
run("child", P, f"{P}/child-1", "--experiments", "3")
plan = [(P, "1", "qwen", 100, ["103"], "keep"),          # surprise +3, HIGH, kept
        (P, "2", "qwen", 100, ["99"], "revert"),         # -1
        (P, "3", "notes/sources/x.md", 100, ["108"], "keep"),  # +8, HIGH
        (f"{P}/child-1", "1", "qwen", 100, ["101"], "revert")]
for d_, e, who, pred, cand, _ in plan:
    run("predict", d_, e, "--proposer", who, "--predicted", str(pred))
    run("keep", d_, "--id", e, "--noise", "2", "--gate", "pass", "--base", "100", "--cand", *cand, "--confirm-base", "100", "100", "100", "--confirm", *(cand * 3))
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
del old["ideas"], old["surprise_threshold"], old["no_judge"], old["judged"], old["judge"]
lab.save(O, old)   # what lab.py 2.7.1 wrote
Path(O, "journal.md").write_text("# Lab journal\n\n- **A1 · hypothesis** · ran x · 210.0 · pass · keep · y\n")
expect("old state passes check", run("check", O), 0, "ok")
expect("old state summary", run("summary", O), 0, "no predictions recorded")
expect("old state spends", run("spend", O), 0, "1 of 4 used")
expect("old state still needs a prediction to keep", run("keep", O, "--id", "A2", "--noise", "1", "--gate", "pass", "--base", "1", "--cand", "5"), 1, "has no prediction")
expect("old state takes a prediction", run("predict", O, "A2", "--proposer", "x", "--predicted", "4"), 0, "ok")
expect("old state default threshold", run("keep", O, "--id", "A2", "--noise", "1", "--gate", "pass", "--base", "1", "--cand", "5", "--confirm-base", "1", "1", "1", "--confirm", "5", "5", "5"), 0, "surprise +1 (|1|, better than predicted, HIGH)")
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
if p["spent"] != 6 or c["locked"] != p["locked"] or c["depth"] != 1:
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

# an ancestor's state is read through its seal: widening the parent's fence by hand is refused
pj = Path(D, "lab.json"); before = pj.read_text()
pj.write_text(before.replace('"src/**"', '"**"', 1))
expect("tampered ancestor refused", run("check", f"{D}/child-1"), 1, "does not match its seal")
pj.write_text(before)

# keep runs check itself before any verdict: a change outside the fence or to a locked file reverts as fail
K = "plan/lab/keepcheck"
run("init", K, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--no-judge")
for e in ("x1", "x2", "x3"):
    run("predict", K, e, "--proposer", "x", "--predicted", "210")
Path("README.md").write_text("# outside the fence\n")
expect("keep reverts a change outside the fence", run("keep", K, "--id", "x1", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "210"), 4, "REVERT: lab.py check fails: change outside the fence: README.md")
subprocess.run(["git", "checkout", "-q", "README.md"], check=True)
Path("README.md").write_text("# committed outside the fence\n"); commit("outside again")
expect("keep reverts a committed change outside the fence", run("keep", K, "--id", "x3", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "210"), 4, "REVERT: lab.py check fails: change outside the fence: README.md")
subprocess.run(["git", "reset", "-q", "--hard", "HEAD~1"], check=True)
Path("harness/bench.py").write_text("print(3)\n")
expect("keep reverts an edit to a locked file", run("keep", K, "--id", "x2", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "210"), 4, "locked file changed: harness/bench.py")
subprocess.run(["git", "checkout", "-q", "harness/bench.py"], check=True)
ki = json.loads(Path(K, "lab.json").read_text())["ideas"]
if any(ki[e].get("outcome") != "fail" or "actual" in ki[e] for e in ("x1", "x2", "x3")):
    failures.append(f"a keep that failed check was not recorded as fail: {ki}")

# the judge: planted cases before experiment 1; predict refuses until it is sealed; no budget spent
J = "plan/lab/judge"
run("init", J, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5")
expect("predict before the judge refused", run("predict", J, "e1", "--proposer", "x", "--predicted", "1"), 1, "lab.py judge")
expect("judge done with no cases refused", run("judge", J, "--done"), 1, "at least 3")
expect("planted case predicted", run("predict", J, "noop", "--judge", "--proposer", "judge", "--predicted", "200"), 0, "ok")
expect("planted case through keep", run("keep", J, "--id", "noop", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "201"), 4, "REVERT")
expect("judge takes no typed-in verdict", run("judge", J, "--case", "noop", "--expect", "revert", "--got", "revert"), 2, "unrecognized arguments")
expect("judge case recorded", run("judge", J, "--case", "noop", "--expect", "revert"), 0, "ok: judge case noop got revert")
expect("judge case needs --expect", run("judge", J, "--case", "gain"), 2, "usage")
expect("judge case name repeated refused", run("judge", J, "--case", "noop", "--expect", "revert"), 1, "already recorded")
# a case names a planted experiment that has run: invented cases and cases not yet run are refused
expect("invented judge case refused", run("judge", J, "--case", "invented", "--expect", "keep"), 1, "not a planted experiment")
run("predict", J, "gain", "--judge", "--proposer", "judge", "--predicted", "210")
expect("judge case not yet run refused", run("judge", J, "--case", "gain", "--expect", "keep"), 1, "no recorded outcome yet")
run("keep", J, "--id", "gain", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "210")
expect("judge case 2 reads keep from the row", run("judge", J, "--case", "gain", "--expect", "keep"), 0, "got keep as expected; 2 recorded")
expect("judge done with 2 cases refused", run("judge", J, "--done"), 1, "at least 3 planted cases; 2 recorded")
expect("still no prediction before the seal", run("predict", J, "e1", "--proposer", "x", "--predicted", "1"), 1, "lab.py judge")
run("predict", J, "zeros", "--judge", "--proposer", "judge", "--predicted", "210")
run("keep", J, "--id", "zeros", "--noise", "4", "--gate", "fail", "--base", "200", "--cand", "210")
expect("judge case 3 reads fail from the row", run("judge", J, "--case", "zeros", "--expect", "fail"), 0, "got fail as expected; 3 recorded")
run("predict", J, "lockedit", "--judge", "--proposer", "judge", "--predicted", "210")
Path("harness/bench.py").write_text("print(4)\n")
run("keep", J, "--id", "lockedit", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "210")
subprocess.run(["git", "checkout", "-q", "harness/bench.py"], check=True)
run("judge", J, "--case", "lockedit", "--expect", "fail")
sj = json.loads(Path(J, "lab.json").read_text())
if sj["spent"] != 0 or sj["judged"] is not False or [c["name"] for c in sj["judge"]] != ["noop", "gain", "zeros", "lockedit"] or not all(c["match"] for c in sj["judge"]):
    failures.append(f"judge state wrong before the seal: {sj}")
st = Path(J, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"judged": false', '"judged": true'))
expect("hand-set judged refused by the seal", run("predict", J, "e1", "--proposer", "x", "--predicted", "1"), 1, "does not match its seal")
st.write_text(orig)
expect("judge sealed", run("judge", J, "--done"), 0, "judge sealed, 4 of 4")
expect("predict after the seal", run("predict", J, "e1", "--proposer", "x", "--predicted", "1"), 0, "ok")
expect("planted case after the seal refused", run("predict", J, "late", "--judge", "--proposer", "x", "--predicted", "1"), 1, "sealed")
expect("judge case after the seal refused", run("judge", J, "--case", "late", "--expect", "keep"), 1, "already sealed")
expect("summary leaves planted cases out", run("summary", J), 0, "1 predicted, 0 with a result")
if json.loads(Path(J, "lab.json").read_text())["spent"] != 0:
    failures.append("the judge spent experiment budget")
expect("child of a judged campaign", run("child", J, f"{J}/c1", "--experiments", "1"), 0, "ok")
expect("child inherits the judge", run("predict", f"{J}/c1", "e1", "--proposer", "x", "--predicted", "1"), 0, "ok")
expect("child runs no judge", run("judge", f"{J}/c1", "--case", "a", "--expect", "keep"), 1, "inherits its parent's judge")
expect("fork inherits the judge", run("fork", J, f"{J}/f1", "--experiments", "1"), 0, "ok")
expect("fork predicts", run("predict", f"{J}/f1", "e1", "--proposer", "x", "--predicted", "1"), 0, "ok")
# a mismatch between the expected verdict and the planted run's recorded outcome parks the campaign
J2 = "plan/lab/judge2"
run("init", J2, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5")
run("predict", J2, "noop", "--judge", "--proposer", "judge", "--predicted", "200")
run("keep", J2, "--id", "noop", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "201")
run("judge", J2, "--case", "noop", "--expect", "revert")
run("predict", J2, "gain", "--judge", "--proposer", "judge", "--predicted", "200")
run("keep", J2, "--id", "gain", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "201")
expect("judge mismatch parks", run("judge", J2, "--case", "gain", "--expect", "keep"), 5, "PARKED: the judge returned revert for gain, expected keep; fix the harness or the gates, never the loop")
expect("judge done with a mismatch parks", run("judge", J2, "--done"), 5, "PARKED: the judge returned revert for gain")
expect("parked judge still blocks predict", run("predict", J2, "e1", "--proposer", "x", "--predicted", "1"), 1, "lab.py judge")
expect("child of an unjudged campaign", run("child", J2, f"{J2}/c1", "--experiments", "1"), 0, "ok")
expect("child of an unjudged campaign cannot predict", run("predict", f"{J2}/c1", "e1", "--proposer", "x", "--predicted", "1"), 1, "lab.py judge")
# the seal needs keep, revert and fail each got at least once, even with 3 matching cases
J3 = "plan/lab/judge3"
run("init", J3, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5")
for e, gate in (("n1", "pass"), ("n2", "pass"), ("z1", "fail")):
    run("predict", J3, e, "--judge", "--proposer", "judge", "--predicted", "200")
    run("keep", J3, "--id", e, "--noise", "4", "--gate", gate, "--base", "200", "--cand", "201")
    run("judge", J3, "--case", e, "--expect", "fail" if gate == "fail" else "revert")
expect("judge done without a keep case refused", run("judge", J3, "--done"), 1, "cover every verdict (keep, revert, fail); none got keep")
# --no-judge is stored and sealed; such a campaign predicts at once and runs no judge
N = "plan/lab/nojudge"
run("init", N, "--fence", "src/**", "--lock", "harness/**", "--experiments", "5", "--no-judge")
if json.loads(Path(N, "lab.json").read_text()).get("no_judge") is not True:
    failures.append("--no-judge not stored")
expect("no-judge campaign predicts", run("predict", N, "e1", "--proposer", "x", "--predicted", "1"), 0, "ok")
expect("no-judge campaign runs no judge", run("judge", N, "--case", "a", "--expect", "keep"), 1, "--no-judge")
st = Path(N, "lab.json"); orig = st.read_text()
st.write_text(orig.replace('"no_judge": true', '"no_judge": false'))
expect("hand-cleared no_judge refused by the seal", run("check", N), 1, "does not match its seal")
st.write_text(orig)
# a state file written before the judge existed (no judged key) counts as judged, and so do its children
Q = "plan/lab/prejudge"
run("init", Q, "--fence", "src/**", "--lock", "harness/**", "--experiments", "6")
old = json.loads(Path(Q, "lab.json").read_text())
del old["no_judge"], old["judged"], old["judge"]
lab.save(Q, old)   # what lab.py wrote before the judge
expect("pre-judge state passes check", run("check", Q), 0, "ok")
expect("pre-judge state predicts", run("predict", Q, "e1", "--proposer", "x", "--predicted", "205"), 0, "ok")
expect("pre-judge state keeps", run("keep", Q, "--id", "e1", "--noise", "4", "--gate", "pass", "--base", "200", "--cand", "205"), 0, "KEEP")
expect("pre-judge child", run("child", Q, f"{Q}/c1", "--experiments", "1"), 0, "ok")
expect("pre-judge child predicts", run("predict", f"{Q}/c1", "e1", "--proposer", "x", "--predicted", "1"), 0, "ok")

# a HIGH-surprise KEEP needs fresh confirmation runs; it keeps only if the gain holds on them
H = "plan/lab/high"
run("init", H, "--fence", "src/**", "--lock", "harness/**", "--experiments", "10", "--surprise", "2", "--no-judge")
for e, pred in (("h1", 100), ("h2", 100), ("h3", 105), ("h4", 100), ("h5", 100), ("h6", 100), ("h7", 100), ("h8", 100), ("h9", 100)):
    run("predict", H, e, "--proposer", "x", "--predicted", str(pred))
expect("HIGH keep without --confirm refused", run("keep", H, "--id", "h1", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110"), 1, "needs --confirm")
if "outcome" in json.loads(Path(H, "lab.json").read_text())["ideas"]["h1"]:
    failures.append("a refused HIGH keep recorded a result")
expect("HIGH gain gone on fresh runs", run("keep", H, "--id", "h1", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm-base", "100", "100", "100", "--confirm", "101", "101.5", "101.25"), 4, "REVERT: the HIGH-surprise gain did not hold on fresh runs (1.25 against noise 2)")
expect("HIGH gain holds on fresh runs", run("keep", H, "--id", "h2", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm-base", "100", "100", "100", "--confirm", "109", "111", "110"), 0, "held on fresh runs (10 against noise 2)")
expect("non-HIGH keep needs no confirm", run("keep", H, "--id", "h3", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "105"), 0, "KEEP")
expect("HIGH revert needs no confirm", run("keep", H, "--id", "h4", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "90"), 4, "REVERT: gain -10")
good = ["1", "2", "1.5", "2.5", "1", "2", "3", "1.2", "1.1", "2.2"]
mixed = ["1", "-2", "1.5", "-2.5", "1", "-2", "1", "-2", "1", "-2"]
expect("HIGH paired keep without --confirm-paired refused", run("keep", H, "--id", "h5", "--gate", "pass", "--paired", *good, "--paired-cand", *["110"] * 10), 1, "needs --confirm-paired")
expect("HIGH paired confirm too short", run("keep", H, "--id", "h5", "--gate", "pass", "--paired", *good, "--paired-cand", *["110"] * 10, "--confirm-paired", "1", "2"), 2, "at least 10")
expect("HIGH paired gain gone on fresh runs", run("keep", H, "--id", "h5", "--gate", "pass", "--paired", *good, "--paired-cand", *["110"] * 10, "--confirm-paired", *mixed), 4, "REVERT: the HIGH-surprise gain did not hold on fresh runs (paired 95% interval")
expect("HIGH paired gain holds", run("keep", H, "--id", "h6", "--gate", "pass", "--paired", *good, "--paired-cand", *["110"] * 10, "--confirm-paired", *good), 0, "held on fresh runs (paired 95% interval")
# --actual cannot replace mean(--cand), so a HIGH surprise cannot be hidden behind a typed-in number
# paired mode reads its metric from the per-item scores, so a typed-in --actual cannot hide a HIGH surprise
expect("paired --actual refused", run("keep", H, "--id", "h7", "--gate", "pass", "--paired", *good, "--paired-cand", *["110"] * 10, "--actual", "100"), 2, "drop --actual")
if "outcome" in json.loads(Path(H, "lab.json").read_text())["ideas"]["h7"]:
    failures.append("a refused paired keep with --actual recorded a result")
# NaN makes every comparison false, so a NaN reading would skip the HIGH-surprise check
expect("paired NaN score refused", run("keep", H, "--id", "h7", "--gate", "pass", "--paired", *good, "--paired-cand", "nan", *["110"] * 9), 1, "finite numbers only")
expect("NaN candidate reading refused", run("keep", H, "--id", "h7", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "nan", "110"), 1, "finite numbers only")
if "outcome" in json.loads(Path(H, "lab.json").read_text())["ideas"]["h7"]:
    failures.append("a refused NaN keep recorded a result")
expect("--actual with --cand refused", run("keep", H, "--id", "h7", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--actual", "100"), 2, "drop --actual")
# the confirmation re-measures both sides: a drift that lifts best-so-far as much as the candidate is no gain
expect("HIGH gain is drift on fresh runs of both sides", run("keep", H, "--id", "h8", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm-base", "110", "110", "110", "--confirm", "110", "110", "110"), 4, "did not hold on fresh runs (0 against noise 2)")
expect("HIGH confirm needs fresh best-so-far readings", run("keep", H, "--id", "h9", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm", "109", "111", "110"), 1, "needs --confirm-base and --confirm")
expect("HIGH confirm needs 3 readings a side", run("keep", H, "--id", "h9", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm-base", "100", "100", "100", "--confirm", "110"), 2, "at least 3 readings each")
expect("HIGH confirm readings alternate", run("keep", H, "--id", "h9", "--noise", "2", "--gate", "pass", "--base", "100", "--cand", "110", "--confirm-base", "100", "100", "100", "--confirm", "110", "110", "110", "110", "110"), 2, "taken alternately")
hi_ = json.loads(Path(H, "lab.json").read_text())["ideas"]
if [hi_[e].get("outcome") for e in ("h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9")] != ["revert", "keep", "keep", "revert", "revert", "keep", None, "revert", None] or hi_["h1"]["actual"] != 110:
    failures.append(f"HIGH-surprise outcomes wrong: {hi_}")

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
