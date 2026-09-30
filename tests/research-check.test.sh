#!/bin/sh
# research-nt check.py: spec validation, assembly, and every gate passing and failing on a small
# run directory. No network, no model calls. Contract: skills/research-nt/bin/check.py docstring.
set -eu
command -v python3 >/dev/null || { echo "python3 not found"; exit 77; }
BIN=$(cd "$(dirname "$0")/.." && pwd)/skills/research-nt/bin
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
PYTHONDONTWRITEBYTECODE=1 BIN="$BIN" WORK="$work" python3 - <<'PY'
import contextlib, io, json, os, shutil, sys
from pathlib import Path
sys.path.insert(0, os.environ["BIN"])
import check

work = Path(os.environ["WORK"])
failures = []

def run(*argv):
    out = io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
        rc = check.main([str(a) for a in argv])
    return rc, out.getvalue()

def expect(desc, got, want_rc, want_text=""):
    rc, out = got
    if rc != want_rc or want_text not in out:
        failures.append(f"{desc}: exit {rc} (wanted {want_rc}), wanted text {want_text!r}\n{out}")

SPEC = """# ResearchSpec

## Run settings
- sections: 4
- fetches_per_section: 5

## Global boundaries
Sources up to 2024.

## S1 | Classical theory

### S1.1 | Mean-variance portfolios
#### What to cover
Markowitz and the efficient frontier.
#### Research questions
- What did Markowitz (1952) show?
#### Required entities
- Harry Markowitz (1952)
- Efficient frontier / frontier of efficient portfolios
#### Source leads
- https://example.org/markowitz — the original paper

### S1.2 | CAPM
#### What to cover
The capital asset pricing model.
#### Research questions
1. Who originated CAPM?
#### Required entities
- Security Market Line (SML)
- Treynor (1962)
#### Source leads
- none

## S2 | Machine learning

### S2.1 | Learned portfolios
#### What to cover
Learning weights from data.
#### Research questions
- How does deep portfolio theory differ from predict-then-optimise?
#### Required entities
- Heaton, Polson & Witte (2017) — Deep Portfolio Theory
#### Source leads
- https://arxiv.org/abs/1605.07230 — the paper
#### Presentation
A short comparison table.
"""

SECTIONS = {
    "S1.1": """### S1.1 | Mean-variance portfolios

Harry Markowitz showed that diversification lowers variance ([Markowitz 1952](https://example.org/markowitz?utm_source=x)). The efficient frontier traces the best trade-offs.

```
# not a heading: git clone https://code.example.org/not-a-citation
```
""",
    "S1.2": """### S1.2 | CAPM

The Security Market Line relates beta to return [(Sharpe)](https://example.org/sharpe/). See S2.1 for learned alternatives.

Omitted: Treynor — no primary source was reachable
""",
    "S2.1": """### S2.1 | Learned portfolios

#### Comparison

| Approach | Source |
|---|---|
| Deep portfolio theory by Heaton, Polson and Witte | [arXiv](https://arxiv.org/abs/1605.07230) |

It learns weights directly, as the [survey](https://en.wikipedia.org/wiki/Portfolio_(finance)) notes.
""",
}

LOG = [
    {"url": "https://example.org/markowitz", "final_url": "https://example.org/markowitz", "section": "S1.1", "status": "ok", "path": "/tmp/a.txt"},
    {"url": "https://example.org/sharpe", "final_url": "https://example.org/sharpe", "section": "S1.2", "status": "ok", "path": "/tmp/b.txt"},
    {"url": "http://arxiv.org/abs/1605.07230", "final_url": "https://arxiv.org/abs/1605.07230", "section": "S2.1", "status": "ok", "path": "/tmp/c.txt"},
    {"url": "https://en.wikipedia.org/wiki/Portfolio_%28finance%29", "final_url": None, "section": "S2.1", "status": "ok", "path": "/tmp/d.txt"},
    {"url": "https://example.org/broken", "section": "S2.1", "status": "error", "error": "HTTP 404"},
]

