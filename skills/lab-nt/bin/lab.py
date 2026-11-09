#!/usr/bin/env python3
"""Deterministic rules for /lab-nt. Standard library only. Run from the root of the campaign's worktree.

The campaign state lives in <dir>/lab.json (<dir> is plan/lab/<slug>, or a child or fork under it). Every save
seals the whole state: its digest goes outside plan/, into the repo's git directory (lab-seals/), and every call
refuses a state file that no longer matches. Each init, child, fork, leg and end is also appended to
lab-seals/ledger.jsonl, and a directory that was ever initialised cannot be initialised again.

What the seal is: tamper evidence. It catches a hand edit to lab.json, a deleted state file, and a re-init that
would reset the budget. It does not stop an agent that deliberately rewrites the seal, the
ledger and this script; that would break the skill's stop-lines, and the ledger and git history show it.

  kind, depth, max_depth, parent  "campaign" | "child" | "fork"; a child is one level deeper, a fork the same depth
  fence                           globs the loop may change; every changed path must match one at every ancestor
  lock_globs, locked              globs the loop may never change, with the sha256 of each file found at init
  start                           the commit the current leg began from; `check` diffs against it by default
  experiments, spent, children    this leg's budget, what is used, and the children and forks carved from it
  legs, max_legs, ended           leg odometer and how the last leg ended
  contract_sha                    sha256 of contract.md when the leg began; `check` refuses a changed contract
  higher_is_better                metric direction
  surprise_threshold              |surprise| above this is HIGH; null means the default, 10% of |predicted|
  baseline_failures               gate failures seen on the campaign's start commit (`baseline`); null = not yet
                                  recorded, [] = clean. Carried across legs, because a kept tip fails no more.
  ideas                           the surprise ledger: experiment id -> proposer, predicted (written before the run),
                                  leg, and once measured: actual, surprise (actual - predicted, sign kept), outcome;
                                  a planted judge case carries judge: true and is left out of `summary`
  no_judge, judged, judge         init --no-judge; whether the judge is sealed; the planted cases (name = the planted
                                  experiment id, expect, got = its recorded outcome, match). A child or fork copies its parent's judged status when it is carved. A state
                                  file with no `judged` key predates the judge and counts as judged.

The judge. Before experiment 1 the agent plants known changes (a no-op, a planted gain, a wrong output, an edit to a
locked file, ...) on a throwaway branch, runs each through the normal harness and `keep` path under an id predicted
with `predict --judge`, and records the case with `judge --case <id> --expect V`; the verdict it got is read from that
id's recorded outcome, never typed in. `judge --done` seals it once at least 3 cases are recorded, all match, and
together they got each of keep, revert and fail at least once; until then `predict` refuses ordinary experiments. A mismatch is PARKED (exit 5).
Judge runs spend no experiment budget.

The keep decision runs `check` itself, against the leg's start commit, before any verdict: a violation is a REVERT
recorded as fail. A KEEP whose surprise is HIGH (|actual - predicted| above the threshold) counts only when fresh
confirmation runs, alternated with best-so-far, reproduce the gain (`--confirm-base` with `--confirm`, or
`--confirm-paired` in paired mode).

The surprise ledger. Every experiment is predicted before it runs (`predict`), and `keep` and `record` refuse an
id with no prediction, the same way `keep` refuses a failed gate. Because the ledger sits in the sealed state file,
a prediction cannot be changed after the result is known, and a recorded result cannot be rewritten. A state file
written before the ledger existed has no `ideas` or `surprise_threshold` key; it loads, checks and summarises as
"no predictions recorded", and only new experiments need a prediction.

Globs: `*` and `?` stay inside one path segment, `**` spans any number of segments (including none), and hidden
files match like any other. The same matcher expands lock globs and tests changed paths; symlinks are not followed
below a glob's literal base. Untracked files count as changes unless a committed .gitignore covers them (entries in
.git/info/exclude or a global excludes file do not hide a file from `check`); lock what the measurement imports
from ignored paths, such as a virtualenv, by glob.

Subcommands and exit codes (0 ok; 1 refused or violated; 2 usage; 3 budget; 4 REVERT; 5 PARKED by the judge):
  init  <dir> --fence G.. --lock G.. --experiments N [--max-depth 2] [--max-legs 5] [--lower-is-better]
        [--surprise X] [--no-judge]
                             every lock glob must match a file; refuses a directory initialised before; X is the
                             high-surprise threshold in metric units (default: 10% of |predicted|, per experiment);
                             --no-judge skips the judge (only with the owner's say-so)
  judge <dir> --case ID --expect V | --done
                             V is keep, revert or fail. Records one planted case: ID is an experiment predicted with
                             `predict --judge`, and got is its recorded outcome (refuses an ID with no such row or no
                             outcome yet, a repeated ID, a child or fork, a --no-judge campaign, a sealed judge);
                             exit 5 PARKED when got differs from expect. --done seals the judge: exit 5 PARKED when
                             any case mismatched; refused under 3 cases or when keep, revert or fail is never got
  check <dir> [--base REF]   seal intact; locked files unchanged and none added; contract.md unchanged; every
                             change since --base (default: the leg's start) inside the fence of every ancestor
  noise <v> <v> <v>..        spread (max - min) and mean of re-measures of the unchanged baseline
  predict <dir> <id> --proposer P --predicted V [--judge]
                             before the run: who proposed the idea (provider/model or vault note path) and the
                             metric value they expect; refuses an id that already has a prediction. Refuses an
                             ordinary experiment until the judge is sealed (or --no-judge); --judge marks a planted
                             case and is refused once the judge is sealed
  baseline <dir> [--failures ID..]
                             record the gate failures observed on the start commit (none: a clean start); an ID is
                             the failure's own text, e.g. "olmoe/prompt 4/decode/6/layer-13"
  keep  <dir> --id ID --gate pass|fail|known [--failures ID..] (--noise X --base v.. --cand v.. [--control v..]
        [--confirm-base v.. --confirm v..] | --paired d.. --actual V [--confirm-paired d..])
                             first runs `check` against the leg's start: any problem prints
                             "REVERT: lab.py check fails: ...", records fail and exits 4
                             --confirm-base / --confirm / --confirm-paired: a KEEP with HIGH surprise is refused
                             (exit 1, nothing recorded) without them. --confirm-base and --confirm are fresh readings
                             of best-so-far and the candidate, taken alternately (at least 3 each, counts differing by
                             at most 1); it keeps only if sign*(mean(confirm) - mean(confirm-base)) > noise, or the
                             paired interval over the confirm gains (at least 10) excludes zero, and reverts
                             otherwise. Results that are not HIGH-surprise KEEPs ignore them
                             --control: readings of the simple-fix control (the cheapest standard fix for the same
                             symptom, applied to best-so-far); a KEEP must also beat the control's mean by more than
                             the noise, or it reverts because the plain fix explains the gain
                             --gate known: the candidate's gate failures (--failures) are all in the recorded
                             baseline, so they do not count against it; any other failure reverts; refused when no
                             baseline is recorded. Refused (exit 1) when ID has no prediction or already has a
                             result; exit 0 KEEP when the gate passed and the gain beats the noise (X >= 0), or the paired 95% bootstrap
                             interval over at least 10 items excludes zero; exit 4 REVERT otherwise. Records the
                             outcome and surprise (actual is the mean of --cand, and --actual with --cand is a usage
                             error, so HIGH surprise cannot be hidden; --actual is the paired-mode metric; a failed
                             gate records no actual, because its metric does not count)
  record <dir> <id> --outcome revert|fail [--actual V]
                             the result of an experiment that never reached `keep` (blown cap, scope violation,
                             crash); revert needs --actual; same refusals as keep
  summary <dir> [--leg N]    surprise rate and kept ideas per proposer, over the campaign and every child and fork
  spend <dir> [--n 1]        book n experiments before running them; exit 3 (nothing booked) when they do not fit
  child <dir> <child-dir> --experiments N [--fence G..]   one level deeper, at most half the parent's remainder,
                             fence contained in the parent's (equal, or under a parent glob ending in **)
  fork  <dir> <fork-dir> --experiments N                  same depth and fence, budget carved from the parent
  forks <dir> [--k 3]        fork-and-flush schedule: the experiment numbers to fork at, per-fork budget
  end   <dir> <STATE>        record how the leg ended (GOAL-MET BUDGET STAGNANT DRY-WELL PARKED)
  leg   <dir> --experiments N  start a resumed leg of a top-level campaign: refuses children and forks, a leg with
                             no recorded end, an exhausted odometer, a changed lock, and a STAGNANT or DRY-WELL end
                             with contract.md unchanged
"""
import argparse, hashlib, json, math, os, random, re, subprocess, sys, time
from pathlib import Path

