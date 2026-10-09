#!/usr/bin/env python3
"""Blind the preregistered five research pairs, then score complete judgments.

prepare PROMPTS RESULTS OUT
  RESULTS/<sample_id>/{A,B}.md and {A,B}.metrics.json must exist.
  Metrics: agent_runs, wall_seconds, words; claims: supported/partial/unsupported counts.
  Creates OUT/judge/<sample_id>/{question.md,rubrics.json,1.md,2.md} plus a private manifest.
score OUT
  Each judge directory needs verdicts.json: {"1":[true,...],"2":[true,...]}.
  Boolean criterion verdicts are in rubric order. Never show the manifest to a judge.
"""
import argparse
import hashlib
import json
import math
import random
from pathlib import Path

IDS = {"6847465956a0f6376a605492", "6847465956a0f6376a605367", "6847465956a0f6376a6053e8",
       "6847465956a0f6376a605491", "6847465956a0f6376a6053bb"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def prepare(prompts, results, out):
    rows = json.loads(prompts.read_text())
    if len(rows) != 5 or {r["sample_id"] for r in rows} != IDS:
        raise ValueError("expected the five preregistered sample IDs")
    if out.exists():
        raise ValueError("output already exists; never reblind after seeing judgments")
    pairs = []
    # Validate all inputs before writing a partial blind set.
    for row in rows:
        sid = row["sample_id"]
        weights = [r["weight"] for r in row["rubrics"]]
        if not weights or any(not isinstance(w, (int, float)) or not math.isfinite(w) for w in weights):
            raise ValueError(f"invalid weights: {sid}")
        if sum(w for w in weights if w > 0) <= 0:
            raise ValueError(f"no positive weights: {sid}")
        pair = {"id": sid, "order": random.SystemRandom().sample(["A", "B"], 2), "metrics": {}}
        for arm in ("A", "B"):
            report = results / sid / f"{arm}.md"
            if not report.read_text().strip():
                raise ValueError(f"empty report: {report}")
            metrics = json.loads((results / sid / f"{arm}.metrics.json").read_text())
            for key in ("agent_runs", "wall_seconds", "words"):
                if type(metrics[key]) not in (int, float) or not math.isfinite(metrics[key]) or metrics[key] <= 0:
                    raise ValueError(f"missing/invalid {key}: {sid}/{arm}")
            counts = metrics["claims"]
            if set(counts) != {"supported", "partial", "unsupported"} or any(
                    type(v) is not int or v < 0 for v in counts.values()) or not sum(counts.values()):
                raise ValueError(f"invalid claim counts: {sid}/{arm}")
            pair["metrics"][arm] = metrics
        pairs.append(pair)
    for row, pair in zip(rows, pairs):
        folder = out / "judge" / pair["id"]
        folder.mkdir(parents=True)
        (folder / "question.md").write_text(row["prompt"] + "\n")
        (folder / "rubrics.json").write_text(json.dumps(row["rubrics"], indent=2) + "\n")
        pair["hashes"] = {}
        for slot, arm in enumerate(pair["order"], 1):
            target = folder / f"{slot}.md"
            target.write_bytes((results / pair["id"] / f"{arm}.md").read_bytes())
            pair["hashes"][str(slot)] = digest(target)
        pair["rubrics_hash"] = digest(folder / "rubrics.json")
    (out / "manifest.json").write_text(json.dumps({"prompts_sha256": digest(prompts), "pairs": pairs}, indent=2) + "\n")
    return {"prepared": len(pairs), "judge_root": str(out / "judge")}


def score(out):
    manifest = json.loads((out / "manifest.json").read_text())
    pairs = manifest["pairs"]
    if len(pairs) != 5 or {p["id"] for p in pairs} != IDS:
        raise ValueError("incomplete benchmark")
    scores = {"A": [], "B": []}
    support = {"A": [], "B": []}
    details = []
    for pair in pairs:
        folder = out / "judge" / pair["id"]
        if digest(folder / "rubrics.json") != pair["rubrics_hash"]:
            raise ValueError("rubrics changed after blinding")
        rubrics = json.loads((folder / "rubrics.json").read_text())
        judgments = json.loads((folder / "verdicts.json").read_text())
        if set(judgments) != {"1", "2"}:
            raise ValueError("both blind reports need judgments")
        result = {"id": pair["id"]}
        for slot, arm in enumerate(pair["order"], 1):
            if digest(folder / f"{slot}.md") != pair["hashes"][str(slot)]:
                raise ValueError("report changed after blinding")
            verdicts = judgments[str(slot)]
            if not isinstance(verdicts, list) or len(verdicts) != len(rubrics) or any(type(v) is not bool for v in verdicts):
                raise ValueError("one boolean verdict required for every criterion")
            value = sum(r["weight"] for r, v in zip(rubrics, verdicts) if v) / sum(
                r["weight"] for r in rubrics if r["weight"] > 0)
            scores[arm].append(value)
            counts = pair["metrics"][arm]["claims"]
            # Strict support rate; partial is disclosed but not counted as fully supported.
            support[arm].append(counts["supported"] / sum(counts.values()))
            result[arm] = value
        details.append(result)
    means = {a: sum(v) / 5 for a, v in scores.items()}
    rates = {a: sum(v) / 5 for a, v in support.items()}
    wins = sum(b > a for a, b in zip(scores["A"], scores["B"]))
    result = {"mean_rubric": means, "B_wins": wins, "mean_full_support": rates,
              "ship": means["B"] >= means["A"] and wins >= 3 and rates["B"] >= rates["A"],
              "pairs": details}
    (out / "score.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    prep = sub.add_parser("prepare")
    for name in ("prompts", "results", "out"):
        prep.add_argument(name, type=Path)
    sub.add_parser("score").add_argument("out", type=Path)
    args = parser.parse_args()
    try:
        result = prepare(args.prompts, args.results, args.out) if args.command == "prepare" else score(args.out)
    except (OSError, ValueError, KeyError, TypeError) as e:
        parser.exit(1, f"bench: {e}\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
