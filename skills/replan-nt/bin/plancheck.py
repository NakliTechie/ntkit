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
# A /research-nt run folder is one record, its report.md, named by the folder.
# _archive/ comes last: an archived copy never replaces a live record of the same name.
RECORD_GLOBS = ("*.md", "research/*.md", "research/*/report.md",
                "lab/*/journal.md", "lab/*/*-leg.md", "_archive/*.md")

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


# One line per finding kind, printed once after the list so a reader never has to open this file.
FIX = {
    "orphan": "the item's [from:] names no record. Add the record, correct the slug, or tag the item [from: hand].",
    "ghost": "a record declares an `add` impact and no derived item cites it. Add the item with [from: <record>], or change the impact line to `none`.",
    "misquote": "the quoted words are not in the named record. Quote words that appear there, or drop the quote.",
}


@dataclass
class Finding:
    kind: str          # orphan | ghost | misquote | untagged
    where: str         # file:line, or file:line,line,... for a ghost that names candidates
    detail: str
    missing: int = 1   # a ghost: how many of its add lines have no citing item

    def as_dict(self) -> dict:
        d = {"kind": self.kind, "where": self.where, "detail": self.detail}
        if self.kind == "ghost":
            d["missing"] = self.missing
        return d


@dataclass
class Plan:
    root: Path
    records: dict[str, Path] = field(default_factory=dict)   # slug -> path
    soc_stamps: set[str] = field(default_factory=set)
    # record slug -> one (where, quoted words, has an unquoted tag) per citing item
    cited: dict[str, list[tuple[str, list[str], bool]]] = field(default_factory=dict)
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
            research_run = path.name == "report.md" and path.parent.parent.name == "research"
            slug = path.parent.name if research_run else path.stem
            if since:
                d = DATE.search(slug)
                if d and d.group(1) < since:
                    continue
            if slug in plan.records and path.parent.name == "_archive":
                continue
            plan.records[slug] = path
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


def _items(text: str, only_sections):
    """Yield (line_no, first_line_text, whole_item) per bullet. An indented line that is not
    itself a bullet continues the item above it, so a wrapped tag still belongs to it."""
    item = None
    for section, lineno, line in _sections(text):
        if only_sections is not None and section not in only_sections:
            if item:
                yield item
            item = None
            continue
        m = ITEM.match(line)
        if m and m.group("text").strip():
            if item:
                yield item
            item = [lineno, m.group("text"), line]
        elif item and line[:1].isspace() and line.strip():
            item[2] += " " + line.strip()
        else:
            if item:
                yield item
            item = None
    if item:
        yield item


def scan_derived(plan: Plan, since: str | None = None) -> None:
    """Provenance on every derived item: resolving, missing (orphan), or absent (untagged)."""
    targets = [(p, None) for p in _derived_paths(plan.root)]
    hist = plan.root / "history.md"
    if hist.exists():
        targets.append((hist, HISTORY_DERIVED_SECTIONS))

    for path, only_sections in targets:
        text = path.read_text(errors="replace")
        for lineno, first, whole in _items(text, only_sections):
            where = f"{path.name}:{lineno}"
            # A placeholder in prose (`[from: <record>]`) documents the format; it is not a
            # tag. Angle brackets never appear in a real slug, so it is skipped.
            tags = [t.group("src") for t in FROM.finditer(whole)
                    if "<" not in t.group("src") and ">" not in t.group("src")]
            if since:
                # --since covers items too: one whose every tag is dated before it is out of range
                dates = [d.group(1) for d in (DATE.search(t) for t in tags) if d]
                if tags and len(dates) == len(tags) and max(dates) < since:
                    continue
            plan.counts["items"] += 1
            if not tags:
                plan.findings.append(Finding("untagged", where, first[:80]))
                continue
            plan.counts["tagged"] += 1
            cited_here: dict[str, tuple[list[str], list[bool]]] = {}   # one item answers one add per record
            for tag in tags:
                src, quote = split_tag(tag)
                slug = src.split("#", 1)[0].strip()
                quotes, unquoted = cited_here.setdefault(slug, ([], [False]))
                if quote is None or src.lower() == "hand":
                    unquoted[0] = True
                else:
                    quotes.append(quote)
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
            for slug, (quotes, unquoted) in cited_here.items():
                plan.cited.setdefault(slug, []).append((where, quotes, unquoted[0]))