STATE = "lab.json"
VERDICTS = ["keep", "revert", "fail"]
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
    if a.surprise is not None and not (math.isfinite(a.surprise) and a.surprise >= 0):
        print("refused: --surprise is a threshold in metric units and must be a finite number >= 0"); return 1
    s = {"kind": "campaign", "depth": 0, "max_depth": a.max_depth, "parent": None, "fence": a.fence,
         "lock_globs": a.lock, "locked": {f: sha_file(f) for f in files}, "experiments": a.experiments,
         "spent": 0, "children": [], "legs": 1, "max_legs": a.max_legs, "ended": None,
         "start": git("rev-parse", "HEAD"), "contract_sha": contract_sha(a.dir),
         "higher_is_better": not a.lower_is_better,
         "surprise_threshold": a.surprise, "ideas": {},
         "no_judge": a.no_judge, "judged": False, "judge": []}
    save(a.dir, s)
    ledger("init", a.dir, experiments=a.experiments)
    print(f"ok: {len(files)} locked files, fence {a.fence}, {a.experiments} experiments, max depth {a.max_depth}")
    return 0


def check_problems(d, s, base=None):
    """What `check` would report for campaign d with state s: (sorted problems, the base commit used)."""
    problems = []
    for f, h in s["locked"].items():
        if not Path(f).is_file():
            problems.append(f"locked file missing: {f}")
        elif sha_file(f) != h:
            problems.append(f"locked file changed: {f}")
    for f in expand(s["lock_globs"]):
        if f not in s["locked"]:
            problems.append(f"new file in a locked path: {f}")
    if contract_sha(d) != s.get("contract_sha"):
        problems.append(f"contract changed: {d}/contract.md")
    base = base or s["start"]
    changed = set(git("diff", "--no-renames", "--name-only", base).splitlines())
    changed |= set(git("ls-files", "--others", "--exclude-per-directory=.gitignore").splitlines())
    fences = [x["fence"] for x in ancestors(d, s)]
    for p in sorted(c for c in changed if c and not c.startswith("plan/") and not skipped(c)):
        if p in s["locked"] or matches(p, s["lock_globs"]):
            problems.append(f"change touches a locked path: {p}")
        elif not all(matches(p, f) for f in fences):
            problems.append(f"change outside the fence: {p}")
    return sorted(set(problems)), base


