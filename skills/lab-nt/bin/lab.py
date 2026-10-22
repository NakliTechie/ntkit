#!/usr/bin/env python3
"""Deterministic rules for /lab-nt. Standard library only. Run from the root of the campaign's worktree.

The campaign state lives in <dir>/lab.json (<dir> is plan/lab/<slug>, or a child or fork under it). Every save
seals the whole state: its digest goes outside plan/, into the repo's git directory (lab-seals/), and every call
refuses a state file that no longer matches. Each init, child, fork, leg, end and merge check is also appended to
lab-seals/ledger.jsonl, and a directory that was ever initialised cannot be initialised again.

What the seal is: tamper evidence. It catches a hand edit to lab.json, a deleted state file, and a re-init that
would reset the budget or add a merge grant. It does not stop an agent that deliberately rewrites the seal, the
ledger and this script; that would break the skill's stop-lines, and the ledger and git history show it.

  kind, depth, max_depth, parent  "campaign" | "child" | "fork"; a child is one level deeper, a fork the same depth
  fence                           globs the loop may change; every changed path must match one at every ancestor
  lock_globs, locked              globs the loop may never change, with the sha256 of each file found at init
  start                           the commit the current leg began from; `check` diffs against it by default
  experiments, spent, children    this leg's budget, what is used, and the children and forks carved from it
  legs, max_legs, ended           leg odometer and how the last leg ended
  contract_sha                    sha256 of contract.md when the leg began; `check` refuses a changed contract
  higher_is_better, merge         metric direction; "none" or "auto" (the user's per-campaign merge grant)

Globs: `*` and `?` stay inside one path segment, `**` spans any number of segments (including none), and hidden
files match like any other. The same matcher expands lock globs and tests changed paths; symlinks are not followed
below a glob's literal base. Untracked files count as changes unless a committed .gitignore covers them (entries in
.git/info/exclude or a global excludes file do not hide a file from `check`); lock what the measurement imports
from ignored paths, such as a virtualenv, by glob.

Subcommands and exit codes (0 ok; 1 refused or violated; 2 usage; 3 budget; 4 REVERT):
  init  <dir> --fence G.. --lock G.. --experiments N [--max-depth 2] [--max-legs 5] [--lower-is-better] [--merge auto]
                             every lock glob must match a file; refuses a directory initialised before
  check <dir> [--base REF]   seal intact; locked files unchanged and none added; contract.md unchanged; every
                             change since --base (default: the leg's start) inside the fence of every ancestor
  noise <v> <v> <v>..        spread (max - min) and mean of re-measures of the unchanged baseline
  keep  <dir> --gate pass|fail (--noise X --base v.. --cand v.. | --paired d..)
                             exit 0 KEEP when the gate passed and the gain beats the noise (X >= 0), or the paired
                             95% bootstrap interval over at least 10 items excludes zero; exit 4 REVERT otherwise
  spend <dir> [--n 1]        book n experiments before running them; exit 3 (nothing booked) when they do not fit
  child <dir> <child-dir> --experiments N [--fence G..]   one level deeper, at most half the parent's remainder,
                             fence contained in the parent's (equal, or under a parent glob ending in **)
  fork  <dir> <fork-dir> --experiments N                  same depth and fence, budget carved from the parent
  forks <dir> [--k 3]        fork-and-flush schedule: the experiment numbers to fork at, per-fork budget
  end   <dir> <STATE>        record how the leg ended (GOAL-MET BUDGET STAGNANT DRY-WELL PARKED)
  leg   <dir> --experiments N  start a resumed leg of a top-level campaign: refuses children and forks, a leg with
                             no recorded end, an exhausted odometer, a changed lock, and a STAGNANT or DRY-WELL end
                             with contract.md unchanged
  merge-ok <dir>             exit 0 only for a sealed top-level campaign holding the user's merge: auto grant, with
                             exactly one init in the ledger
"""
import argparse, hashlib, json, os, random, re, subprocess, sys, time
from pathlib import Path

