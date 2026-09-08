#!/usr/bin/env python3
"""plancheck — does a plan/ folder's derived state agree with its records?

Mechanical only: it never calls a model, never edits a file, and never guesses.
It compares provenance tags in the derived files against the records that exist,
and `## Impact` declarations in the records against the derived items that cite them.

Contract: MEMORY.md.  Exit 0 clean · 1 divergence · 2 could not run.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

# --- what counts as what (MEMORY.md §1) ------------------------------------

DERIVED_FILES = ("pending.md", "workplan.md")
# history.md is hybrid: these sections are derived, `## Log` is a record.
HISTORY_DERIVED_SECTIONS = ("Decisions", "Dead ends")

# A record file is anything else that carries dated or streamed entries.
RECORD_GLOBS = ("*.md", "_archive/*.md", "lab/*/journal.md", "lab/*/*-leg.md")

# Bulleted or numbered: pending.md's Now section is commonly an ordered list,
# and an item that does not parse is an item whose provenance is never checked.
ITEM = re.compile(r"^\s*(?:[-*]|\d+[.)])\s+(?:\[(?P<box>[ x~])\]\s*)?(?P<text>.+?)\s*$")
FROM = re.compile(r"\[from:\s*(?P<src>[^\]]+?)\s*\]")
HEADING = re.compile(r"^##\s+(?P<name>.+?)\s*$")
SOC_ENTRY = re.compile(r"^\s*[-*]\s+(?P<ts>\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2})")
DATE = re.compile(r"(\d{4}-\d{2}-\d{2})")
IMPACT_NONE = re.compile(r"^\s*[-*]\s*none\b", re.IGNORECASE)
IMPACT_LINE = re.compile(
    r"^\s*[-*]\s+(?P<target>[^\s—-][^—]*?)\s*[—-]{1,2}\s*(?P<verb>add|status|remove|reword)\b",
    re.IGNORECASE,
)


@dataclass
class Finding:
    kind: str          # orphan | ghost | untagged
    where: str         # file:line
    detail: str

    def as_dict(self) -> dict:
        return {"kind": self.kind, "where": self.where, "detail": self.detail}


@dataclass
class Plan:
    root: Path
    records: dict[str, Path] = field(default_factory=dict)   # slug -> path
    soc_stamps: set[str] = field(default_factory=set)
    cited: dict[str, list[str]] = field(default_factory=dict)  # record slug -> where cited
    findings: list[Finding] = field(default_factory=list)
    counts: dict[str, int] = field(default_factory=lambda: {"items": 0, "tagged": 0, "records": 0})


def _derived_paths(root: Path) -> list[Path]:
    return [root / n for n in DERIVED_FILES if (root / n).exists()]


def _is_derived(path: Path, root: Path) -> bool:
    return path.name in DERIVED_FILES and path.parent == root


def _sections(text: str):
    """Yield (section_name, line_no, line) for every line, section '' before the first heading."""
    current = ""
    for i, line in enumerate(text.splitlines(), 1):
        m = HEADING.match(line)
        if m:
            current = m.group("name").strip()
            continue
        yield current, i, line


def collect_records(plan: Plan, since: str | None) -> None:
    """Every record file, by slug. Derived files are excluded."""
    seen: set[Path] = set()
    for pattern in RECORD_GLOBS:
        for path in sorted(plan.root.glob(pattern)):
            if path in seen or not path.is_file():
                continue
            seen.add(path)
            if _is_derived(path, plan.root):
                continue
            if since:
                d = DATE.search(path.name)
                if d and d.group(1) < since:
                    continue
            plan.records[path.stem] = path
            if path.name == "soc.md":
                for line in path.read_text(errors="replace").splitlines():
                    m = SOC_ENTRY.match(line)
                    if m:
                        plan.soc_stamps.add(m.group("ts").replace(" ", "T"))
    # history.md ## Log is a record even though the file is hybrid
    plan.counts["records"] = len(plan.records)


def resolves(plan: Plan, src: str) -> bool:
    """Does a [from: ...] tag point at something that exists?"""
    src = src.strip()
    if src.lower() == "hand":
        return True
    if src.lower().startswith("soc:"):
        stamp = src[4:].strip().replace(" ", "T")
        # a bare date matches any entry that day
        return any(s == stamp or s.startswith(stamp) for s in plan.soc_stamps)
    slug = src.split("#", 1)[0].strip()
    return slug in plan.records


def scan_derived(plan: Plan) -> None:
    """Provenance on every derived item: resolving, missing (orphan), or absent (untagged)."""
    targets = [(p, None) for p in _derived_paths(plan.root)]
    hist = plan.root / "history.md"
    if hist.exists():
        targets.append((hist, HISTORY_DERIVED_SECTIONS))

    for path, only_sections in targets:
        text = path.read_text(errors="replace")
        for section, lineno, line in _sections(text):
            if only_sections is not None and section not in only_sections:
                continue
            m = ITEM.match(line)
            if not m or not m.group("text").strip():
                continue
            plan.counts["items"] += 1
            where = f"{path.name}:{lineno}"
            tag = FROM.search(line)
            # A placeholder in prose (`[from: <record>]`) documents the format; it is not a
            # tag. Angle brackets never appear in a real slug, so treat it as untagged.
            if tag and ("<" in tag.group("src") or ">" in tag.group("src")):
                tag = None
            if not tag:
                plan.findings.append(
                    Finding("untagged", where, m.group("text")[:80])
                )
                continue
            plan.counts["tagged"] += 1
            src = tag.group("src")
            plan.cited.setdefault(src.split("#", 1)[0].strip(), []).append(where)
            if not resolves(plan, src):
                plan.findings.append(
                    Finding("orphan", where, f"[from: {src}] names no record in plan/")
                )


def scan_impacts(plan: Plan) -> None:
    """An `add` impact in a record with nothing in the derived files citing it is a ghost."""
    for slug, path in sorted(plan.records.items()):
        if path.name == "soc.md":          # exempt by contract (MEMORY.md §3)
            continue
        text = path.read_text(errors="replace")
        adds: list[tuple[int, str]] = []
        for section, lineno, line in _sections(text):
            if section.strip().lower() != "impact":
                continue
            if IMPACT_NONE.match(line):
                adds.clear()
                break
            m = IMPACT_LINE.match(line)
            if m and m.group("verb").lower() == "add":
                adds.append((lineno, m.group("target").strip()))
        if adds and slug not in plan.cited:
            for lineno, target in adds:
                plan.findings.append(
                    Finding(
                        "ghost",
                        f"{path.name}:{lineno}",
                        f"declares add on {target}, but no derived item cites [from: {slug}]",
                    )
                )


def run(root: Path, since: str | None) -> Plan:
    plan = Plan(root=root)
    collect_records(plan, since)
    scan_derived(plan)
    scan_impacts(plan)
    return plan


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="plancheck", description=__doc__.splitlines()[0])
    ap.add_argument("path", nargs="?", default=".", help="repo root or its plan/ folder (default: .)")
    ap.add_argument("--since", metavar="YYYY-MM-DD", help="ignore records dated before this")
    ap.add_argument("--json", action="store_true", dest="as_json", help="machine-readable output")
    args = ap.parse_args(argv)

    root = Path(args.path).expanduser().resolve()
    if root.name != "plan":
        root = root / "plan"
    if not root.is_dir():
        print(f"plancheck: no plan/ folder at {root}", file=sys.stderr)
        return 2

    plan = run(root, args.since)
    hard = [f for f in plan.findings if f.kind in ("orphan", "ghost")]
    info = [f for f in plan.findings if f.kind == "untagged"]

    if args.as_json:
        print(json.dumps({
            "plan": str(root),
            "counts": plan.counts,
            "findings": [f.as_dict() for f in plan.findings],
            "status": "divergence" if hard else "clean",
        }, indent=2))
        return 1 if hard else 0

    c = plan.counts
    if not hard:
        print(f"Replay: clean — {c['items']} derived items, {c['tagged']} tagged, {c['records']} records")
    else:
        orphans = sum(1 for f in hard if f.kind == "orphan")
        ghosts = sum(1 for f in hard if f.kind == "ghost")
        print(f"Replay: {orphans} orphan(s) / {ghosts} ghost(s)")
        for f in hard:
            print(f"  {f.kind:7} {f.where:28} {f.detail}")
    if info:
        print(f"  untagged: {len(info)} item(s) with no provenance (treated as hand-written)")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