def cmd_check(a):
    s = load(a.dir)
    problems, base = check_problems(a.dir, s, a.base)
    if problems:
        print("\n".join(problems)); return 1
    print(f"ok: seal, lockbox and contract intact, every change since {base[:12]} inside the fence"); return 0


def mean(v):
    return sum(v) / len(v)


def threshold(s, predicted):
    t = s.get("surprise_threshold")
    return t if t is not None else 0.1 * abs(predicted)


def surprise_text(s, row):
    if row.get("actual") is None:
        return "no surprise recorded (no metric that counts)"
    sur = row["surprise"]
    better = (sur > 0) == s["higher_is_better"]
    high = abs(sur) > threshold(s, row["predicted"])
    side = "as predicted" if sur == 0 else ("better than predicted" if better else "worse than predicted")
    return f"surprise {sur:+.6g} (|{abs(sur):.6g}|, {side}{', HIGH' if high else ''})"


def unrecorded(d, s, eid, actual=None):
    """The idea row for eid when it has a prediction and no result yet; None (after printing why) otherwise."""
    if actual is not None and not math.isfinite(actual):
        print("refused: --actual must be a finite number"); return None
    row = (s.get("ideas") or {}).get(eid)
    if row is None:
        print(f"refused: experiment {eid} has no prediction; run `lab.py predict {d} {eid} --proposer P --predicted V` before running it")
        return None
    if "outcome" in row:
        print(f"refused: experiment {eid} already has a result ({row['outcome']}); past rows are never rewritten")
        return None
    return row


