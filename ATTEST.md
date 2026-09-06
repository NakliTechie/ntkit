# ATTEST.md — Communication Standard for This Repository

This standard governs communication. Code, comments, commit messages, and
execution permissions are out of scope.

## 0. Apply selectively

Use full ATTEST-100 formatting only for designated formal reports and handbacks
exceeding approximately 200 characters before ATTEST formatting is added.
Designated outputs are formal audit reports, release-readiness gate summaries,
unattended-run handbacks, and outputs explicitly requested in ATTEST.

Use concise natural prose for shorter outputs, ordinary discussion, explanations,
planning, progress updates, routine coding handbacks, and questions, even during
a workflow that produces a formal report. A workflow's reference to ATTEST
designates its report; it does not switch the whole conversation into ATTEST.
Apply the threshold to the intended output, not the conversation. Treat 200
characters as a presentation guideline; do not add counting machinery or pad
responses. Explicit user instructions about a particular output take precedence.

The formatting scope ends with the designated output. This section governs
activation of sections 1–7, including their references to every message, claim,
question, or handback. Those formatting and vocabulary rules apply within a
qualifying formal output, not to subsequent conversation.

### Evidence standards at every length

- Distinguish executed checks and direct observations from inference, assumptions, and external reports.
- Support success claims with relevant command results or artifacts. Do not equate implementation or a refusal with validated delivery.
- State checks that did not run, remaining limitations, and blockers. Flag assumptions that gate further work and explain what would establish them.
- Use real, resolving evidence pointers. Do not invent results or imply broader coverage than the checks support.

Core principle: **"done" is the verifier's word, never yours.** In formal ATTEST
reports, label every factual claim with its evidence class and apply the success
vocabulary rules below. In natural prose, express the same evidentiary limits
without mandatory labels or typed blocks.

All existing authorization, approval, spending, privacy, security, and workflow
execution boundaries remain in force regardless of response length or format.

---

## 1. Structure every message as typed blocks

Every line of your report lives inside a typed block. No untyped prose, no
greetings, no sign-offs, no apologies, no enthusiasm. Order: worst news first
(BLOCKS-severity RISK → RESULT/STATUS → BLOCKER → QUESTION → DIFF → PLAN →
lower RISK → ESCALATION).

Block format:

```
[TYPE evidence-class]
Content.
evidence: <pointer>
```

The eight block types (closed set — never invent new ones):

| Type | Use when | Must contain |
|---|---|---|
| RESULT | Reporting an outcome | claim + evidence class + evidence pointer |
| STATUS | Reporting position in a plan | step ref + state: complete / in-progress / not-started / blocked |
| PLAN | Stating next actions | numbered steps, each with its verifier |
| BLOCKER | Progress stopped | what stopped + tried-trail + smallest thing that unblocks |
| QUESTION | You need a decision | closed list of options, your recommendation marked, **a default if unanswered**, what is blocked meanwhile |
| RISK | Flagging a hazard | first word = severity: BLOCKS / DEGRADES / COSMETIC, then trigger + mitigation |
| DIFF | Summarizing changes | files as path:line ranges + behavior delta + invariants affected |
| ESCALATION | Exiting a loop | reason: no-progress / budget / locked-decision + pointer to written tried-trail |

Rules:
- One block, one concern. A result that raises a question = two blocks.
- Any turn that reports work contains at least one RESULT or STATUS.
- A QUESTION always states its default action; never silently halt waiting for
  an answer.

## 1a. Rendering within a qualifying formal output

Apply section 0 before choosing a register. A short standalone output uses
natural prose; it does not need a compact ATTEST wrapper.

Within a qualifying formal report:

- **Compact register:** a brief concern can use one line with type, evidence
  class, and pointer inline. Adjacent claims of the same type can share a block
  when their evidence classes and pointers remain clear.
- **Full register:** use multiline blocks for BLOCKER, QUESTION, ESCALATION,
  BLOCKS-severity RISK, and formal end-of-run handbacks. Include their applicable
  structured fields: tried-trail, options and default, or severity and mitigation.
- Choose the register by the information needed within the report. The
  approximately 200-character guideline applies to activation of the intended
  output, not separately to each block inside an already qualifying report.

Sections 2–5 apply in both formal registers. The evidence standards in section 0
also apply to natural prose outside formal reports.

## 2. Mark every factual claim with an evidence class

Exactly one class per claim. Declare it in the block header when uniform
(`[RESULT verified]`), inline when mixed (`(observed)`).

| Class | You may use it when | You must cite |
|---|---|---|
| verified | A deterministic check ran and passed | the literal command + exit code, test id, or artifact path |
| observed | You executed something and saw output, but no formal check | what you ran and what you saw |
| inferred | You concluded from reading code/docs; nothing executed | the source, as path:line or doc ref |
| assumed | You are taking it as true without evidence | what check would confirm it |
| reported | You are relaying an external source | the source |

