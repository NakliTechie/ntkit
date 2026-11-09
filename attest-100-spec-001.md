# ATTEST-100

**Agent-To-human Technical English with Evidence and STatus**
Standard for coding-agent communication with humans.

This file holds the parts of ATTEST-100 that ATTEST.md does not: the spec's
metadata and lineage, the posture and rationale, scope detail, conformance
levels, rule IDs with enforcement tiers, clauses that extend single ATTEST.md
rules, extra reserved-word replacements, a RISK block example, the
`attest-lint` rule table, governance and the change log, and the adoption path.
ATTEST.md is the operative standard; read it first.

| Field | Value |
|---|---|
| Issue | 0.2 |
| Status | Reference spec. §§0–5 (posture, blocks, evidence classes, dictionary, writing rules) are in force — `ATTEST.md` is their operative subset, used every session. §6–8 (linter, governance change-form, adoption milestones) remain proposal-stage: `attest-lint` does not exist yet; no session has run under A/B conformance checking. |
| Date | 2026-09-23 (Issue 0.2 revision; Issue 0.1 drafted 2026-08-01) |
| Maintainer | NakliTechie (governance model: STEMG-style, see §7) |
| License | TBD (candidate: CC-BY-SA, publishable like Sidecar Doctrine) |
| Lineage | ASD-STE100 Issue 9 (writing rules, controlled lexicon) · S1000D (typed content units) · RFC 2119/8174 (controlled semantic dimension) · NakliTechie Build Doctrine ("done is the verifier's word") · Wikipedia "Signs of AI writing" + arXiv word-frequency studies (Issue 0.2 readability zone, see §0) |

---

## §0 — Posture and scope (extends ATTEST.md §0)

**Posture.** An agent's report is not prose; it is a claim-bearing instrument. The
failure mode this standard exists to prevent: an agent that says "done" when no
verifier ran, hedges when it should measure, and buries one blocker in five
paragraphs of success theater. ATTEST-100 makes those failures *grammatically
detectable* rather than stylistically discouraged.

**The inversion, Issue 0.1.** ASD-STE100 closes the entire general vocabulary
(~900 approved words) because its readers are non-native mechanics. ATTEST-100
left the general vocabulary open and closed only the **claim zone**: a reserved
lexicon usable only with machine evidence, and a banned lexicon with no legal use.

**The second zone, Issue 0.2.** A claim-zone-only standard still let natural
prose run long and unreadable, because nothing gated sentence length or word
choice outside a claim. Issue 0.2 adds a **readability zone**: sentence and
paragraph caps, and a banned lexicon of documented AI-writing tells (ATTEST.md
§4.2), that apply to every sentence, not only claims. Two zones are now closed;
the rest of the language stays open.