def record(d, s, eid, row, outcome, actual):
    row.update(outcome=outcome, recorded_at=time.strftime("%Y-%m-%dT%H:%M:%S%z"))
    if actual is not None:
        row.update(actual=actual, surprise=actual - row["predicted"])
    save(d, s)
    ledger("result", d, id=eid, outcome=outcome, actual=actual)
    print(f"{eid}: predicted {row['predicted']:.6g} by {row['proposer']}; " + surprise_text(s, row))


def cmd_predict(a):
    s = load(a.dir)
    if not a.id.strip() or not a.proposer.strip():
        print("refused: the experiment id and the proposer cannot be empty"); return 1
    if not math.isfinite(a.predicted):
        print("refused: --predicted must be a finite number"); return 1
    if a.id in (s.get("ideas") or {}):
        print(f"refused: experiment {a.id} already has a prediction; past rows are never rewritten"); return 1
    if a.judge and judged(s):
        print("refused: the judge is sealed (or not used); --judge marks a planted case, which only runs before experiment 1"); return 1
    if not a.judge and not judged(s):
        print(f"refused: the judge is not sealed; run the planted cases (`lab.py predict {a.dir} <id> --judge`, `lab.py keep`), "
              f"record each with `lab.py judge {a.dir} --case <id> --expect <verdict>`, "
              f"then `lab.py judge {a.dir} --done`"); return 1
    row = {"proposer": a.proposer, "predicted": a.predicted, "leg": s["legs"],
           "predicted_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "head": git("rev-parse", "HEAD")}
    if a.judge:
        row["judge"] = True
    s.setdefault("ideas", {})[a.id] = row
    save(a.dir, s)
    ledger("predict", a.dir, id=a.id, proposer=a.proposer, predicted=a.predicted)
    print(f"ok: {a.id} predicted {a.predicted:.6g} by {a.proposer}"); return 0


def judged(s):
    """True when experiments may be predicted: the judge is sealed, the campaign opted out with --no-judge, or the
    state file predates the judge (no `judged` key), so campaigns already running are not blocked."""
    return s.get("judged", True) is True or bool(s.get("no_judge"))


def cmd_judge(a):
    s = load(a.dir)
    if s["kind"] != "campaign":
        print(f"refused: a {s['kind']} inherits its parent's judge and never runs its own"); return 1
    if s.get("no_judge"):
        print("refused: this campaign was initialised with --no-judge"); return 1
    if judged(s):
        print("refused: the judge is already sealed; its cases are never rewritten"); return 1
    cases = s.setdefault("judge", [])
    if a.done:
        if a.case or a.expect:
            print("usage: judge --done takes no --case or --expect"); return 2
        bad = [c for c in cases if not c["match"]]
        if bad:
            c = bad[0]
            print(f"PARKED: the judge returned {c['got']} for {c['name']}, expected {c['expect']}; fix the harness or the gates, never the loop"); return 5
        if len(cases) < 3:
            print(f"refused: the judge needs at least 3 planted cases; {len(cases)} recorded"); return 1
        missing = [v for v in VERDICTS if not any(c["got"] == v for c in cases)]
        if missing:
            print("refused: the planted cases must cover every verdict (keep, revert, fail); none got " + ", ".join(missing)); return 1
        s["judged"] = True
        save(a.dir, s)
        ledger("judge-done", a.dir, cases=len(cases))
        print(f"ok: judge sealed, {len(cases)} of {len(cases)} planted cases got their expected verdict; experiment 1 may be predicted")
        return 0
    if not (a.case and a.case.strip() and a.expect):
        print("usage: judge needs --case ID --expect V, or --done"); return 2
    if any(c["name"] == a.case for c in cases):
        print(f"refused: judge case {a.case} is already recorded; past rows are never rewritten"); return 1
    row = (s.get("ideas") or {}).get(a.case)
    if row is None or not row.get("judge"):
        print(f"refused: {a.case} is not a planted experiment; run `lab.py predict {a.dir} {a.case} --judge ...` "
              "and the keep path first"); return 1
    got = row.get("outcome")
    if got not in VERDICTS:
        print(f"refused: planted experiment {a.case} has no recorded outcome yet; run it through `lab.py keep` "
              "(or `lab.py record`) first"); return 1
    match = a.expect == got
    cases.append({"name": a.case, "expect": a.expect, "got": got, "match": match})
    save(a.dir, s)
    ledger("judge", a.dir, case=a.case, expect=a.expect, got=got, match=match)
    if not match:
        print(f"PARKED: the judge returned {got} for {a.case}, expected {a.expect}; fix the harness or the gates, never the loop"); return 5
    print(f"ok: judge case {a.case} got {got} as expected; {len(cases)} recorded"); return 0


def cmd_record(a):
    s = load(a.dir)
    if a.outcome == "revert" and a.actual is None:
        print("usage: --outcome revert needs --actual, the harness number"); return 2
    row = unrecorded(a.dir, s, a.id, a.actual)
    if row is None:
        return 1
    record(a.dir, s, a.id, row, a.outcome, a.actual)
    return 0


def cmd_noise(a):
    if len(a.values) < 3:
        print("refused: measure the unchanged baseline at least 3 times"); return 1
    print(f"noise {max(a.values) - min(a.values):.6g} mean {mean(a.values):.6g} n {len(a.values)}"); return 0


def cmd_keep(a):
    s = load(a.dir)
    sign = 1 if s["higher_is_better"] else -1
    row = unrecorded(a.dir, s, a.id, a.actual)
    if row is None:
        return 1
    if a.cand and a.actual is not None:
        print("usage: with --cand the recorded actual is the mean of --cand; drop --actual (it is only for --paired)"); return 2
    problems, _ = check_problems(a.dir, s)
    if problems:
        print("REVERT: lab.py check fails: " + "; ".join(problems))
        record(a.dir, s, a.id, row, "fail", None); return 4
    if a.gate == "known":
        known = s.get("baseline_failures")
        if known is None:
            print("refused: no baseline recorded; run the gates on the start commit and `lab.py baseline <dir>` first"); return 1
        if not a.failures:
            print("usage: --gate known needs --failures, the candidate's gate failures"); return 2
        new = [f for f in a.failures if f not in known]
        if new:
            print("REVERT: gate failures not on the start commit: " + "; ".join(new))
            record(a.dir, s, a.id, row, "fail", None); return 4
        print(f"gate: {len(a.failures)} failure(s), all on the start commit's baseline; they do not count")
    elif a.gate != "pass":
        print("REVERT: the gate failed for this commit, so its metric does not count")
        record(a.dir, s, a.id, row, "fail", None); return 4
    if a.paired:
        if len(a.paired) < 10:
            print("usage: a paired decision needs at least 10 items"); return 2
        if a.actual is None:
            print("usage: a paired decision needs --actual, the candidate's metric as the harness reports it"); return 2
        lo, hi = paired_interval(sign, a.paired)
        verdict = "KEEP" if lo > 0 else "REVERT"
        print(f"{verdict}: paired gain 95% interval [{lo:.6g}, {hi:.6g}] over {len(a.paired)} items")
        actual = a.actual
    else:
        if not a.base or not a.cand or a.noise is None:
            print("usage: keep needs --noise, --base and --cand, or --paired"); return 2
        if a.noise < 0:
            print("usage: --noise is a spread and cannot be negative"); return 2
        gain = sign * (mean(a.cand) - mean(a.base))
        verdict = "KEEP" if gain > a.noise else "REVERT"
        print(f"{verdict}: gain {gain:.6g} against noise {a.noise:.6g}")
        if verdict == "KEEP" and a.control:
            over = sign * (mean(a.cand) - mean(a.control))
            if over > a.noise:
                print(f"control: beats the simple-fix control by {over:.6g} against noise {a.noise:.6g}")
            else:
                verdict = "REVERT"
                print(f"REVERT: the simple-fix control reaches it (candidate leads the control by {over:.6g}, noise {a.noise:.6g})")
        actual = mean(a.cand)
    if verdict == "KEEP" and abs(actual - row["predicted"]) > threshold(s, row["predicted"]):
        # a HIGH-surprise win counts only when fresh runs, alternated with best-so-far, reproduce it
        if a.paired:
            if not a.confirm_paired:
                print("refused: a HIGH-surprise win needs --confirm-paired, per-item gains from fresh runs; nothing recorded"); return 1
            if len(a.confirm_paired) < 10:
                print("usage: --confirm-paired needs at least 10 items"); return 2
            lo, hi = paired_interval(sign, a.confirm_paired)
            held, what = lo > 0, f"paired 95% interval [{lo:.6g}, {hi:.6g}] over {len(a.confirm_paired)} items"
        else:
            if not a.confirm or not a.confirm_base:
                print("refused: a HIGH-surprise win needs --confirm-base and --confirm, fresh readings of best-so-far and the "
                      "candidate taken alternately; nothing recorded"); return 1
            if len(a.confirm) < 3 or len(a.confirm_base) < 3:
                print("usage: --confirm-base and --confirm need at least 3 readings each"); return 2
            if abs(len(a.confirm) - len(a.confirm_base)) > 1:
                print("usage: --confirm-base and --confirm are taken alternately, so their counts differ by at most 1"); return 2
            gain = sign * (mean(a.confirm) - mean(a.confirm_base))
            held, what = gain > a.noise, f"{gain:.6g} against noise {a.noise:.6g}"
        if held:
            print(f"confirm: the HIGH-surprise gain held on fresh runs ({what})")
        else:
            verdict = "REVERT"
            print(f"REVERT: the HIGH-surprise gain did not hold on fresh runs ({what})")
    record(a.dir, s, a.id, row, verdict.lower(), actual)
    return 0 if verdict == "KEEP" else 4


def paired_interval(sign, gains):
    """95% bootstrap interval of the mean paired gain, oriented so that positive is better."""
    rng = random.Random(0)
    d = [sign * x for x in gains]
    means = sorted(mean([rng.choice(d) for _ in d]) for _ in range(2000))
    return means[49], means[1949]


def cmd_baseline(a):
    s = load(a.dir)
    s["baseline_failures"] = sorted(set(a.failures or []))
    save(a.dir, s)
    ledger("baseline", a.dir, failures=s["baseline_failures"])
    n = len(s["baseline_failures"])
    print("ok: clean baseline, every gate passes on the start commit" if not n else
          f"ok: {n} start-commit gate failure(s) recorded; candidates may fail these and only these"); return 0


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
         "contract_sha": contract_sha(a.target), "higher_is_better": s["higher_is_better"],
         "surprise_threshold": s.get("surprise_threshold"), "ideas": {},
         "no_judge": s.get("no_judge", False), "judged": judged(s), "judge": []}
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


