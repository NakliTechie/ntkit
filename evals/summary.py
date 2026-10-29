#!/usr/bin/env python3
"""Summarise evals/run.sh's runs.tsv: pass rate per case and arm, cases that flipped
between arms, and mean turns, tokens, time and cost per arm.

Usage: summary.py <runs.tsv>
"""
import csv
import sys
from collections import defaultdict

NUM = ("cost", "turns", "in", "out", "cache_read", "cache_write", "ms")


def load(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def main(path):
    rows = load(path)
    if not rows:
        print("no runs recorded")
        return 1
    arms = sorted({r["arm"] for r in rows})
    cases = sorted({r["case"] for r in rows})
    by = defaultdict(list)
    for r in rows:
        by[(r["case"], r["arm"])].append(r)

    def rate(c, a):
        rs = by[(c, a)]
        return sum(int(r["pass"]) for r in rs), len(rs)

    print("pass rate per case: " + "  ".join(f"arm {a}" for a in arms))
    for c in cases:
        cells = []
        for a in arms:
            p, n = rate(c, a)
            cells.append(f"{p}/{n}")
        print(f"  {c}: " + "  ".join(cells))

    if len(arms) == 2:
        a, b = arms
        better = [c for c in cases if rate(c, b)[0] * rate(c, a)[1] > rate(c, a)[0] * rate(c, b)[1]]
        worse = [c for c in cases if rate(c, b)[0] * rate(c, a)[1] < rate(c, a)[0] * rate(c, b)[1]]
        print(f"flipped: {len(worse)} case(s) pass less in arm {b}, {len(better)} pass more")
        for c in worse:
            print(f"  worse in {b}: {c}")
        for c in better:
            print(f"  better in {b}: {c}")
        if worse or better:
            print("read the transcripts of every flipped case before trusting the rates")

    print("mean per run: arm  pass  turns  in  out  cache_read  cache_write  seconds  cost")
    for a in arms:
        rs = [r for r in rows if r["arm"] == a]
        n = len(rs)
        m = {k: sum(float(r[k]) for r in rs) / n for k in NUM}
        p = sum(int(r["pass"]) for r in rs)
        print(f"  {a}  {p}/{n}  {m['turns']:.1f}  {m['in']:.0f}  {m['out']:.0f}  "
              f"{m['cache_read']:.0f}  {m['cache_write']:.0f}  {m['ms'] / 1000:.1f}  ${m['cost']:.2f}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__.strip(), file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