STATE = "lab.json"
ENDS = ["GOAL-MET", "BUDGET", "STAGNANT", "DRY-WELL", "PARKED"]
SKIP_DIRS = {".git", ".worktrees", ".build", "node_modules", "__pycache__"}


def git(*a):
    r = subprocess.run(["git", "-c", "core.quotePath=false", *a], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"git {' '.join(a)}: {r.stderr.strip()}")
    return r.stdout.strip()


def sha_file(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def glob_re(g):
    out, i = "", 0
    while i < len(g):
        if g.startswith("**/", i):
            out += "(?:.*/)?"; i += 3
        elif g.startswith("**", i):
            out += ".*"; i += 2
        elif g[i] == "*":
            out += "[^/]*"; i += 1
        elif g[i] == "?":
            out += "[^/]"; i += 1
        else:
            out += re.escape(g[i]); i += 1
    return re.compile(out + r"\Z")


def matches(path, globs):
    return any(glob_re(g).match(path) for g in globs)


def skipped(path):
    parts = path.split("/")
    return any(p in SKIP_DIRS for p in parts[:-1]) or parts[-1] == ".DS_Store"


def expand(globs, each=False):
    found, per = set(), {}
    for g in globs:
        lit = []
        for p in g.split("/"):
            if any(c in p for c in "*?"):
                break
            lit.append(p)
        base = Path(*lit) if lit else Path(".")
        hits = set()
        if base.is_file():
            if matches(base.as_posix(), [g]):
                hits.add(base.as_posix())
        else:
            for root, dirs, files in os.walk(base):
                dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
                for f in files:
                    rel = (Path(root) / f).as_posix().removeprefix("./")
                    if matches(rel, [g]):
                        hits.add(rel)
        per[g] = hits
        found |= hits
    return (sorted(found), per) if each else sorted(found)


def seal_dir():
    return Path(git("rev-parse", "--git-common-dir")).resolve() / "lab-seals"


def seal_path(d):
    key = hashlib.sha256(Path(d).resolve().as_posix().encode()).hexdigest()[:24]
    return seal_dir() / f"{key}.json"


def digest(s):
    return hashlib.sha256(json.dumps(s, sort_keys=True).encode()).hexdigest()


def ledger(event, d, **extra):
    p = seal_dir() / "ledger.jsonl"
    p.parent.mkdir(parents=True, exist_ok=True)
    row = {"t": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "event": event, "dir": str(Path(d).resolve()),
           "head": git("rev-parse", "HEAD"), **extra}
    with p.open("a") as f:
        f.write(json.dumps(row, sort_keys=True) + "\n")


def inits(d):
    p = seal_dir() / "ledger.jsonl"
    if not p.is_file():
        return 0
    target = str(Path(d).resolve())
    return sum(1 for line in p.read_text().splitlines()
               if line.strip() and json.loads(line).get("event") == "init" and json.loads(line).get("dir") == target)


def load(d):
    p = Path(d) / STATE
    if not p.is_file():
        print(f"refused: no {STATE} in {d}" + ("; it was initialised before and its state file is gone"
                                                if seal_path(d).is_file() else "; run `lab.py init` first"))
        raise SystemExit(1)
    s = json.loads(p.read_text())
    sp = seal_path(d)
    if not sp.is_file() or json.loads(sp.read_text()).get("digest") != digest(s):
        print(f"refused: {d}/{STATE} does not match its seal (edited by hand?)")
        raise SystemExit(1)
    return s


def write_atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text)
    os.replace(tmp, path)


def save(d, s):
    write_atomic(Path(d) / STATE, json.dumps(s, indent=2, sort_keys=True) + "\n")
    write_atomic(seal_path(d), json.dumps({"dir": str(Path(d).resolve()), "digest": digest(s)}) + "\n")


def contract_sha(d):
    p = Path(d) / "contract.md"
    return sha_file(p) if p.is_file() else None


def ancestors(d, s):
    chain = [s]
    while chain[-1].get("parent"):
        chain.append(load(chain[-1]["parent"]))
    return chain


def contained(child_glob, parent_globs):
    for p in parent_globs:
        if child_glob == p:
            return True
        if p.endswith("**") and child_glob.startswith(p[:-2]):
            return True
    return False