def cmd_summary(a):
    s = load(a.dir)
    root = Path(a.dir)
    rows, todo, seen = [], [(a.dir, s)], 0
    while todo:
        d, st = todo.pop(0)
        seen += 1
        rel = Path(d).relative_to(root).as_posix() if Path(d) != root and Path(d).is_relative_to(root) else ""
        for eid, row in (st.get("ideas") or {}).items():
            if (a.leg is None or row.get("leg") == a.leg) and not row.get("judge"):
                rows.append((f"{rel}/{eid}" if rel else eid, st, row))
        todo += [(c, load(c)) for c in st.get("children", [])]
    scope = f"leg {a.leg}" if a.leg is not None else "all legs"
    if not rows:
        print(f"no predictions recorded in {a.dir} ({scope}, {seen} state files); state written before the surprise"
              " ledger has none, and only new experiments need one"); return 0
    measured = [(i, st, r) for i, st, r in rows if r.get("actual") is not None]
    high = {i for i, st, r in measured if abs(r["surprise"]) > threshold(st, r["predicted"])}
    t = s.get("surprise_threshold")
    rule = f"|surprise| > {t:.6g}" if t is not None else "|surprise| > 10% of |predicted| (default)"
    print(f"surprise ledger for {a.dir} ({scope}, {seen} state files): {len(rows)} predicted, "
          f"{sum('outcome' in r for _, _, r in rows)} with a result, {len(measured)} measured")
    if measured:
        print(f"surprise rate: {len(high)} of {len(measured)} measured ({100 * len(high) / len(measured):.0f}%) with {rule}; "
              f"mean |surprise| {mean([abs(r['surprise']) for _, _, r in measured]):.6g}")
    else:
        print(f"surprise rate: no measured results yet ({rule})")
    per = {}
    for i, st, r in rows:
        p = per.setdefault(r["proposer"], [0, 0, 0, 0])
        p[0] += 1
        p[1] += r.get("actual") is not None
        p[2] += r.get("outcome") == "keep"
        p[3] += i in high
    print("kept ideas per proposer (ideas · measured · kept · high surprise):")
    for name, (n, m, k, h) in sorted(per.items(), key=lambda x: (-x[1][2], x[0])):
        print(f"  {name} · {n} · {m} · {k} · {h}")
    print("rows:")
    for i, st, r in rows:
        res = f"actual {r['actual']:.6g} · {surprise_text(st, r)}" if r.get("actual") is not None else "no metric that counts"
        print(f"  {i} · {r['proposer']} · predicted {r['predicted']:.6g} · {res} · {r.get('outcome', 'pending')}")
    return 0