def scan_impacts(plan: Plan) -> None:
    """Each `add` impact line needs its own derived item citing the record; one short is a ghost.

    A citing item that quotes words (`[from: <slug> "<words>"]`) answers the first open add
    line whose text holds those words. Items with an unquoted tag are then counted against
    the add lines left open in each target file; an add whose target names no derived file
    takes any citing item. When the count shows lines missing but cannot say which, one ghost
    names every candidate line. A quoted-only item that matches no add line answers none.
    An archived record is skipped: the reconcile pass applied its adds when it folded the
    record, and those items may since be finished and removed."""
    def group_of(target: str) -> str:
        name = target.split("/", 1)[0].strip()
        return name if name in DERIVED_FILES or name == "history.md" else ""

    def fits(group: str, cite_file: str) -> bool:
        return not group or group == cite_file

    for slug, path in sorted(plan.records.items()):
        if path.name == "soc.md":          # exempt by contract (MEMORY.md §3)
            continue
        if path.parent.name == "_archive":
            continue
        text = path.read_text(errors="replace")
        adds: list[tuple[int, str, str, str]] = []   # (line, target, add text, target group)
        for section, lineno, line in _sections(text):
            if section.strip().lower() != "impact":
                continue
            if IMPACT_NONE.match(line):
                adds.clear()
                break
            m = IMPACT_LINE.match(line)
            if m and m.group("verb").lower() == "add":
                tag = FROM.search(line)
                if tag and tag.group("src").split('"')[0].strip() != slug:
                    continue   # the add names another source; its item cites that, not this record
                target = m.group("target").strip()
                adds.append((lineno, target, line[m.end():].lstrip(" :").strip(), group_of(target)))
        if not adds:
            continue
        # Quoted citations first: each takes the first open add whose text holds its words.
        counted: list[str] = []   # the file of each unquoted citing item a quote did not place
        for where, quotes, unquoted in plan.cited.get(slug, []):
            cite_file = where.split(":", 1)[0]
            hit = next((a for a in adds if fits(a[3], cite_file)
                        and any(fold(q) in fold(a[2]) for q in quotes)), None)
            if hit:
                adds.remove(hit)
            elif unquoted:
                counted.append(cite_file)
        groups: dict[str, list[tuple[int, str, str, str]]] = {}
        for a in adds:
            groups.setdefault(a[3], []).append(a)
        # Named target files take their own items first; the open-target group takes what is left.
        for group in sorted(groups, key=lambda g: g == ""):
            lines = groups[group]
            usable = [i for i, f in enumerate(counted) if fits(group, f)][:len(lines)]
            for i in reversed(usable):
                counted.pop(i)
            missing = len(lines) - len(usable)
            if missing <= 0:
                continue
            if not usable:     # nothing cites these lines: each one is a ghost
                for lineno, target, add_text, _ in lines:
                    plan.findings.append(Finding(
                        "ghost", f"{path.name}:{lineno}",
                        f'declares add on {target} ("{add_text[:50]}"), and no derived item '
                        f"cites [from: {slug}] for it"))
                continue
            plan.findings.append(Finding(
                "ghost", f"{path.name}:" + ",".join(str(a[0]) for a in lines),
                f"{missing} of these {len(lines)} add(s) on {group or 'an unnamed target'} have no "
                f"citing item; {len(usable)} unquoted [from: {slug}] cannot say which. Quote each "
                f"add's words in its tag to pin it", missing=missing))


def run(root: Path, since: str | None) -> Plan:
    plan = Plan(root=root)
    collect_records(plan, since)
    scan_derived(plan, since)
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
        ghosts = sum(f.missing for f in hard if f.kind == "ghost")   # add lines with no item
        misquotes = sum(1 for f in hard if f.kind == "misquote")
        print(f"Replay: {orphans} orphan(s) / {ghosts} ghost(s) / {misquotes} misquote(s)")
        for f in hard:
            print(f"  {f.kind:7} {f.where:28} {f.detail}")
        for kind in sorted({f.kind for f in hard}):
            print(f"  fix {kind}: {FIX[kind]}")
    if info:
        print(f"  untagged: {len(info)} item(s) with no provenance (treated as hand-written)")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
