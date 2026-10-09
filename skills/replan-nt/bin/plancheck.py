#!/usr/bin/env python3
"""plancheck — does a plan/ folder's derived state agree with its records?

Mechanical only: it never calls a model, never edits a file, and never guesses.
It compares provenance tags in the derived files against the records that exist,
checks that a quoted tag's words really appear in the record it names, and compares
`## Impact` declarations in the records against the derived items that cite them.

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

DERIVED_FILES = ("pending.md", "workplan.md", "standing.md")   # standing.md is optional (MEMORY.md §7)
# history.md is hybrid: these sections are derived, `## Log` is a record.
HISTORY_DERIVED_SECTIONS = ("Decisions", "Dead ends")

# A record file is anything else that carries dated or streamed entries.
RECORD_GLOBS = ("*.md", "_archive/*.md", "lab/*/journal.md", "lab/*/*-leg.md")

# Bulleted or numbered: pending.md's Now section is commonly an ordered list,
# and an item that does not parse is an item whose provenance is never checked.
ITEM = re.compile(r"^\s*(?:[-*]|\d+[.)])\s+(?:\[(?P<box>[ x~])\]\s*)?(?P<text>.+?)\s*$")
FROM = re.compile(r"\[from:\s*(?P<src>[^\]]+?)\s*\]")
# A tag may carry the exact words it rests on: [from: <slug> "the words"] (MEMORY.md §4).
QUOTED = re.compile(r'^(?P<ref>.*?)\s+["\u201c](?P<quote>[^"\u201c\u201d]+)["\u201d]$')
# Characters folded away before a quote is compared: markdown emphasis and code marks.
MARKUP = re.compile(r"[*_`]+")
TYPOGRAPHY = str.maketrans({"\u2018": "'", "\u2019": "'", "\u201c": '"', "\u201d": '"',
                            "\u2013": "-", "\u2014": "-", "\u00a0": " "})
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
    kind: str          # orphan | ghost | misquote | untagged
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
    counts: dict[str, int] = field(default_factory=lambda: {"items": 0, "tagged": 0, "quoted": 0, "records": 0})


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


def split_tag(src: str) -> tuple[str, str | None]:
    """`slug "words"` -> ("slug", "words"); an unquoted tag -> (src, None)."""
    m = QUOTED.match(src.strip())
    if not m:
        return src.strip(), None
    return m.group("ref").strip(), m.group("quote")


def fold(text: str) -> str:
    """Normalise for quote comparison: typography, markup, case, whitespace."""
    text = MARKUP.sub("", text.translate(TYPOGRAPHY))
    return " ".join(text.split()).casefold()


def record_text(plan: Plan, ref: str) -> str | None:
    """The text a resolving tag points at: one soc entry, or a whole record file."""
    if ref.lower().startswith("soc:"):
        soc = plan.records.get("soc")
        if soc is None:
            return None
        stamp = ref[4:].strip().replace(" ", "T")
        lines = soc.read_text(errors="replace").splitlines()
        out: list[str] = []
        taking = False
        for line in lines:
            m = SOC_ENTRY.match(line)
            if m:
                taking = m.group("ts").replace(" ", "T").startswith(stamp)
            if taking:
                out.append(line)
        return "\n".join(out) if out else None
    path = plan.records.get(ref.split("#", 1)[0].strip())
    return path.read_text(errors="replace") if path else None


def quote_found(plan: Plan, ref: str, quote: str) -> bool:
    text = record_text(plan, ref)
    return text is not None and fold(quote) in fold(text)


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
            src, quote = split_tag(tag.group("src"))
            plan.cited.setdefault(src.split("#", 1)[0].strip(), []).append(where)
            if not resolves(plan, src):
                plan.findings.append(
                    Finding("orphan", where, f"[from: {src}] names no record in plan/")
                )
                continue
            if quote is None or src.lower() == "hand":
                continue
            plan.counts["quoted"] += 1
            if not quote_found(plan, src, quote):
                plan.findings.append(
                    Finding("misquote", where, f'"{quote[:60]}" is not in {src}')
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
    hard = [f for f in plan.findings if f.kind in ("orphan", "ghost", "misquote")]
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
        print(f"Replay: clean — {c['items']} derived items, {c['tagged']} tagged "
              f"({c['quoted']} quoted), {c['records']} records")
    else:
        orphans = sum(1 for f in hard if f.kind == "orphan")
        ghosts = sum(1 for f in hard if f.kind == "ghost")
        misquotes = sum(1 for f in hard if f.kind == "misquote")
        print(f"Replay: {orphans} orphan(s) / {ghosts} ghost(s) / {misquotes} misquote(s)")
        for f in hard:
            print(f"  {f.kind:7} {f.where:28} {f.detail}")
    if info:
        print(f"  untagged: {len(info)} item(s) with no provenance (treated as hand-written)")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