def fresh(name):
    d = work / name
    if d.exists():
        shutil.rmtree(d)
    (d / "sections").mkdir(parents=True)
    (d / "spec.md").write_text(SPEC)
    (d / "question.md").write_text("How should a portfolio be built?\n")
    for sid, text in SECTIONS.items():
        (d / "sections" / f"{sid}.md").write_text(text)
    (d / "fetch-log.jsonl").write_text("".join(json.dumps(e) + "\n" for e in LOG))
    return d

def built(name):
    d = fresh(name)
    assert run("assemble", d)[0] == 0
    shutil.copy(d / "draft.md", d / "report.md")
    return d

# --- spec -------------------------------------------------------------------
d = fresh("spec-ok")
expect("valid spec passes", run("spec", d), 0, "spec ok: 2 main sections, 3 units, 3 research questions, 5 required entities")
expect("settings are read", run("spec", d), 0, "fetches_per_section 5")

bad_specs = {
    "duplicate id": (SPEC.replace("### S1.2 | CAPM", "### S1.1 | CAPM"), "out of order"),
    "wrong parent": (SPEC.replace("### S2.1 | Learned", "### S1.3 | Learned"), "sits under S2"),
    "no research questions": (SPEC.replace("1. Who originated CAPM?", "Who originated CAPM?"), "S1.2 (line"),
    "missing block": (SPEC.replace("#### Source leads\n- none\n", ""), "missing block(s) 'source leads'"),
    "lead without URL": (SPEC.replace("- none\n\n## S2", "- the Sharpe paper\n\n## S2"), "does not start with a URL"),
    "unit cap": (SPEC.replace("- sections: 4", "- sections: 2"), "3 units exceed the section cap of 2"),
    "unknown setting": (SPEC.replace("- sections: 4", "- sectons: 4"), "unknown key 'sectons'"),
    "no title": (SPEC.replace("# ResearchSpec", "# Plan"), "must start with '# ResearchSpec'"),
    "main without units": (SPEC + "\n## S3 | Empty\n", "S3: main section has no units"),
}
for desc, (text, want) in bad_specs.items():
    d = fresh("spec-bad")
    (d / "spec.md").write_text(text)
    expect(f"spec: {desc}", run("spec", d), 1, want)

# --- assemble ---------------------------------------------------------------
d = fresh("assemble")
expect("assemble", run("assemble", d), 0, "assembled draft.md: 3 units, 1 omitted entity")
draft = (d / "draft.md").read_text()
order = [draft.index(h) for h in ("# How should a portfolio be built?", "## S1 | Classical theory",
         "### S1.1 | Mean-variance", "### S1.2 | CAPM", "## S2 | Machine learning", "### S2.1 |", "## Not covered")]
if order != sorted(order):
    failures.append("assemble: headings out of order\n" + draft)
if "- S1.2 · Treynor: no primary source was reachable" not in draft or "Omitted:" in draft:
    failures.append("assemble: Omitted line not moved to Not covered\n" + draft)

d = fresh("assemble-missing")
(d / "sections" / "S1.2.md").unlink()
expect("assemble: missing section", run("assemble", d), 1, "sections/S1.2.md not found")
d = fresh("assemble-heading")
(d / "sections" / "S2.1.md").write_text(SECTIONS["S2.1"] + "\n### S2.2 | Smuggled unit\n")
expect("assemble: added unit heading", run("assemble", d), 1, "adds a heading above level 4")
d = fresh("assemble-wrong-id")
(d / "sections" / "S1.1.md").write_text(SECTIONS["S1.1"].replace("### S1.1 |", "### S1.2 |"))
expect("assemble: wrong id in file", run("assemble", d), 1, "must open with '### S1.1 | <title>'")

# --- gates: the clean run ---------------------------------------------------
d = built("clean")
expect("clean run, G3 skipped", run("gates", d, "--without", "g3"), 0, "VERIFIED (G3 skipped by --without)")
verify = json.loads((d / "verify.json").read_text())
if verify["verified"] is not True or verify["gates"]["G3"]["pass"] is not None:
    failures.append(f"verify.json wrong: {verify}")
