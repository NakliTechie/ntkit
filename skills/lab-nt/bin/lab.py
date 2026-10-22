#!/usr/bin/env python3
"""Deterministic checks for /lab-nt. Standard library only. Run from the repo (or worktree) root.

The campaign state lives in <dir>/lab.json, where <dir> is plan/lab/<slug> (or a child under it):
  depth, max_depth, parent   recursion bookkeeping; a child is one level deeper than its parent
  fence                      globs the loop may change; every changed path must match one
  lock_globs, locked         globs the loop may never change, and the sha256 of each file at init
  experiments, spent         the leg's experiment budget and what is used (children take theirs out of it)
  higher_is_better           direction of the metric
  merge                      "none" (default) or "auto": the user's per-run grant to merge a kept result

Subcommands (exit 0 ok, 1 refused or violated, 2 usage, 3 budget exhausted):
  init  <dir> --fence G.. --lock G.. --experiments N [--max-depth 2] [--lower-is-better] [--merge auto]
  check <dir> [--base REF]       locked files unchanged; every changed path inside the fence, none locked
  noise <v> <v> <v>..            spread (max - min) and mean of re-measures of the unchanged baseline
  keep  <dir> --noise X --gate pass|fail (--base v.. --cand v.. | --paired d..)
                                 KEEP only when the gate passed and the gain beats the noise
                                 (or, paired, the 95% bootstrap interval of the per-item gain excludes zero)
  spend <dir> [--n 1]            count experiments; exit 3 once the budget is used
  child <dir> <child-dir> --experiments N [--fence G..]
                                 open a child campaign: depth limit, budget carved from the parent,
                                 fence inside the parent's, the parent's locks inherited
  forks <dir> [--k 3]            fork-and-flush schedule: the experiment numbers to fork at, per-fork budget
  leg   <dir> --experiments N    start a resumed leg: every locked hash re-checked, experiment counter reset
"""
import argparse, fnmatch, glob, hashlib, json, random, subprocess, sys
from pathlib import Path

STATE = "lab.json"


def load(d):
    p = Path(d) / STATE
    if not p.is_file():
        raise SystemExit(f"no {STATE} in {d}; run `lab.py init` first")
    return json.loads(p.read_text())


def save(d, s):
    Path(d).mkdir(parents=True, exist_ok=True)
    (Path(d) / STATE).write_text(json.dumps(s, indent=2, sort_keys=True) + "\n")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def expand(globs):
    out = set()
    for g in globs:
        for f in glob.glob(g, recursive=True):
            if Path(f).is_file():
                out.add(Path(f).as_posix())
    return sorted(out)


def matches(path, globs):
    return any(fnmatch.fnmatchcase(path, g) for g in globs)


def changed_paths(base):
    def git(*a):
        r = subprocess.run(["git", *a], capture_output=True, text=True)
        if r.returncode:
            raise SystemExit(f"git {' '.join(a)}: {r.stderr.strip()}")
        return [l for l in r.stdout.splitlines() if l]
    paths = set(git("diff", "--name-only", base)) | set(git("ls-files", "--others", "--exclude-standard"))
    return sorted(p for p in paths if not p.startswith("plan/"))


def cmd_init(a):
    if not a.fence:
        print("refused: a campaign needs a fence (--fence)"); return 1
    files = expand(a.lock)
    if not files:
        print("refused: the lockbox is empty; --lock must match the harness, metric and gate files"); return 1
    overlap = [f for f in files if matches(f, a.fence)]
    if overlap:
        print("refused: locked files sit inside the fence: " + ", ".join(overlap)); return 1
    if a.experiments < 1:
        print("refused: --experiments must be at least 1"); return 1
    save(a.dir, {"depth": 0, "max_depth": a.max_depth, "parent": None, "fence": a.fence,
                 "lock_globs": a.lock, "locked": {f: sha(f) for f in files},
                 "experiments": a.experiments, "spent": 0, "children": [],
                 "higher_is_better": not a.lower_is_better, "merge": a.merge})
    print(f"ok: {len(files)} locked files, fence {a.fence}, {a.experiments} experiments, max depth {a.max_depth}")
    return 0


def lock_problems(s):
    out = []
    for f, h in s["locked"].items():
        if not Path(f).is_file():
            out.append(f"locked file missing: {f}")
        elif sha(f) != h:
            out.append(f"locked file changed: {f}")
    return out


def cmd_leg(a):
    s = load(a.dir)
    problems = lock_problems(s)
    if problems:
        print("PARKED: " + "; ".join(problems)); return 1
    if a.experiments < 1:
        print("refused: --experiments must be at least 1"); return 1
    s["experiments"], s["spent"] = a.experiments, 0
    save(a.dir, s)
    print(f"ok: lockbox intact; new leg with {a.experiments} experiments"); return 0


