#!/usr/bin/env python3
"""Check every reachable state of a small model and report which rules hold.

A model is a Python file that defines:
  init()          yields the starting states, each a dict of plain values
  actions(s, g)   yields (action name, next state) pairs from state s; wrap each guard as
                  g("guard name", condition), so the checker can switch that guard off
  RULES           {"plain sentence": function(state) -> bool}, true in every reachable state
  GUARDS          optional {"guard name": "the RULES sentence it protects"}

Usage: statecheck.py MODEL.py [--break-guards] [--max-states N] [--json]
  Walks every reachable state breadth-first, so a broken rule is reported with its shortest path.
  --break-guards  for each guard, switch it off alone and report how many steps break a rule
Exit 0 every rule holds · 1 a rule fails, or any walk hit the state limit · 2 bad model or usage.
Standard library only.
"""
import argparse
import importlib.util
import json
import sys
from collections import deque


def freeze(s):
    if not isinstance(s, dict):
        raise TypeError(f"a state must be a dict, got {type(s).__name__}")
    return tuple(sorted(s.items()))


def load(path):
    spec = importlib.util.spec_from_file_location("model", path)
    if spec is None or spec.loader is None:
        raise ValueError(f"cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    for name in ("init", "actions", "RULES"):
        if not hasattr(mod, name):
            raise ValueError(f"{path} defines no {name}")
    if not mod.RULES:
        raise ValueError(f"{path}: RULES is empty")
    return mod


def explore(mod, off=frozenset(), limit=1_000_000):
    """Breadth-first walk. Returns (states seen, longest path, broken or None, guards seen, capped).
    broken = (rule, path), path = [(action, state dict), ...] from a start state."""
    seen_guards = set()

    def g(name, cond):
        seen_guards.add(name)
        return True if name in off else bool(cond)

    parent, depth, queue = {}, {}, deque()
    for s in mod.init():
        k = freeze(s)
        if k not in parent:
            if len(parent) >= limit:
                return len(parent), 0, None, seen_guards, True
            parent[k], depth[k] = None, 0
            queue.append(k)
    if not parent:
        raise ValueError("init() yields no starting state")
    longest = 0
    while queue:
        k = queue.popleft()
        state = dict(k)
        for rule, ok in mod.RULES.items():
            if not ok(state):
                path, cur = [], k
                while cur is not None:
                    prev = parent[cur]
                    path.append((prev[1] if prev else "start", dict(cur)))
                    cur = prev[0] if prev else None
                return len(parent), longest, (rule, path[::-1]), seen_guards, False
        for action, nxt in mod.actions(state, g):
            nk = freeze(nxt)
            if nk not in parent:
                if len(parent) >= limit:
                    return len(parent), longest, None, seen_guards, True
                parent[nk], depth[nk] = (k, action), depth[k] + 1
                longest = max(longest, depth[nk])
                queue.append(nk)
    return len(parent), longest, None, seen_guards, False


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("model")
    p.add_argument("--break-guards", action="store_true")
    p.add_argument("--max-states", type=int, default=1_000_000)
    p.add_argument("--json", action="store_true")
    a = p.parse_args()
    if a.max_states < 1:
        print("statecheck: --max-states must be at least 1", file=sys.stderr)
        return 2
    try:
        mod = load(a.model)
        n, longest, broken, guards, capped = explore(mod, limit=a.max_states)
    except Exception as e:  # a model is user code: report, never a traceback
        print(f"statecheck: bad model: {type(e).__name__}: {e}", file=sys.stderr)
        return 2
    out = {"states": n, "steps": longest, "rules": len(mod.RULES), "capped": capped,
           "broken": None, "guards": []}
    if broken:
        rule, path = broken
        out["broken"] = {"rule": rule, "steps": len(path) - 1,
                         "path": [{"action": act, "state": st} for act, st in path]}
    if a.break_guards and not broken:
        protects = getattr(mod, "GUARDS", {}) or {}
        for name in sorted(guards | set(protects)):
            try:
                _, _, b, _, cap = explore(mod, off=frozenset([name]), limit=a.max_states)
            except Exception as e:
                print(f"statecheck: bad model with guard {name!r} off: {e}", file=sys.stderr)
                return 2
            out["guards"].append({"guard": name, "protects": protects.get(name),
                                  "breaks": b[0] if b else None,
                                  "steps": len(b[1]) - 1 if b else None, "capped": cap})
    if a.json:
        print(json.dumps(out, indent=2, default=str))
    else:
        if capped:
            print(f"stopped at the state limit ({a.max_states}); the model is too large to check fully")
        elif broken:
            print(f"BROKEN: {broken[0]} — after {out['broken']['steps']} step(s) "
                  f"({n} states explored)")
            for i, step in enumerate(out["broken"]["path"]):
                print(f"  {i}. {step['action']}: {step['state']}")
        else:
            print(f"checked: {n} states, {longest} steps, all {len(mod.RULES)} rules hold")
        for r in out["guards"]:
            if r["capped"]:
                print(f"  without {r['guard']}: stopped at the state limit")
            elif r["breaks"]:
                print(f"  without {r['guard']}: \"{r['breaks']}\" breaks in {r['steps']} step(s)")
            else:
                print(f"  without {r['guard']}: every rule still holds — another guard covers it, "
                      f"or this guard is dead")
    guard_capped = any(r["capped"] for r in out["guards"])
    return 1 if (broken or capped or guard_capped) else 0


if __name__ == "__main__":
    sys.exit(main())