**Governance note on the readability zone.** §7's change-form process requires
≥3 transcript excerpts before a word enters a controlled list. The Issue 0.2
readability zone did not go through that process — it was added by maintainer
directive, backed by published external evidence (Wikipedia's "Signs of AI
writing," arXiv word-frequency studies of GPT-family output) rather than
the author's own transcripts. This is a logged exception to §7, not a silent one;
see the Issue 0.2 entry there.

**Scope.** Binds agent → human messages: status reports, handback summaries,
escalations, questions. Does NOT bind: code, comments, commit messages (Conventional
Commits governs those), agent → agent traffic, or human → agent instructions.

**Conformance levels.**

| Level | Meaning |
|---|---|
| A-conformant | Passes all machine-checkable rules (§6, A-rules). Lintable. |
| B-conformant | A-conformant + passes judgment rules (§6, B-rules) as screened by a checker context. |

No session has been scored against either level yet; `attest-lint` is unbuilt
(§8, M0).

---

## §1 — Message types (extends ATTEST.md §1)

Pleasantries, apologies, and enthusiasm have no legal container and are
therefore structurally banned. The block syntax is line-oriented and grep-able,
with no JSON ceremony.

### 1.1 Optional fields per type

ATTEST.md §1 lists the required fields. Each type may also carry:

| Type | Optional fields |
|---|---|
| RESULT | scope note |
| STATUS | per-step evidence |
| PLAN | budget estimate |
| BLOCKER | severity; the tried-trail may be given as a pointer |
| QUESTION | deadline for default |
| RISK | evidence class |
| DIFF | migration note |
| ESCALATION | recommendation |

### 1.2 Type rules: IDs and added clauses

| ID | Rule (full text in ATTEST.md §1 unless an added clause follows) |
|---|---|
| A1.1 | Every line lives inside a typed block. |
| A1.2 | One block, one concern. |
| A1.3 | A turn that reports work contains ≥1 RESULT or STATUS block. |
| A1.4 | A QUESTION states its default action. Added clause: it also states **when the default triggers**. |
| A1.5 | A RISK block's first word is its severity word. Added rationale: this is the STE warning rule, transplanted. |
| A1.6 | An ESCALATION points at a written tried-trail. Added clause: the trail itself lives in external state (a state file), not only in the message. |
| A1.7 | Block order: RISK (BLOCKS) → RESULT/STATUS → BLOCKER → QUESTION → DIFF → PLAN → RISK (lower) → ESCALATION. |

---

## §2 — Evidence classes (extends ATTEST.md §2)

The five classes are strictly ordered by entitlement: VERIFIED, OBSERVED,
INFERRED, ASSUMED, REPORTED. This is the RFC 2119 move applied to the *evidence*
dimension instead of the *requirement* dimension.

Added clauses to the class table:

- INFERRED covers conclusions from reading code, docs, or config.
- REPORTED sources include a doc, an issue, a human instruction, or an upstream
  changelog.

| ID | Rule (full text in ATTEST.md §2 unless an added clause follows) |
|---|---|
| B2.1 | One claim, one class. Added clause: a sentence may not carry two factual claims (rule 3.1), so a sentence carries at most one marker. |
| B2.2 | Header class when uniform, inline when mixed. Added clause: uniform-header is the default; inline is the exception. |
| B2.3 | The success vocabulary is reserved to VERIFIED. An agent that has not run the verifier cannot say "done" without producing a lintable violation. |
| B2.4 | Evidence pointers resolve; an unresolvable pointer is a fabrication (rule A-10). Added rationale: this is the linguistic layer of the reward-hacking screen. |
| B2.5 | Downgrading is always legal; upgrading never is. |
| B2.6 | An ASSUMED claim that gates further work also appears in a QUESTION or RISK block. |

---

## §3 — Writing rules: IDs and enforcement tiers (extends ATTEST.md §0.3 and §5)

**Enforcement tiers.** Rules marked ● are hard (linted, A-tier or
checker-screened); rules marked ○ are defaults an agent may break when the
reader is better served (ATTEST.md §0.2). An ○ break is bounded, not unlimited
(3.5's 40-word limit) — it buys room, not an exit from the standard. Constrain
the claims hard, the prose moderately — the ACE failure (unreadable because
fully machine-parseable) is the over-rotation this tier split prevents.

**Scope, Issue 0.2.** Rules 3.1–3.4 bind only inside typed blocks (above the
structure threshold). The sentence rules and readability rules bind
everywhere — inside blocks and in natural prose alike.

| ID | Tier | Rule | ATTEST.md home | Added clause |
|---|---|---|---|---|
| 3.1 | ● | One claim per sentence. No conjunction joins two factual claims; each needs its own evidence class. | §2, §0.3 | This rule is about factual claims, not only main points. |
| 3.2 | ● | Every VERIFIED/OBSERVED/INFERRED/REPORTED claim carries its pointer. | §2 | — |
| 3.3 | ● | Numbers over adjectives; count what is countable. | §5.3 | — |
| 3.4 | ● | Claim absence explicitly. | §5.4 | Applies when the handoff's gate lists the check. |
| 3.5 | ○ | Sentence length: aim for 25 words; 40 is the limit. | §0.3, §5.7 | — |
| 3.6 | ● | Active voice, agent as subject. | §0.3, §5.2 | Attribution is load-bearing: a later reader must tell the agent's action from the system's. |
| 3.7 | ○ | Tense: simple present; past for completed actions and tried-trails; "will" only in PLAN or an explicit forward statement. | §0.3, §5.9 | — |
| 3.8 | ● | No rhetorical questions. | §5.9 | Interrogatives are legal only in QUESTION blocks. |
| 3.9 | ● | File references are `path:line` or `path:line-range`. Never "the auth file." | §5.5 | — |
| 3.10 | ● | Command references are the literal command in backticks. Never "I ran the tests" without the invocation. | §5.5 | — |
| 3.11 | ● | Identifiers appear verbatim, backticked. | §5.5 | Identifiers include tests, migrations, feature flags, and env vars. |
| 3.12 | ● | Tried-trail: append-only, first person, past tense, one attempt per entry, replayable. | §5.6 | — |
| 3.13 | ● | A QUESTION presents a closed list of options with the recommendation marked. | §1 | Open-ended "what do you think?" is a violation. |
| 3.14 | ○ | A BLOCKER names the *smallest* thing that unblocks, not the largest. | §1 | — |
| 3.15 | ● | One main point per sentence; a sentence may carry its reason. Reader-first rules outrank this one. | §0.3, §5.1 | — |
| 3.16 | ● | Paragraph cap: 6 sentences, then a list. | §0.3 | — |
| 3.17 | ○ | No metaphor, idiom, or figurative language. | §0.3 | The closed instances in the AI-tell list (ATTEST.md §4.2) are A-tier lintable; the open-ended form of this rule is B-tier, checker-screened judgment. |

---

## §4 — Dictionary (extends ATTEST.md §3 and §4)

The dictionary is the complete controlled zone: the claim zone (reserved and
banned words) plus the readability zone (AI-tell words and formatting tells,
Issue 0.2). Everything not listed is unrestricted technical English. The
claim-zone lists grow only via change form (§7); the readability zone grows from
published evidence of AI-writing patterns, logged the same way (§7, Issue 0.2
entry).

### 4.1 Reserved lexicon additions (extends ATTEST.md §3)

Added words: completed, passes, ship-ready. Added replacements when the claim is
not VERIFIED:

| Word/phrase | If not VERIFIED, write instead |
|---|---|
| done, complete, completed | "implemented, not yet verified" (OBSERVED/INFERRED) |
| passing, passes, green | state which check and its actual status |
| correct | "matches spec at <ref>" (INFERRED) |
| safe, secure | name the specific property checked |
| verified, confirmed, proven | (definitionally reserved) |
| production-ready, ship-ready | never available below VERIFIED; even then cite the gate |

### 4.2 Banned lexicon additions (extends ATTEST.md §4.1)

- Social filler also includes "as requested".
- "appears to" is banned when it describes the agent's own work.

### 4.4 Severity words (extends ATTEST.md §1, RISK)

BLOCKS · DEGRADES · COSMETIC is a closed set. No synonyms ("critical," "minor,"
"P1") — one scale, three words.

---

## §5 — RISK block example (extends ATTEST.md §6)

ATTEST.md §6 has no RISK block. This one shows the severity-first form:

```
[RISK]
BLOCKS: `crate` v1 API surface changes if step 3 of the plan proceeds.
trigger: renaming `vault.open()` breaks the frozen ESM contract.
mitigation: step 3 rewritten to extend, not rename. (inferred)
evidence: crate/API.md:12-40
```

A VERIFIED evidence line may also cite the run artifact:

```
evidence: `npm test -- grant.spec.js` exit 0, 17/17, artifact tests/logs/run-0142.txt
```

---

## §6 — Conformance: the linter rule table

The gate artifact. A-rules are deterministic — a linter runs them on every agent
message, same seam as maker-checker. B-rules are screened by the checker context
alongside its existing reward-hack screen. **Unbuilt as of Issue 0.2** — this
table specifies `attest-lint`'s behavior once §8 M0 lands; no session has been
scored against it yet.

### A-rules (machine-checkable)

| ID | Rule | Check |
|---|---|---|
| A-01 | All content inside typed blocks | Parse: no orphan lines |
| A-02 | Block type ∈ registry (ATTEST.md §1) | Token match |
| A-03 | Required fields present per type | Schema |
| A-04 | Evidence class ∈ {verified, observed, inferred, assumed, reported} | Token match |
| A-05 | Reserved word ⇒ enclosing claim is VERIFIED | Lexicon scan × class |
| A-06 | Banned word absent (ATTEST.md §4.1, plus §4.2 here) | Lexicon scan |
| A-07 | RISK first word ∈ {BLOCKS, DEGRADES, COSMETIC} | Token match |
| A-08 | QUESTION contains `default:` | Field presence |
| A-09 | VERIFIED claim has `evidence:` field | Field presence |
| A-10 | Evidence pointers resolve: cited path exists; cited command appears in transcript; cited test id exists | FS stat + transcript grep + test-registry lookup |
| A-11 | File refs match `path:line(-line)?` | Regex |
| A-12 | No exclamation marks, no emoji | Charscan |
| A-13 | ESCALATION cites a tried-trail path that exists | FS stat |
| A-14 | Block order per A1.7 | Sequence check |
| A-15 | Sentence ≤40 words (25 is the aim, not linted) | Word count per sentence |
| A-16 | Paragraph ≤6 sentences before a list | Sentence count per paragraph |
| A-17 | AI-tell word absent (ATTEST.md §4.2) | Lexicon scan |
| A-18 | ≤1 em dash per message; no emoji-as-bullet | Charscan |

A-10 is the deepest check and the point of the standard: **a VERIFIED claim citing
a test that does not exist, or a command absent from the transcript, is a
mechanically detected fabrication.** Lying becomes a lint error.

### B-rules (checker-screened)

| ID | Rule |
|---|---|
| B-01 | One claim per sentence (3.1) — decomposition is judgment |
| B-02 | Claims not upgraded (B2.5): does the evidence actually support the class? |
| B-03 | Tried-trail replayable by a cold reader (3.12) |
| B-04 | Omission honesty (3.4): everything in the gate list is claimed or explicitly not-run |
| B-05 | Reader-first rules hold (ATTEST.md §0.2): no unexplained internal labels, no noun sandwiches, one term per thing, reasons kept |
| B-06 | The reward-hack screen: green achieved by deleting/skipping checks ⇒ VERIFIED claims citing it are void |
| B-07 | Metaphor/idiom absent in its open-ended form (3.17), beyond the closed AI-tell list |

### Exit condition for adopting a tool/session

A session is ATTEST-conformant when: linter exit 0 on every agent turn (A-tier),
and the checker context's B-screen reports no violations. "Conformant" is the
linter's word, never the agent's.

---

## §7 — Governance

- **Issues.** Versioned issues, STEMG cadence adapted: revise when transcript
  evidence accumulates, not on a calendar.
- **Change forms.** A word enters the reserved or banned list only with: (1) ≥3
  transcript excerpts showing the ambiguity/abuse, (2) the replacement phrasing,
  (3) the linter rule delta. Same discipline for new block types — and the type
  registry has a strong bias against growth (the 3-doc rule, applied to blocks).
- **Dictionary growth is downward-only by default:** adding restrictions needs
  evidence; removing them needs only a judgment that the ambiguity risk is gone.
- **Precedence.** Where ATTEST-100 conflicts with a project's Agent Handoff, the
  handoff wins and the conflict is filed as a change form.
- **Issue 0.3 change log (2026-10-11):** added the reader-first rules (ATTEST.md
  §0.2: plain descriptions over internal labels, no noun sandwiches, one term per
  thing, concrete names, keep the reasoning), which outrank the style rules.
  Relaxed 3.5 and 3.15. Removed the one-line compact register from ATTEST.md
  §1a: every formal block is written out in full. Entry method: owner review of Issue 0.2 output, plus the
  Office of the Federal Register's "Principles of Clear Writing".
- **Issue 0.2 change log (2026-09-23):** added the readability zone (§0, §3.5,
  3.15–3.17, §4.3–4.5, A-15–A-18, B-07). Entry method: maintainer directive plus
  external published evidence, not the standard ≥3-transcript-excerpts form —
  logged here as the exception, per the posture that a process gap gets named,
  not hidden. Unified the 20/25-word sentence-cap split (Issue 0.1, rule 3.5)
  to a single 25-word cap with a bounded 40-word exception. Moved this file from
  `~/Downloads` into `ntkit/`, alongside `ATTEST.md`, so the footer's "full spec"
  pointer resolves.
- **Slimming (2026-11):** cut this file to the parts ATTEST.md lacks, on owner
  approval. Section references in the Issue 0.2 entry above name the pre-cut
  layout; the readability-zone lists now live in ATTEST.md §4.2–4.3.

---

## §8 — Adoption path (ntkit)

1. **M0** — This spec + `attest-lint` as a standalone script (stdin → violations,
   exit code). Deterministic verifier; no agent self-report. **Not started as of
   Issue 0.2** — no `attest-lint` script exists in this repo or elsewhere on this
   machine.
2. **M1** — Handoff template gains a pointer: "All handback communication conforms
   to ATTEST-100; the checker runs `attest-lint`." Wire into maker-checker.
3. **M2** — Transcript corpus review after ~10 real sessions; first change-form
   batch; Issue 0.2. *(Superseded: Issue 0.2 shipped by directive instead, ahead
   of a transcript corpus review — see §7 change log.)*
4. **Open decisions** — name confirmation (Attest / Plaint / Vouch); license;
   whether A-10 transcript-grep needs a session-log format contract (likely yes —
   smallest viable: linter receives the transcript path as arg); whether M2's
   corpus review, once it happens, ratifies or revises the Issue 0.2 readability
   zone added ahead of it.

---

*The claim zone and the readability zone are closed; the rest of the language is
open. An agent may explain anything, in any words — except whether its work is
done, and except in the words that mark the explanation as unread machine
output. Those belong to the verifier and the reader, not the agent.*
