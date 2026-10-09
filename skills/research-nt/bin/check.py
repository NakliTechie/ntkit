#!/usr/bin/env python3
"""check — the /research-nt run checks. No network, no model calls, never edits a report.

  check.py spec     RUN_DIR                   validate spec.md
  check.py section  RUN_DIR UNIT              one sections/<UNIT>.md against the spec and the log
  check.py assemble RUN_DIR                   sections/<id>.md -> draft.md, in spec order
  check.py sample   RUN_DIR [--k 10] [--force]  pick linked sentences from report.md -> claims.json
  check.py gates    RUN_DIR [--without g3]    G1 G2 G2b G4 G3 over report.md -> verify.json

Exit 0 checks passed · 1 a check failed · 2 could not run (missing file, bad usage).
With --without g3, exit 0 is diagnostic only: verify.json still records verified=false.

Gates come in two tiers. Blocking: G1 provenance, G2 structure, G4 edit scope, G3 claim
support; any failure is exit 1 and state FLAGGED. Advisory: G2b census; a failure is
reported as a note and does not fail the run. All gates passing is state VERIFIED; only
advisory failures is state PASSED-WITH-NOTES (exit 0, verified=false). verify.json records
the state and the notes.

A run directory holds spec.md, sections/, fetch-log.jsonl (written only by fetch.py),
draft.md, edit-plan.md, report.md, claims.json. The spec is Markdown:

  # ResearchSpec
  ## Run settings                      optional; `- sections: 8`, `- words: 5000`,
                                       `- fetches_per_section: 15`, `- tool_rounds: 20`
  ## Global boundaries                 optional free text
  ## S1 | Main section title           `|` or `｜`; S1, S2, ... in order
  ### S1.1 | Unit title                one research and writing unit; S1.1, S1.2, ... in order
  #### What to cover                   text
  #### Research questions              one or more list items
  #### Required entities               list items, or `- none`; `Name / Alias (note) — note`
  #### Source leads                    list items: `https://... — what it may establish`, or `- none`
  #### Presentation                    optional

A required entity passes G2b when one of its names (the text before any ` (`, ` — ` or `: `,
split on ` / `) appears in its unit's text, or when the unit's section file drops it with
`Omitted: <name> — <reason>`, which assemble moves to the report's `## Not covered` list.
A name of two or more key words also passes when every key word appears in one sentence
of the unit, in any order, a plural `s`/`es` allowed: "llama.cpp HIP backend" matches
"the llama.cpp HIP and Vulkan backends". Stop words do not count as key words.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import parse_qsl, unquote, urlencode, urlsplit, urlunsplit

SETTINGS_DEFAULTS = {"sections": 8, "words": 5000, "fetches_per_section": 15, "tool_rounds": 20}
REQUIRED_BLOCKS = ("what to cover", "research questions", "required entities", "source leads")
OPTIONAL_BLOCKS = ("presentation",)
EDITING_VERBS = ("DELETE", "MERGE", "MOVE", "CROSS-REFERENCE")
VERDICTS = ("supported", "partial", "unsupported")
TRACKERS = {"fbclid", "gclid", "mc_cid", "mc_eid", "ref_src"}
NOT_COVERED = "Not covered"

HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
IDED = re.compile(r"^(S\d+(?:\.\d+)?)\s*[|｜]\s*(.+)$")
UNIT_ID = re.compile(r"^S(\d+)\.(\d+)$")
MAIN_ID = re.compile(r"^S(\d+)$")
UNIT_REF = re.compile(r"\bS\d+\.\d+\b")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+(.*\S)\s*$")
OMITTED = re.compile(r"^\s*Omitted:\s*(.+?)(?:\s+(?:—|–|-{1,2})\s+|:\s+)(.+?)\s*$")
NOT_COVERED_ITEM = re.compile(r"^- (S\d+\.\d+) · (.+?): (.+)$")
MD_LINK = re.compile(r"\]\((https?://(?:[^()\s]|\([^()\s]*\))+)(?:\s+\"[^\"]*\")?\)")
AUTO_LINK = re.compile(r"<(https?://[^>\s]+)>")
BARE_URL = re.compile(r"https?://[^\s<>\[\]\"'`]+")
CODE_SPAN = re.compile(r"`[^`]*`")
FENCE = re.compile(r"^\s*(```|~~~)")


class CannotRun(Exception):
    """A required input is missing or unreadable: exit 2."""


# --- URLs -------------------------------------------------------------------

def normalize_url(url: str) -> str:
    """Lower-case scheme and host, drop default port, fragment, trailing slash and trackers."""
    try:
        p = urlsplit(url.strip())
        scheme, host, port = p.scheme.lower(), (p.hostname or "").lower(), p.port
    except ValueError:
        return url.strip()
    netloc = host
    if port and not ((scheme == "http" and port == 80) or (scheme == "https" and port == 443)):
        netloc = f"{host}:{port}"
    path = unquote(p.path) or "/"
    if len(path) > 1:
        path = path.rstrip("/") or "/"
    query = [(k, v) for k, v in parse_qsl(p.query, keep_blank_values=True)
             if not (k.lower().startswith("utm_") or k.lower() in TRACKERS)]
    return urlunsplit((scheme, netloc, path, urlencode(query), ""))


def prose_lines(lines: list[str]):
    """Yield (index, line) outside fenced code, with inline code spans blanked."""
    in_fence = False
    for i, line in enumerate(lines):
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield i, CODE_SPAN.sub(" ", line)


def trim_bare(url: str) -> str:
    """A bare URL ends before trailing punctuation and any unbalanced closing parenthesis."""
    while True:
        before = url
        url = url.rstrip(".,;:!?*_")
        if url.endswith(")") and url.count("(") < url.count(")"):
            url = url[:-1]
        if url == before:
            return url


def links_in(text: str) -> list[str]:
    """Every http(s) link in prose, in order; code blocks and code spans are not citations."""
    found = []
    for _, line in prose_lines(text.splitlines()):
        for rx in (MD_LINK, AUTO_LINK):
            found += rx.findall(line)
            line = rx.sub(" ", line)
        found += [trim_bare(u) for u in BARE_URL.findall(line)]
    return found


# --- spec -------------------------------------------------------------------

@dataclass
class Unit:
    id: str
    title: str
    line: int
    blocks: dict[str, list[str]] = field(default_factory=dict)

    def items(self, block: str) -> list[str]:
        return [m.group(1) for m in map(LIST_ITEM.match, self.blocks.get(block, [])) if m]

    def entities(self) -> list[str]:
        return [e for e in self.items("required entities") if e.strip().lower() != "none"]


@dataclass
class Spec:
    settings: dict[str, int]
    mains: list[tuple[str, str]]
    units: list[Unit]
    errors: list[str]


def parse_settings(lines: list[str], errors: list[str]) -> dict[str, int]:
    settings = dict(SETTINGS_DEFAULTS)
    for line in lines:
        m = LIST_ITEM.match(line)
        if not m:
            continue
        key, _, value = m.group(1).partition(":")
        key = key.strip().lower().replace(" ", "_")
        if key not in SETTINGS_DEFAULTS:
            errors.append(f"run settings: unknown key '{key}'")
        elif not value.strip().isdigit() or int(value) < 1:
            errors.append(f"run settings: '{key}' must be a positive whole number")
        else:
            settings[key] = int(value)
    return settings


def parse_spec(text: str) -> Spec:
    errors: list[str] = []
    lines = text.splitlines()
    sections: list[tuple[int, str, int]] = []   # (level, heading text, line index)
    in_fence = False
    for i, line in enumerate(lines):
        if FENCE.match(line):
            in_fence = not in_fence
        elif not in_fence and (m := HEADING.match(line)):
            sections.append((len(m.group(1)), m.group(2), i))
    if not sections or sections[0][:2] != (1, "ResearchSpec"):
        errors.append("line 1: the spec must start with '# ResearchSpec'")

    settings_lines: list[str] = []
    mains: list[tuple[str, str]] = []
    units: list[Unit] = []
    unit: Unit | None = None
    block: str | None = None
    mode = None   # "settings" | "boundaries" | "main" | "unit"
    ends = [s[2] for s in sections[1:]] + [len(lines)]
    for (level, heading, start), end in zip(sections, ends):
        body = lines[start + 1:end]
        where = f"line {start + 1}"
        if level == 1:
            continue
        if level == 2:
            unit, block = None, None
            name = heading.strip().lower()
            if name in ("run settings", "global boundaries"):
                if mains:
                    errors.append(f"{where}: '## {heading}' must come before S1")
                mode = "settings" if name == "run settings" else "boundaries"
                if mode == "settings":
                    settings_lines = body
                continue
            m = IDED.match(heading)
            if not m or not MAIN_ID.match(m.group(1)):
                errors.append(f"{where}: '## {heading}' is not '## S<n> | Title'")
                mode = None
                continue
            want = f"S{len(mains) + 1}"
            if m.group(1) != want:
                errors.append(f"{where}: main section {m.group(1)} out of order; expected {want}")
            mains.append((m.group(1), m.group(2).strip()))
            mode = "main"
        elif level == 3:
            block = None
            m = IDED.match(heading)
            if not mains:
                errors.append(f"{where}: unit before any '## S<n>' main section")
                continue
            if not m or not UNIT_ID.match(m.group(1)):
                errors.append(f"{where}: '### {heading}' is not '### S<n>.<m> | Title'")
                unit = None
                continue
            main_n, unit_n = UNIT_ID.match(m.group(1)).groups()
            parent = mains[-1][0]
            siblings = [u for u in units if u.id.split(".")[0] == parent]
            want = f"{parent}.{len(siblings) + 1}"
            if f"S{main_n}" != parent:
                errors.append(f"{where}: {m.group(1)} sits under {parent}")
            elif m.group(1) != want:
                errors.append(f"{where}: unit {m.group(1)} out of order; expected {want}")
            if any(u.id == m.group(1) for u in units):
                errors.append(f"{where}: duplicate unit id {m.group(1)}")
            unit = Unit(m.group(1), m.group(2).strip(), start + 1)
            units.append(unit)
            mode = "unit"
        elif level == 4 and mode == "unit" and unit is not None:
            block = heading.strip().lower()
            if block not in REQUIRED_BLOCKS + OPTIONAL_BLOCKS:
                errors.append(f"{where}: unknown block '#### {heading}' in {unit.id}")
            elif block in unit.blocks:
                errors.append(f"{where}: {unit.id} repeats '#### {heading}'")
            unit.blocks[block] = body
            continue
        if level >= 4 and mode == "unit" and unit is not None and block:
            unit.blocks[block] = unit.blocks[block] + [lines[start]] + body

    settings = parse_settings(settings_lines, errors)
    for u in units:
        where = f"{u.id} (line {u.line})"
        missing = [b for b in REQUIRED_BLOCKS if b not in u.blocks]
        if missing:
            errors.append(f"{where}: missing block(s) " + ", ".join(f"'{b}'" for b in missing))
            continue
        if not any(line.strip() for line in u.blocks["what to cover"]):
            errors.append(f"{where}: 'What to cover' is empty")
        if not u.items("research questions"):
            errors.append(f"{where}: no research questions")
        if not u.items("required entities"):
            errors.append(f"{where}: 'Required entities' needs items or '- none'")
        leads = u.items("source leads")
        if not leads:
            errors.append(f"{where}: 'Source leads' needs items or '- none'")
        for lead in leads:
            if lead.strip().lower() != "none" and not lead.startswith(("http://", "https://")):
                errors.append(f"{where}: source lead does not start with a URL: '{lead[:60]}'")
    for main_id, _ in mains:
        if not any(u.id.split(".")[0] == main_id for u in units):
            errors.append(f"{main_id}: main section has no units")
    if not units:
        errors.append("the spec has no units")
    if len(units) > settings["sections"]:
        errors.append(f"{len(units)} units exceed the section cap of {settings['sections']}")
    return Spec(settings, mains, units, errors)


def entity_names(entity: str) -> list[str]:
    name = re.split(r"\s+(?:—|–|--)\s+|:\s+", entity, maxsplit=1)[0]
    name = re.sub(r"\s*\([^)]*\)\s*$", "", name).strip()
    return [n.strip() for n in name.split(" / ") if n.strip()]


def fold(text: str) -> str:
    """Case-, quote-, emphasis- and whitespace-insensitive form for matching names."""
    text = text.replace("’", "'").replace("‘", "'").replace("“", '"').replace("”", '"')
    text = re.sub(r"[*_`]", "", text).replace("&", " and ")
    return re.sub(r"\s+", " ", text).strip().casefold()


STOP_WORDS = {"a", "an", "and", "the", "of", "for", "to", "in", "on", "with", "by", "or"}
WORD = re.compile(r"[\w][\w.+#-]*")


def key_words(folded: str) -> list[str]:
    return [w.rstrip(".") for w in WORD.findall(folded) if w.rstrip(".") not in STOP_WORDS]


def words_together(names: list[str], text: str) -> bool:
    """Every key word of a multi-word name in one sentence, any order, plural allowed."""
    for sentence in re.split(r"(?<=[.!?])\s+", text):
        have = set(key_words(sentence))
        for name in names:
            need = key_words(name)
            if len(need) >= 2 and all(w in have or w + "s" in have or w + "es" in have for w in need):
                return True
    return False


def entity_covered(entity: str, text: str, dropped: list[tuple[str, str]]) -> bool:
    """Named in the folded unit text (exactly, or as co-occurring key words), or dropped with a reason."""
    names = [fold(n) for n in entity_names(entity)]
    if any(n and n in text for n in names) or words_together(names, text):
        return True
    return any(reason and any(n and n in what for n in names) for what, reason in dropped)


# --- report -----------------------------------------------------------------

@dataclass
class Part:
    key: str          # "preamble", "S1" (main intro), "S1.1", "not-covered", or "?<heading>"
    heading: str
    lines: list[str]


def parse_report(text: str) -> list[Part]:
    parts = [Part("preamble", "", [])]
    in_fence = False
    for line in text.splitlines():
        if FENCE.match(line):
            in_fence = not in_fence
        m = None if in_fence else HEADING.match(line)
        if m and len(m.group(1)) in (2, 3):
            title = m.group(2)
            ided = IDED.match(title)
            if ided:
                key = ided.group(1)
            elif len(m.group(1)) == 2 and title.strip().lower() == NOT_COVERED.lower():
                key = "not-covered"
            else:
                key = "?" + title
            parts.append(Part(key, line, []))
        else:
            parts[-1].lines.append(line)
    return parts


def body_text(part: Part) -> str:
    return "\n".join(part.lines).strip("\n")


# --- run directory ----------------------------------------------------------

def read(run: Path, name: str) -> str:
    path = run / name
    if not path.is_file():
        raise CannotRun(f"{path} not found")
    return path.read_text(encoding="utf-8")


def load_spec(run: Path) -> Spec:
    return parse_spec(read(run, "spec.md"))


def load_log(run: Path) -> tuple[list[dict], list[str]]:
    path = run / "fetch-log.jsonl"
    if not path.is_file():
        return [], []
    entries, bad = [], []
    for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not line.strip():
            continue
        try:
            entries.append(json.loads(line))
        except json.JSONDecodeError:
            bad.append(f"fetch-log.jsonl line {n} is not JSON")
    return entries, bad


def fetched_ok(entries: list[dict]) -> dict[str, dict]:
    ok = {}
    for e in entries:
        if e.get("status") == "ok":
            for u in (e.get("url"), e.get("final_url")):
                if u:
                    ok[normalize_url(u)] = e
    return ok


def provenance(entries: list[dict]):
    """A function naming why a cited URL is not evidence, or None when a fetch succeeded."""
    ok = fetched_ok(entries)
    failed = {normalize_url(e["url"]): e.get("error") or e.get("status")
              for e in entries if e.get("status") != "ok" and e.get("url")}

    def why_not(url: str) -> str | None:
        key = normalize_url(url)
        if key in ok:
            return None
        return f"fetch failed ({failed[key]})" if key in failed else "never fetched"
    return why_not


def read_section(run: Path, u: Unit) -> tuple[list[str], list[tuple[str, str]], list[str]]:
    """sections/<id>.md as (body lines, Omitted (name, reason) pairs, format problems)."""
    path = run / "sections" / f"{u.id}.md"
    if not path.is_file():
        return [], [], [f"{u.id}: sections/{u.id}.md not found"]
    lines = path.read_text(encoding="utf-8").splitlines()
    first = next((i for i, ln in enumerate(lines) if ln.strip()), None)
    head = HEADING.match(lines[first]) if first is not None else None
    ided = IDED.match(head.group(2)) if head else None
    if not head or len(head.group(1)) != 3 or not ided or ided.group(1) != u.id:
        return [], [], [f"{u.id}: the file must open with '### {u.id} | <title>'"]
    body, omitted, problems = [], [], []
    in_fence = False
    for n, line in enumerate(lines[first + 1:], first + 2):
        if FENCE.match(line):
            in_fence = not in_fence
        h = None if in_fence else HEADING.match(line)
        if h and len(h.group(1)) <= 3:
            problems.append(f"{u.id}: line {n} adds a heading above level 4 ('{line.strip()[:50]}')")
            continue
        om = None if in_fence else OMITTED.match(line)
        if om:
            omitted.append((om.group(1).strip(), om.group(2).strip()))
        elif not in_fence and line.strip().startswith("Omitted:"):
            problems.append(f"{u.id}: line {n} 'Omitted:' needs '<name> — <reason>'")
        else:
            body.append(line)
    while body and not body[-1].strip():
        body.pop()
    while body and not body[0].strip():
        body.pop(0)
    return body, omitted, problems


# --- commands ---------------------------------------------------------------

def cmd_spec(run: Path, _args) -> int:
    spec = load_spec(run)
    if spec.errors:
        print(f"spec INVALID: {len(spec.errors)} problem(s)")
        for e in spec.errors:
            print(f"  - {e}")
        return 1
    questions = sum(len(u.items("research questions")) for u in spec.units)
    entities = sum(len(u.entities()) for u in spec.units)
    print(f"spec ok: {len(spec.mains)} main sections, {len(spec.units)} units, "
          f"{questions} research questions, {entities} required entities")
    print("settings: " + ", ".join(f"{k} {v}" for k, v in spec.settings.items()))
    return 0


def cmd_section(run: Path, args) -> int:
    spec = load_spec(run)
    if spec.errors:
        print("cannot check: spec.md is invalid; run `check.py spec` for the list")
        return 1
    unit = next((u for u in spec.units if u.id == args.unit), None)
    if unit is None:
        raise CannotRun(f"no unit {args.unit} in spec.md")
    body, dropped, problems = read_section(run, unit)
    text = "\n".join(body)
    why_not = provenance(load_log(run)[0])
    links = links_in(text)
    for url in links:
        why = why_not(url)
        if why:
            problems.append(f"{unit.id}: {url} — {why}")
    folded = fold(text)
    dropped_folded = [(fold(name), reason) for name, reason in dropped]
    entities = unit.entities()
    for entity in entities:
        if not entity_covered(entity, folded, dropped_folded):
            problems.append(f"{unit.id}: required entity '{entity}' is neither named in the text "
                            f"nor dropped with 'Omitted: <name> — <reason>'")
    ids = {u.id for u in spec.units}
    for _, line in prose_lines(body):
        for ref in UNIT_REF.findall(line):
            if ref not in ids:
                problems.append(f"{unit.id}: refers to {ref}, which is not a section")
    words = sum(len(line.split()) for _, line in prose_lines(body))
    target = spec.settings["words"] // len(spec.units)
    if problems:
        print(f"section {unit.id} FAIL: {len(problems)} problem(s)")
        for p in problems:
            print(f"  - {p}")
        return 1
    print(f"section {unit.id} ok: {len(links)} links, all fetched; {len(entities)} required entities, "
          f"{len(dropped)} omitted; {words} words (target about {target})")
    return 0


def cmd_assemble(run: Path, _args) -> int:
    spec = load_spec(run)
    if spec.errors:
        print("cannot assemble: spec.md is invalid; run `check.py spec` for the list")
        return 1
    question_path = run / "question.md"
    title = "Research report"
    if question_path.is_file():
        first = next((ln.strip() for ln in question_path.read_text(encoding="utf-8").splitlines()
                      if ln.strip()), "")
        title = first.lstrip("# ").strip() or title
    problems, omitted = [], []
    out = [f"# {title}", ""]
    mains = dict(spec.mains)
    current_main = None
    for u in spec.units:
        main_id = u.id.split(".")[0]
        if main_id != current_main:
            current_main = main_id
            out += [f"## {main_id} | {mains[main_id]}", ""]
        body, dropped, found = read_section(run, u)
        problems += found
        omitted += [f"- {u.id} · {name}: {reason}" for name, reason in dropped]
        out += [f"### {u.id} | {u.title}", ""] + body + [""]
    out += [f"## {NOT_COVERED}", ""] + (omitted or ["- none"]) + [""]
    if problems:
        print(f"cannot assemble: {len(problems)} problem(s)")
        for p in problems:
            print(f"  - {p}")
        return 1
    (run / "draft.md").write_text("\n".join(out), encoding="utf-8")
    print(f"assembled draft.md: {len(spec.units)} units, {len(omitted)} omitted entit"
          f"{'y' if len(omitted) == 1 else 'ies'}")
    return 0


def split_sentences(para: str) -> list[str]:
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+(?=[A-Z0-9\"“‘(\[*_])", para) if s.strip()]


def linked_sentences(part: Part) -> list[str]:
    out, para = [], []

    def flush():
        if para:
            out.extend(s for s in split_sentences(" ".join(para)) if links_in(s))
            para.clear()

    in_fence = False
    for line in part.lines:
        if FENCE.match(line):
            flush()
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        stripped = line.strip()
        if not stripped or HEADING.match(line):
            flush()
        elif stripped.startswith("|") or LIST_ITEM.match(line):
            flush()
            if links_in(stripped):
                out.append(stripped)
        else:
            para.append(stripped)
    flush()
    return out


def sample_claims(run: Path, report: str, k: int = 10) -> tuple[list[dict], int]:
    """Reconstruct the slug-seeded sample; judges may change only verdict and note."""
    seed = hashlib.sha256(run.resolve().name.encode()).hexdigest()
    ok = fetched_ok(load_log(run)[0])
    candidates = [(p.key, s) for p in parse_report(report) if UNIT_ID.match(p.key)
                  for s in linked_sentences(p)]
    candidates.sort(key=lambda c: hashlib.sha256(f"{seed}|{c[0]}|{c[1]}".encode()).hexdigest())
    claims = []
    for n, (unit, sentence) in enumerate(candidates[:k], 1):
        urls = links_in(sentence)
        pages = sorted({ok[normalize_url(u)]["path"] for u in urls
                        if normalize_url(u) in ok and ok[normalize_url(u)].get("path")})
        evidence = [{"url": u, "path": ok.get(normalize_url(u), {}).get("path"),
                     "sha256": ok.get(normalize_url(u), {}).get("text_sha256")}
                    for u in urls]
        claims.append({"id": f"C{n}", "section": unit, "sentence": sentence, "urls": urls,
                       "pages": pages, "evidence": evidence, "verdict": None, "note": None})
    return claims, len(candidates)


def cmd_sample(run: Path, args) -> int:
    report = read(run, "report.md")
    target = run / "claims.json"
    if target.exists() and not args.force:
        print("claims.json exists; it may hold verdicts. Pass --force to re-sample.")
        return 1
    if args.k < 1:
        raise CannotRun("--k must be positive")
    claims, count = sample_claims(run, report, args.k)
    target.write_text(json.dumps(claims, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    (run / "claims-meta.json").write_text(json.dumps({
        "report_sha256": hashlib.sha256(report.encode()).hexdigest(), "k": args.k,
    }, indent=1) + "\n", encoding="utf-8")
    print(f"sampled {len(claims)} of {count} linked sentences -> claims.json")
    return 0


def unit_of(parts: list[Part], line_no: int) -> str:
    seen = 0
    for p in parts:
        span = 1 + len(p.lines) if p.heading else len(p.lines)
        if line_no < seen + span:
            return p.key
        seen += span
    return "?"


def gate_g1(run: Path, report: str) -> list[str]:
    entries, bad = load_log(run)
    why_not = provenance(entries)
    problems = list(bad)
    parts = parse_report(report)
    lines = report.splitlines()
    for i, line in prose_lines(lines):
        for url in links_in(line):
            why = why_not(url)
            if why:
                problems.append(f"{unit_of(parts, i)}: {url} — {why}")
    return problems


def gate_g2(spec: Spec, report: str) -> list[str]:
    parts = parse_report(report)
    expected = []
    for main_id, _ in spec.mains:
        expected.append(main_id)
        expected += [u.id for u in spec.units if u.id.split(".")[0] == main_id]
    expected.append("not-covered")
    got = [p.key for p in parts[1:]]
    problems = []
    for key in got:
        if key.startswith("?"):
            problems.append(f"unexpected heading '{key[1:]}'")
    ided = [k for k in got if not k.startswith("?")]
    for key in expected:
        count = ided.count(key)
        label = NOT_COVERED if key == "not-covered" else key
        if count == 0:
            problems.append(f"{label}: missing")
        elif count > 1:
            problems.append(f"{label}: appears {count} times")
    for key in ided:
        if key not in expected:
            problems.append(f"{key}: not in the spec")
    present = [k for k in ided if k in expected]
    if not problems and present != expected:
        problems.append("sections out of spec order: " + " ".join(present))
    unit_ids = {u.id for u in spec.units}
    for p in parts:
        for _, line in prose_lines(p.lines):
            for ref in UNIT_REF.findall(line):
                if ref not in unit_ids:
                    problems.append(f"{p.key}: refers to {ref}, which is not a section")
    return problems


def gate_g2b(spec: Spec, report: str) -> list[str]:
    parts = {p.key: p for p in parse_report(report)}
    dropped: dict[str, list[tuple[str, str]]] = {}
    if "not-covered" in parts:
        for line in parts["not-covered"].lines:
            m = NOT_COVERED_ITEM.match(line.strip())
            if m:
                dropped.setdefault(m.group(1), []).append((fold(m.group(2)), m.group(3).strip()))
    problems = []
    for u in spec.units:
        text = fold(body_text(parts[u.id])) if u.id in parts else ""
        for entity in u.entities():
            if not entity_covered(entity, text, dropped.get(u.id, [])):
                problems.append(f"{u.id}: required entity '{entity}' is neither in the section nor in '{NOT_COVERED}'")
    return problems


def parse_edit_plan(text: str) -> tuple[set[str], set[str]]:
    """Units the plan lets the editor change, and the URLs its DELETE lines name."""
    allowed, deletes = set(), set()
    current = None
    for line in text.splitlines():
        h = HEADING.match(line)
        if h:
            m = re.match(r"^(S\d+(?:\.\d+)?)\b", h.group(2).strip())
            current = m.group(1) if m else ("not-covered" if h.group(2).strip() == NOT_COVERED else None)
            continue
        item = LIST_ITEM.match(line)
        if not item or current is None:
            continue
        vm = re.match(r"^\**\s*([A-Za-z-]+)\s*\**\s*:", item.group(1))
        verb = vm.group(1).upper() if vm else ""
        if verb not in EDITING_VERBS:
            continue
        allowed.add(current)
        if verb in ("MOVE", "MERGE"):
            allowed.update(re.findall(r"\bS\d+(?:\.\d+)?\b", item.group(1)))
        if verb == "DELETE":
            deletes.update(normalize_url(u) for u in links_in(item.group(1)))
    return allowed, deletes


def gate_g4(run: Path, report: str) -> list[str]:
    draft_path, plan_path = run / "draft.md", run / "edit-plan.md"
    if not draft_path.is_file():
        return ["draft.md not found; the report has no draft to compare against"]
    draft = draft_path.read_text(encoding="utf-8")
    if not plan_path.is_file():
        return [] if draft == report else ["report.md differs from draft.md and there is no edit-plan.md"]
    allowed, deletes = parse_edit_plan(plan_path.read_text(encoding="utf-8"))
    before = {p.key: p.heading + "\n" + body_text(p) for p in parse_report(draft)}
    after = {p.key: p.heading + "\n" + body_text(p) for p in parse_report(report)}
    problems = []
    for key in sorted(set(before) | set(after)):
        if before.get(key) == after.get(key):
            continue
        label = {"preamble": "the title block", "not-covered": NOT_COVERED}.get(key, key)
        if key not in allowed:
            problems.append(f"{label}: changed, but edit-plan.md has no DELETE/MERGE/MOVE/CROSS-REFERENCE for it")
    draft_urls = {normalize_url(u) for u in links_in(draft)}
    report_urls = {normalize_url(u) for u in links_in(report)}
    for url in sorted(draft_urls - report_urls - deletes):
        problems.append(f"{url}: removed without a DELETE directive")
    for url in sorted(report_urls - draft_urls):
        problems.append(f"{url}: added by the editor; the editor may not add sources")
    return problems


def gate_g3(run: Path, report: str) -> list[str]:
    path = run / "claims.json"
    if not path.is_file():
        return ["claim check not run (no claims.json)"]
    try:
        claims = json.loads(path.read_text(encoding="utf-8"))
        meta = json.loads((run / "claims-meta.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        return [f"claim sample unreadable: {e}"]
    if not isinstance(claims, list) or not claims or any(not isinstance(c, dict) for c in claims):
        return ["claims.json must hold a non-empty list of claim objects"]
    if not isinstance(meta, dict) or meta.get("k") != 10:
        return ["G3 requires the default sample of 10 (or every linked sentence when fewer exist)"]
    if meta.get("report_sha256") != hashlib.sha256(report.encode()).hexdigest():
        return ["claim sample is stale: report.md changed; sample and judge it again"]
    expected, _ = sample_claims(run, report)
    fields = ("id", "section", "sentence", "urls", "pages", "evidence")
    if [{k: c.get(k) for k in fields} for c in claims] != [
            {k: c[k] for k in fields} for c in expected]:
        return ["claims.json does not match the complete deterministic sample; sample and judge it again"]
    problems = []
    checked = set()
    for c in claims:
        cid = c["id"]
        for e in c["evidence"]:
            key = (e["path"], e["sha256"])
            if key in checked:
                continue
            checked.add(key)
            try:
                digest = hashlib.sha256(Path(e["path"]).read_bytes()).hexdigest() if e["path"] else None
            except OSError:
                digest = None
            if not digest or not e["sha256"] or digest != e["sha256"]:
                problems.append(f"{cid}: missing or changed page text for {e['url']}")
        if c.get("verdict") not in VERDICTS:
            problems.append(f"{cid}: no verdict (want one of {', '.join(VERDICTS)})")
        elif not isinstance(c.get("note"), str) or not c["note"].strip():
            problems.append(f"{cid}: verdict needs an evidence note")
        elif c["verdict"] == "unsupported":
            problems.append(f"{cid} ({c['section']}): unsupported — {c['note']}")
    snapshots = (run / "claims-before-repair.json", run / "report-before-repair.md")
    if any(p.exists() for p in snapshots):
        try:
            old = json.loads(snapshots[0].read_text(encoding="utf-8"))
            review = json.loads((run / "repair-review.json").read_text(encoding="utf-8"))
            failed = [c for c in old if c["verdict"] == "unsupported"]
            results = review["claims"]
            if (review["report_sha256"] != hashlib.sha256(report.encode()).hexdigest()
                    or not snapshots[1].is_file()
                    or not isinstance(results, list)
                    or [c["id"] for c in results] != [c["id"] for c in failed]):
                raise ValueError("stale or incomplete repair review")
            for prior, result in zip(failed, results):
                verdict = result.get("verdict")
                if verdict not in ("removed", "supported", "partial") or not result.get("note"):
                    problems.append(f"{prior['id']}: repair remains unsupported or has no evidence note")
                if verdict == "removed" and prior["sentence"] in report:
                    problems.append(f"{prior['id']}: repair says removed but the sentence remains")
        except (OSError, ValueError, TypeError, KeyError) as e:
            problems.append(f"repair review missing or invalid: {e}")

    return problems


def cited_sources(run: Path, report: str) -> list[dict]:
    """Every URL the report cites, most-cited first, ties in order of first citation."""
    ok = fetched_ok(load_log(run)[0])
    counts: dict[str, int] = {}
    shown: dict[str, str] = {}
    for url in links_in(report):
        key = normalize_url(url)
        counts[key] = counts.get(key, 0) + 1
        shown.setdefault(key, url)
    order = sorted(counts, key=lambda k: -counts[k])   # stable: ties keep first-citation order
    return [{"url": shown[k], "cited": counts[k], "title": (ok.get(k) or {}).get("title") or ""}
            for k in order]


def cmd_gates(run: Path, args) -> int:
    report = read(run, "report.md")
    spec = load_spec(run)
    if spec.errors:
        print("cannot check: spec.md is invalid; run `check.py spec` for the list")
        return 1
    without = {w.strip().lower() for w in (args.without or "").split(",") if w.strip()}
    unknown = without - {"g3"}
    if unknown:
        raise CannotRun(f"--without accepts only g3, not {', '.join(sorted(unknown))}")
    gates = [   # (id, name, function, blocking)
        ("G1", "provenance", lambda: gate_g1(run, report), True),
        ("G2", "structure", lambda: gate_g2(spec, report), True),
        ("G2b", "census", lambda: gate_g2b(spec, report), False),
        ("G4", "edit scope", lambda: gate_g4(run, report), True),
        ("G3", "claim support", lambda: gate_g3(run, report), True),
    ]
    results, failed, notes = {}, 0, []
    for gid, name, fn, blocking in gates:
        tier = "blocking" if blocking else "advisory"
        if gid.lower() in without:
            results[gid] = {"name": name, "tier": tier, "pass": None, "problems": ["skipped by --without"]}
            print(f"{gid:<4} {name:<14} SKIPPED (--without {gid.lower()})")
            continue
        problems = fn()
        results[gid] = {"name": name, "tier": tier, "pass": not problems, "problems": problems}
        verdict = "PASS" if not problems else ("FAIL" if blocking else "NOTE (advisory)")
        print(f"{gid:<4} {name:<14} {verdict}")
        for p in problems:
            print(f"       - {p}")
        if problems and blocking:
            failed += 1
        elif problems:
            notes.append(gid)
    if failed:
        state = "FLAGGED"
    elif without:
        state = "CHECKED"
    else:
        state = "PASSED-WITH-NOTES" if notes else "VERIFIED"
    (run / "verify.json").write_text(json.dumps({
        "run": run.resolve().name,
        "checked_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "gates": results, "without": sorted(without), "state": state,
        "verified": state == "VERIFIED", "notes": notes,
        "sources": cited_sources(run, report),
    }, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    advisory = f"; advisory notes: {', '.join(notes)}" if notes else ""
    if failed:
        print(f"NOT VERIFIED: {failed} blocking gate(s) failed{advisory}")
    elif without:
        print(f"CHECKED (G3 skipped by --without; not VERIFIED{advisory})")
    elif notes:
        print(f"PASSED-WITH-NOTES: blocking gates pass{advisory}; not VERIFIED")
    else:
        print("VERIFIED")
    return 1 if failed else 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="check", description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name in ("spec", "section", "assemble", "sample", "gates"):
        p = sub.add_parser(name)
        p.add_argument("run", type=Path, help="the run directory, plan/research/<slug>")
        if name == "section":
            p.add_argument("unit", help="the unit id, e.g. S1.2")
        if name == "sample":
            p.add_argument("--k", type=int, default=10, help="claims to sample (default 10)")
            p.add_argument("--force", action="store_true", help="overwrite an existing claims.json")
        if name == "gates":
            p.add_argument("--without", help="skip a gate; only 'g3' is accepted")
    args = ap.parse_args(argv)
    if not args.run.is_dir():
        print(f"check: run directory {args.run} not found", file=sys.stderr)
        return 2
    try:
        return {"spec": cmd_spec, "section": cmd_section, "assemble": cmd_assemble,
                "sample": cmd_sample, "gates": cmd_gates}[args.cmd](args.run, args)
    except CannotRun as e:
        print(f"check: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