- When unsure between two classes, use the lower one. Never upgrade.
- An `assumed` claim that gates further work must also appear in a QUESTION or
  RISK block.
- Every evidence pointer must resolve: the cited test exists, the cited command
  actually appears in this session, the cited file exists at that path. A
  pointer that does not resolve is a fabrication and voids the claim.

## 3. Reserved words — only inside a `verified` claim

done · complete · fixed · resolved · passing · green · works · working ·
correct · safe · secure · verified · confirmed · proven · no regressions ·
production-ready

If you have not run the verifier, write the honest downgrade instead:
- not "done" → "implemented, not yet verified"
- not "fixed" → "changed; fix unconfirmed"
- not "works" → "ran without error on <input> (observed)"
- not "no regressions" → "suite <id> passed" or say which suites did not run

A **refusal-only** outcome is never a "done": if only the refusal or guard path is
built and the positive capability is not, report it as unfinished — "refusal path
implemented; capability not yet built" — never inside a reserved word. (The
delivery-side rule this mirrors: `SUBSTANCE.md` §4.)

## 4. Banned words — never, in any block

- Predictive hedges: should work, probably, likely, hopefully, seems to,
  appears to, "I think/believe" as a claim prefix (use the evidence class)
- Minimizers: just, simply, basically, straightforward, trivial, quick fix
- Success theater: great, perfect, excellent, awesome, all set, good to go,
  any emoji, any exclamation mark
- Social filler: great question, happy to, of course, certainly
- Apologies: sorry, apologies, my mistake — state the error and the correction
  instead; contrition is not information
- Vague quantities when the count is knowable: a few, some, several, most, many

("should" is allowed only when quoting a spec's normative language inside a
`reported` claim.)

## 5. Writing rules

1. One factual claim per sentence. Never join two claims with a conjunction.
2. Active voice, you as subject: "I changed X", never "X was changed".
3. Count what is countable: "3 of 41 tests fail", never "a few tests fail".
4. Claim absence explicitly: if a required check did not run, say "I did not
   run <check>" — never imply completion by omission.
5. Files are `path:line` or `path:line-range`. Commands are literal, in
   backticks. Identifiers verbatim, in backticks.
6. Tried-trails: append-only, first person, past tense, one attempt per line:
   "I ran X; it failed with Y." A cold reader must be able to replay it.
7. Sentence length: aim under 20 words in RESULT/STATUS/BLOCKER. If a complex
   explanation genuinely needs more room, add `[prose-exception: reason]` and
   write normally — but claims inside it still carry classes and rules 1–6.
8. Simple past for what happened; simple present for what is; "will" only
   inside PLAN blocks. No rhetorical questions.

## 6. Canonical example

```
[RESULT verified]
Grant-scope check passes for all 3 roles.
evidence: `npm test -- grant.spec.js` exit 0, 17/17

[RESULT observed]
The demo page loads and issues a scoped token in Chrome 126.
evidence: `python3 -m http.server 8080` + manual load; token in console

[BLOCKER]
I cannot test the Firefox path.
tried: I installed firefox-esr; headless launch failed with `GLIBC_2.36 not found`.
tried: I pinned firefox 115; same failure.
needed: a base image with GLIBC >= 2.36, or waiver of the Firefox gate.

[QUESTION]
Options: (a) waive Firefox for M1, gate at M2 — recommended; (b) swap base image now.
default: (a), applied if unanswered at next session start.
blocked meanwhile: nothing; the M1 gate minus Firefox is satisfiable.
```

Anti-example — never write this:
> "Great news! Everything's done and working perfectly — fixed the auth bug,
> tests should all be passing now. Just a small tweak was needed!"

Violations: untyped prose, 5 banned words, 4 reserved words without a verified
claim, no evidence pointers, no counts.

## 7. Self-check before you send

- [ ] Section 0 designates this output for formal ATTEST and its unformatted
      length exceeds approximately 200 characters, unless the user specifies otherwise
- [ ] Every line of this formal output is inside one of the 8 block types
- [ ] Brief concerns use compact blocks; BLOCKER / QUESTION / ESCALATION /
      BLOCKS-RISK / formal handbacks use full blocks with their required fields
- [ ] Every factual claim has exactly one evidence class
- [ ] Every reserved word sits inside a `verified` claim with a resolving pointer
- [ ] Zero banned words, zero exclamation marks, zero emoji
- [ ] Every QUESTION has a default; every BLOCKER has a tried-trail
- [ ] Everything the task's gate requires is either claimed or explicitly
      marked not-run
- [ ] Worst news is first

Use this checklist only for outputs selected by section 0. For a qualifying
formal output, conformance is judged by a linter and a separate checker, not by
you. If any box fails, rewrite before sending. For other outputs, apply section
0's evidence standards in natural prose.

---
ATTEST-100 Issue 0.1 · operative subset · full spec: attest-100-spec-001.md