def main(argv=None):
    p = argparse.ArgumentParser(prog="lab.py", description=__doc__.split("\n")[0])
    sub = p.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("init"); i.add_argument("dir")
    i.add_argument("--fence", nargs="+", default=[]); i.add_argument("--lock", nargs="+", default=[])
    i.add_argument("--experiments", type=int, required=True); i.add_argument("--max-depth", type=int, default=2)
    i.add_argument("--max-legs", type=int, default=5)
    i.add_argument("--lower-is-better", action="store_true")
    i.add_argument("--surprise", type=float); i.add_argument("--no-judge", action="store_true")
    c = sub.add_parser("check"); c.add_argument("dir"); c.add_argument("--base")
    n = sub.add_parser("noise"); n.add_argument("values", type=float, nargs="+")
    k = sub.add_parser("keep"); k.add_argument("dir"); k.add_argument("--noise", type=float)
    k.add_argument("--id", required=True); k.add_argument("--actual", type=float)
    k.add_argument("--gate", choices=["pass", "fail", "known"], required=True); k.add_argument("--failures", nargs="+")
    bl = sub.add_parser("baseline"); bl.add_argument("dir"); bl.add_argument("--failures", nargs="+")
    k.add_argument("--base", type=float, nargs="+"); k.add_argument("--cand", type=float, nargs="+")
    k.add_argument("--paired", type=float, nargs="+"); k.add_argument("--control", type=float, nargs="+")
    k.add_argument("--confirm", type=float, nargs="+"); k.add_argument("--confirm-paired", type=float, nargs="+")
    k.add_argument("--confirm-base", type=float, nargs="+")
    jd = sub.add_parser("judge"); jd.add_argument("dir"); jd.add_argument("--case")
    jd.add_argument("--expect", choices=VERDICTS)
    jd.add_argument("--done", action="store_true")
    sp = sub.add_parser("spend"); sp.add_argument("dir"); sp.add_argument("--n", type=int, default=1)
    ch = sub.add_parser("child"); ch.add_argument("dir"); ch.add_argument("target")
    ch.add_argument("--experiments", type=int, required=True); ch.add_argument("--fence", nargs="+")
    fk = sub.add_parser("fork"); fk.add_argument("dir"); fk.add_argument("target")
    fk.add_argument("--experiments", type=int, required=True)
    f = sub.add_parser("forks"); f.add_argument("dir"); f.add_argument("--k", type=int, default=3)
    e = sub.add_parser("end"); e.add_argument("dir"); e.add_argument("state")
    lg = sub.add_parser("leg"); lg.add_argument("dir"); lg.add_argument("--experiments", type=int, required=True)
    pr = sub.add_parser("predict"); pr.add_argument("dir"); pr.add_argument("id")
    pr.add_argument("--proposer", required=True); pr.add_argument("--predicted", type=float, required=True)
    pr.add_argument("--judge", action="store_true")
    rc = sub.add_parser("record"); rc.add_argument("dir"); rc.add_argument("id")
    rc.add_argument("--outcome", choices=["revert", "fail"], required=True); rc.add_argument("--actual", type=float)
    su = sub.add_parser("summary"); su.add_argument("dir"); su.add_argument("--leg", type=int)
    a = p.parse_args(argv)
    if a.cmd in ("child", "fork"):
        return carve(a, a.cmd)
    return {"init": cmd_init, "check": cmd_check, "noise": cmd_noise, "keep": cmd_keep, "baseline": cmd_baseline, "spend": cmd_spend,
            "forks": cmd_forks, "end": cmd_end, "leg": cmd_leg, "predict": cmd_predict,
            "record": cmd_record, "summary": cmd_summary, "judge": cmd_judge}[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