def cmd_init(a):
    if (Path(a.dir) / STATE).exists() or seal_path(a.dir).is_file() or inits(a.dir):
        print(f"refused: {a.dir} was initialised before; resume it with `lab.py leg`"); return 1
    if not a.fence:
        print("refused: a campaign needs a fence (--fence)"); return 1
    files, per = expand(a.lock, each=True)
    if not a.lock:
        print("refused: the lockbox is empty; --lock must match the harness, metric and gate files"); return 1
    empty = [g for g, hits in per.items() if not hits]
    if empty:
        print("refused: lock globs match no file (typo?): " + ", ".join(empty)); return 1
    overlap = [f for f in files if matches(f, a.fence)]
    if overlap:
        print("refused: locked files sit inside the fence: " + ", ".join(overlap)); return 1
    if a.experiments < 1:
        print("refused: --experiments must be at least 1"); return 1
    s = {"kind": "campaign", "depth": 0, "max_depth": a.max_depth, "parent": None, "fence": a.fence,
         "lock_globs": a.lock, "locked": {f: sha_file(f) for f in files}, "experiments": a.experiments,
         "spent": 0, "children": [], "legs": 1, "max_legs": a.max_legs, "ended": None,
         "start": git("rev-parse", "HEAD"), "contract_sha": contract_sha(a.dir),
         "higher_is_better": not a.lower_is_better, "merge": a.merge}
    save(a.dir, s)
    ledger("init", a.dir, merge=a.merge, experiments=a.experiments)
    print(f"ok: {len(files)} locked files, fence {a.fence}, {a.experiments} experiments, max depth {a.max_depth}")
    return 0


def cmd_check(a):
    s = load(a.dir)
    problems = []
    for f, h in s["locked"].items():
        if not Path(f).is_file():
            problems.append(f"locked file missing: {f}")
        elif sha_file(f) != h:
            problems.append(f"locked file changed: {f}")
    for f in expand(s["lock_globs"]):
        if f not in s["locked"]:
            problems.append(f"new file in a locked path: {f}")
    if contract_sha(a.dir) != s.get("contract_sha"):
        problems.append(f"contract changed: {a.dir}/contract.md")
    base = a.base or s["start"]
    changed = set(git("diff", "--no-renames", "--name-only", base).splitlines())
    changed |= set(git("ls-files", "--others", "--exclude-per-directory=.gitignore").splitlines())
    fences = [x["fence"] for x in ancestors(a.dir, s)]
    for p in sorted(c for c in changed if c and not c.startswith("plan/") and not skipped(c)):
        if p in s["locked"] or matches(p, s["lock_globs"]):
            problems.append(f"change touches a locked path: {p}")
        elif not all(matches(p, f) for f in fences):
            problems.append(f"change outside the fence: {p}")
    if problems:
        print("\n".join(sorted(set(problems)))); return 1
    print(f"ok: seal, lockbox and contract intact, every change since {base[:12]} inside the fence"); return 0


def mean(v):
    return sum(v) / len(v)


def cmd_noise(a):
    if len(a.values) < 3:
        print("refused: measure the unchanged baseline at least 3 times"); return 1
    print(f"noise {max(a.values) - min(a.values):.6g} mean {mean(a.values):.6g} n {len(a.values)}"); return 0


def cmd_keep(a):
    s = load(a.dir)
    sign = 1 if s["higher_is_better"] else -1
    if a.gate != "pass":
        print("REVERT: the gate failed for this commit, so its metric does not count"); return 4
    if a.paired:
        if len(a.paired) < 10:
            print("usage: a paired decision needs at least 10 items"); return 2
        rng = random.Random(0)
        d = [sign * x for x in a.paired]
        means = sorted(mean([rng.choice(d) for _ in d]) for _ in range(2000))
        lo, hi = means[49], means[1949]
        if lo > 0:
            print(f"KEEP: paired gain 95% interval [{lo:.6g}, {hi:.6g}] over {len(d)} items"); return 0
        print(f"REVERT: paired gain 95% interval [{lo:.6g}, {hi:.6g}] over {len(d)} items"); return 4
    if not a.base or not a.cand or a.noise is None:
        print("usage: keep needs --noise, --base and --cand, or --paired"); return 2
    if a.noise < 0:
        print("usage: --noise is a spread and cannot be negative"); return 2
    gain = sign * (mean(a.cand) - mean(a.base))
    if gain > a.noise:
        print(f"KEEP: gain {gain:.6g} against noise {a.noise:.6g}"); return 0
    print(f"REVERT: gain {gain:.6g} against noise {a.noise:.6g}"); return 4