expect("G3 required by default", run("gates", d), 1, "claim check not run")
expect("--without only takes g3", run("gates", d, "--without", "g1"), 2, "accepts only g3")

# --- G1 provenance ----------------------------------------------------------
def with_section(name, sid, text):
    d = fresh(name)
    (d / "sections" / f"{sid}.md").write_text(text)
    assert run("assemble", d)[0] == 0, name
    shutil.copy(d / "draft.md", d / "report.md")
    return d

d = with_section("g1-unfetched", "S1.1", SECTIONS["S1.1"] + "\nA made-up claim ([blog](https://unfetched.example/post)).\n")
expect("G1: unfetched citation", run("gates", d, "--without", "g3"), 1, "S1.1: https://unfetched.example/post — never fetched")
d = with_section("g1-failed", "S2.1", SECTIONS["S2.1"] + "\nSee https://example.org/broken.\n")
expect("G1: failed fetch", run("gates", d, "--without", "g3"), 1, "fetch failed (HTTP 404)")
d = built("g1-badlog")
with open(d / "fetch-log.jsonl", "a") as fh:
    fh.write("not json\n")
expect("G1: corrupt log", run("gates", d, "--without", "g3"), 1, "line 6 is not JSON")

# --- G2 structure -----------------------------------------------------------
d = with_section("g2-leak", "S1.2", SECTIONS["S1.2"].replace("See S2.1", "See S1.5"))
expect("G2: dangling section reference", run("gates", d, "--without", "g3"), 1, "refers to S1.5, which is not a section")
d = built("g2-missing")
r = (d / "report.md").read_text()
start = r.index("### S1.2"); end = r.index("## S2 |")
for f in ("report.md", "draft.md"):
    (d / f).write_text(r[:start] + r[end:])
expect("G2: missing unit", run("gates", d, "--without", "g3"), 1, "S1.2: missing")
d = built("g2-extra")
for f in ("report.md", "draft.md"):
    (d / f).write_text((d / f).read_text().replace("## Not covered", "## Conclusion\nMore.\n\n## Not covered"))
expect("G2: extra heading", run("gates", d, "--without", "g3"), 1, "unexpected heading 'Conclusion'")

# --- G2b census -------------------------------------------------------------
d = with_section("g2b-silent", "S1.2", SECTIONS["S1.2"].replace("Omitted: Treynor — no primary source was reachable\n", ""))
expect("G2b: silent omission", run("gates", d, "--without", "g3"), 1, "required entity 'Treynor (1962)'")
d = with_section("g2b-alias", "S1.1", SECTIONS["S1.1"].replace("The efficient frontier traces", "The frontier of efficient portfolios traces"))
expect("G2b: alias counts", run("gates", d, "--without", "g3"), 0, "VERIFIED")

# --- G4 edit scope ----------------------------------------------------------
d = built("g4-noplan")
(d / "report.md").write_text((d / "report.md").read_text().replace("best trade-offs", "best trade-off"))
expect("G4: edit without a plan", run("gates", d, "--without", "g3"), 1, "differs from draft.md and there is no edit-plan.md")

d = built("g4-directed")
(d / "edit-plan.md").write_text("# Global Editorial Plan\n## Ownership Decisions\n- CAPM detail → S1.2\n## S1.1\n- **DELETE**: the repeated trade-off sentence\n")
(d / "report.md").write_text((d / "report.md").read_text().replace(" The efficient frontier traces the best trade-offs.", " The efficient frontier traces them."))
expect("G4: directed edit passes", run("gates", d, "--without", "g3"), 0, "VERIFIED")
(d / "report.md").write_text((d / "report.md").read_text().replace("It learns weights directly", "It learns the weights directly"))
expect("G4: undirected edit", run("gates", d, "--without", "g3"), 1, "S2.1: changed, but edit-plan.md has no")