def cmd_check(a):
    s = load(a.dir)
    problems = lock_problems(s)
    for p in changed_paths(a.base):
        if matches(p, s["lock_globs"]) or p in s["locked"]:
            problems.append(f"change touches a locked path: {p}")
        elif not matches(p, s["fence"]):
            problems.append(f"change outside the fence: {p}")
    if problems:
        print("\n".join(problems)); return 1
    print("ok: lockbox intact, every change inside the fence"); return 0


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
        print("REVERT: the gate failed for this commit, so its metric does not count"); return 0
    if a.paired:
        rng = random.Random(0)
        d = [sign * x for x in a.paired]
        means = sorted(mean([rng.choice(d) for _ in d]) for _ in range(2000))
        lo, hi = means[49], means[1949]
        verdict = "KEEP" if lo > 0 else "REVERT"
        print(f"{verdict}: paired gain 95% interval [{lo:.6g}, {hi:.6g}] over {len(d)} items"); return 0
    if not a.base or not a.cand:
        print("usage: keep needs --base and --cand, or --paired"); return 2
    gain = sign * (mean(a.cand) - mean(a.base))
    verdict = "KEEP" if gain > a.noise else "REVERT"
    print(f"{verdict}: gain {gain:.6g} against noise {a.noise:.6g}"); return 0


def cmd_spend(a):
    s = load(a.dir)
    if s["spent"] >= s["experiments"]:
        print(f"BUDGET: {s['spent']} of {s['experiments']} experiments used"); return 3
    s["spent"] += a.n
    save(a.dir, s)
    left = s["experiments"] - s["spent"]
    print(f"ok: {s['spent']} of {s['experiments']} used, {left} left")
    return 3 if left <= 0 else 0


def cmd_child(a):
    s = load(a.dir)
    if s["depth"] + 1 > s["max_depth"]:
        print(f"refused: depth {s['depth'] + 1} exceeds max depth {s['max_depth']}"); return 1
    left = s["experiments"] - s["spent"]
    cap = left // 2
    if a.experiments < 1 or a.experiments > cap:
        print(f"refused: a child may take 1 to {cap} experiments (half of the parent's {left} left)"); return 1
    fence = a.fence or s["fence"]
    outside = [g for g in fence if not matches(g, s["fence"])]
    if outside:
        print("refused: child fence outside the parent's: " + ", ".join(outside)); return 1
    if (Path(a.child) / STATE).exists():
        print(f"refused: {a.child} already holds a campaign"); return 1
    save(a.child, {"depth": s["depth"] + 1, "max_depth": s["max_depth"], "parent": str(a.dir),
                   "fence": fence, "lock_globs": s["lock_globs"], "locked": s["locked"],
                   "experiments": a.experiments, "spent": 0, "children": [],
                   "higher_is_better": s["higher_is_better"], "merge": "none"})
    s["spent"] += a.experiments
    s["children"].append(str(a.child))
    save(a.dir, s)
    print(f"ok: child at depth {s['depth'] + 1} with {a.experiments} experiments; parent has {left - a.experiments} left")
    return 0


def cmd_forks(a):
    s = load(a.dir)
    n = s["experiments"]
    each = max(1, round(0.06 * n))
    if n < 12:
        print(f"off: {n} experiments is too short a leg to fork (needs 12)"); return 0
    at = sorted({max(1, round(n / 3)), max(1, round(2 * n / 3))})
    print(f"fork at experiments {at[0]} and {at[-1]}: {a.k} fresh-context forks of {each} experiment(s) each, "
          f"{a.k * each} per fork point, counted in the budget")
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(prog="lab.py", description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("init"); i.add_argument("dir")
    i.add_argument("--fence", nargs="+", default=[]); i.add_argument("--lock", nargs="+", default=[])
    i.add_argument("--experiments", type=int, required=True); i.add_argument("--max-depth", type=int, default=2)
    i.add_argument("--lower-is-better", action="store_true"); i.add_argument("--merge", choices=["none", "auto"], default="none")
    c = sub.add_parser("check"); c.add_argument("dir"); c.add_argument("--base", default="HEAD")
    n = sub.add_parser("noise"); n.add_argument("values", type=float, nargs="+")
    k = sub.add_parser("keep"); k.add_argument("dir"); k.add_argument("--noise", type=float, default=0.0)
    k.add_argument("--gate", choices=["pass", "fail"], required=True)
    k.add_argument("--base", type=float, nargs="+"); k.add_argument("--cand", type=float, nargs="+")
    k.add_argument("--paired", type=float, nargs="+")
    sp = sub.add_parser("spend"); sp.add_argument("dir"); sp.add_argument("--n", type=int, default=1)
    ch = sub.add_parser("child"); ch.add_argument("dir"); ch.add_argument("child")
    ch.add_argument("--experiments", type=int, required=True); ch.add_argument("--fence", nargs="+")
    f = sub.add_parser("forks"); f.add_argument("dir"); f.add_argument("--k", type=int, default=3)
    lg = sub.add_parser("leg"); lg.add_argument("dir"); lg.add_argument("--experiments", type=int, required=True)
    a = p.parse_args(argv)
    return {"init": cmd_init, "check": cmd_check, "noise": cmd_noise, "keep": cmd_keep,
            "spend": cmd_spend, "child": cmd_child, "forks": cmd_forks, "leg": cmd_leg}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