def cmd_spend(a):
    s = load(a.dir)
    if a.n < 1:
        print("refused: --n must be at least 1"); return 1
    left = s["experiments"] - s["spent"]
    if a.n > left:
        print(f"BUDGET: {a.n} more do not fit; {s['spent']} of {s['experiments']} used"); return 3
    s["spent"] += a.n
    save(a.dir, s)
    print(f"ok: {s['spent']} of {s['experiments']} used, {left - a.n} left"); return 0


def carve(a, kind):
    s = load(a.dir)
    depth = s["depth"] + (1 if kind == "child" else 0)
    if depth > s["max_depth"]:
        print(f"refused: depth {depth} exceeds max depth {s['max_depth']}"); return 1
    if kind == "fork" and s["kind"] == "fork":
        print("refused: a fork does not fork again; forks happen in the campaign that scheduled them"); return 1
    left = s["experiments"] - s["spent"]
    cap = left // 2 if kind == "child" else left
    if a.experiments < 1 or a.experiments > cap:
        print(f"refused: a {kind} may take 1 to {cap} experiments ({left} left in the parent)"); return 1
    fence = (getattr(a, "fence", None) or s["fence"])
    outside = [g for g in fence if not contained(g, s["fence"])]
    if outside:
        print(f"refused: {kind} fence outside the parent's: " + ", ".join(outside)); return 1
    if (Path(a.target) / STATE).exists() or seal_path(a.target).is_file():
        print(f"refused: {a.target} already holds a campaign"); return 1
    s["spent"] += a.experiments
    s["children"].append(str(a.target))
    save(a.dir, s)
    t = {"kind": kind, "depth": depth, "max_depth": s["max_depth"], "parent": str(a.dir), "fence": fence,
         "lock_globs": s["lock_globs"], "locked": s["locked"], "experiments": a.experiments, "spent": 0,
         "children": [], "legs": 1, "max_legs": 1, "ended": None, "start": git("rev-parse", "HEAD"),
         "contract_sha": contract_sha(a.target), "higher_is_better": s["higher_is_better"], "merge": "none"}
    save(a.target, t)
    ledger(kind, a.target, parent=str(Path(a.dir).resolve()), experiments=a.experiments)
    print(f"ok: {kind} at depth {depth} with {a.experiments} experiments; parent has {left - a.experiments} left")
    return 0


def cmd_forks(a):
    s = load(a.dir)
    n = s["experiments"]
    each = max(1, round(0.06 * n))
    if n < 12:
        print(f"off: {n} experiments is too short a leg to fork (needs 12)"); return 0
    at = sorted({max(1, round(n / 3)), max(1, round(2 * n / 3))})
    print(f"fork at experiments {at[0]} and {at[-1]}: {a.k} fresh-context forks of {each} experiment(s) each, "
          f"{a.k * each} per fork point, carved with `lab.py fork`")
    return 0


def cmd_end(a):
    s = load(a.dir)
    if a.state not in ENDS:
        print("usage: STATE is one of " + " ".join(ENDS)); return 2
    s["ended"] = a.state
    save(a.dir, s)
    ledger("end", a.dir, state=a.state, leg=s["legs"])
    print(f"ok: leg {s['legs']} ended {a.state}"); return 0