d = built("g4-verify-only")
(d / "edit-plan.md").write_text("## S2.1\n- VERIFY: the survey claim\n")
(d / "report.md").write_text((d / "report.md").read_text().replace("It learns weights directly", "It learns the weights directly"))
expect("G4: VERIFY does not authorise an edit", run("gates", d, "--without", "g3"), 1, "S2.1: changed")

d = built("g4-url-removed")
(d / "edit-plan.md").write_text("## S2.1\n- MERGE: fold the survey sentence into the table\n")
r = (d / "report.md").read_text()
(d / "report.md").write_text(r.replace(", as the [survey](https://en.wikipedia.org/wiki/Portfolio_(finance)) notes", ""))
expect("G4: URL removed without DELETE", run("gates", d, "--without", "g3"), 1, "Portfolio_(finance): removed without a DELETE directive")
(d / "edit-plan.md").write_text("## S2.1\n- DELETE: the survey link https://en.wikipedia.org/wiki/Portfolio_(finance)\n")
expect("G4: URL removed with DELETE", run("gates", d, "--without", "g3"), 0, "VERIFIED")

d = built("g4-url-added")
(d / "edit-plan.md").write_text("## S1.2\n- MOVE: CAPM detail from S1.2 to S2.1\n")
(d / "report.md").write_text((d / "report.md").read_text().replace("relates beta to return", "relates beta to return ([Fama](https://example.org/sharpe/extra))"))
expect("G4: editor added a URL", run("gates", d, "--without", "g3"), 1, "added by the editor")

d = built("g4-move-target")
(d / "edit-plan.md").write_text("## S1.2\n- MOVE: the CAPM aside from S1.2 to S2.1\n")
(d / "report.md").write_text((d / "report.md").read_text().replace("It learns weights directly", "It learns the weights directly"))
expect("G4: MOVE target may change", run("gates", d, "--without", "g3"), 0, "VERIFIED")

# --- sample and G3 ----------------------------------------------------------
d = built("g3")
expect("sample", run("sample", d, "--k", "3"), 0, "sampled 3 of 4 linked sentences")
claims = json.loads((d / "claims.json").read_text())
first = [c["sentence"] for c in claims]
expect("sample refuses to overwrite", run("sample", d), 1, "Pass --force")
expect("sample --force", run("sample", d, "--k", "3", "--force"), 0, "sampled 3")
again = [c["sentence"] for c in json.loads((d / "claims.json").read_text())]
if first != again:
    failures.append(f"sample is not deterministic: {first} vs {again}")
if any("code.example.org" in c["sentence"] for c in claims):
    failures.append("sample picked a sentence from a code block")
wiki = [c for c in claims if "Portfolio_(finance)" in c["sentence"]]
if wiki and wiki[0]["pages"] != ["/tmp/d.txt"]:
    failures.append(f"sample: pages not resolved through the log: {wiki[0]}")
expect("G3: no verdicts yet", run("gates", d), 1, "C1: no verdict")
for c in claims:
    c["verdict"] = "supported"
claims[-1]["verdict"] = "partial"
(d / "claims.json").write_text(json.dumps(claims))
expect("G3: supported and partial pass", run("gates", d), 0, "VERIFIED")
claims[0]["verdict"] = "unsupported"; claims[0]["note"] = "page says 1959"
(d / "claims.json").write_text(json.dumps(claims))
expect("G3: unsupported fails", run("gates", d), 1, "unsupported — page says 1959")
claims[0]["verdict"] = "supported"; claims[0]["sentence"] = "A sentence the report no longer has."
(d / "claims.json").write_text(json.dumps(claims))
expect("G3: stale verdict", run("gates", d), 1, "no longer in report.md")

# --- could not run ----------------------------------------------------------
expect("missing run dir", run("gates", work / "nope"), 2, "not found")
d = fresh("no-report")
expect("missing report.md", run("gates", d), 2, "report.md not found")

if failures:
    print(f"{len(failures)} failure(s):")
    for f in failures:
        print(" - " + f.replace("\n", "\n   "))
    sys.exit(1)
print("research-nt check.py: all cases pass")
PY