def cmd_leg(a):
    s = load(a.dir)
    if s["kind"] != "campaign":
        print(f"refused: a {s['kind']} runs one leg and never re-arms"); return 1
    if not s.get("ended"):
        print("refused: the last leg has no recorded end; run `lab.py end <dir> <STATE>` first"); return 1
    if s["legs"] >= s["max_legs"]:
        print(f"RETIRED: {s['legs']} of {s['max_legs']} legs used; extend only through /decide-nt"); return 1
    if s["ended"] in ("STAGNANT", "DRY-WELL") and contract_sha(a.dir) == s.get("contract_sha"):
        print(f"refused: the last leg ended {s['ended']} and contract.md is unchanged; change the fence, budget or hypothesis"); return 1
    bad = [f for f, h in s["locked"].items() if not Path(f).is_file() or sha_file(f) != h]
    if bad:
        print("PARKED: locked files changed between legs: " + ", ".join(bad)); return 1
    if a.experiments < 1:
        print("refused: --experiments must be at least 1"); return 1
    s.update(experiments=a.experiments, spent=0, legs=s["legs"] + 1, ended=None,
             start=git("rev-parse", "HEAD"), contract_sha=contract_sha(a.dir))
    save(a.dir, s)
    ledger("leg", a.dir, leg=s["legs"], experiments=a.experiments)
    print(f"ok: lockbox intact; leg {s['legs']} of {s['max_legs']} with {a.experiments} experiments"); return 0


def cmd_merge_ok(a):
    s = load(a.dir)
    n = inits(a.dir)
    ok = s["kind"] == "campaign" and s["merge"] == "auto" and n == 1
    ledger("merge-ok", a.dir, granted=ok)
    if ok:
        print("ok: merge granted for this campaign"); return 0
    reason = f"the ledger shows {n} inits for this directory" if s["merge"] == "auto" and s["kind"] == "campaign" else "no merge grant for this campaign"
    print(f"refused: {reason}"); return 1


def main(argv=None):
    p = argparse.ArgumentParser(prog="lab.py", description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("init"); i.add_argument("dir")
    i.add_argument("--fence", nargs="+", default=[]); i.add_argument("--lock", nargs="+", default=[])
    i.add_argument("--experiments", type=int, required=True); i.add_argument("--max-depth", type=int, default=2)
    i.add_argument("--max-legs", type=int, default=5)
    i.add_argument("--lower-is-better", action="store_true"); i.add_argument("--merge", choices=["none", "auto"], default="none")
    c = sub.add_parser("check"); c.add_argument("dir"); c.add_argument("--base")
    n = sub.add_parser("noise"); n.add_argument("values", type=float, nargs="+")
    k = sub.add_parser("keep"); k.add_argument("dir"); k.add_argument("--noise", type=float)
    k.add_argument("--gate", choices=["pass", "fail"], required=True)
    k.add_argument("--base", type=float, nargs="+"); k.add_argument("--cand", type=float, nargs="+")
    k.add_argument("--paired", type=float, nargs="+")
    sp = sub.add_parser("spend"); sp.add_argument("dir"); sp.add_argument("--n", type=int, default=1)
    ch = sub.add_parser("child"); ch.add_argument("dir"); ch.add_argument("target")
    ch.add_argument("--experiments", type=int, required=True); ch.add_argument("--fence", nargs="+")
    fk = sub.add_parser("fork"); fk.add_argument("dir"); fk.add_argument("target")
    fk.add_argument("--experiments", type=int, required=True)
    f = sub.add_parser("forks"); f.add_argument("dir"); f.add_argument("--k", type=int, default=3)
    e = sub.add_parser("end"); e.add_argument("dir"); e.add_argument("state")
    lg = sub.add_parser("leg"); lg.add_argument("dir"); lg.add_argument("--experiments", type=int, required=True)
    m = sub.add_parser("merge-ok"); m.add_argument("dir")
    a = p.parse_args(argv)
    if a.cmd in ("child", "fork"):
        return carve(a, a.cmd)
    return {"init": cmd_init, "check": cmd_check, "noise": cmd_noise, "keep": cmd_keep, "spend": cmd_spend,
            "forks": cmd_forks, "end": cmd_end, "leg": cmd_leg, "merge-ok": cmd_merge_ok}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
