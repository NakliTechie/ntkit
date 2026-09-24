# Test-value lens — hunting classes and the retention bar

Read this when the traversal reaches a test suite. The lens asks one question per test: does
it protect observable behaviour, a credible regression, or an independent contract? A test that
does none of those costs maintenance and returns nothing. A test that *looks* like it does none
of those may still be the only guard on a contract, so the retention bar below outranks the
hunting list.

(Adapted from openclaw's `test-audit` skill, `.agents/skills/test-audit/` in
[openclaw/openclaw](https://github.com/openclaw/openclaw), paraphrased; its campaign found
9 real coverage gaps behind cuts that looked safe, which is why this lens reports and never
deletes.)

## Read before judging

For each candidate, read the whole test and the production code it claims to cover: the
entry point, its callers, sibling implementations, overlapping tests, and how CI routes it.
When the test claims dependency-backed behaviour, read the dependency's source or types. Judge
a test by its assertions, not its name — a test named for clearing a window can assert the
window was *not* cleared.

## Hunting classes

- **Assertion-free** — runs code, asserts nothing, or asserts only that nothing threw.
- **Self-fulfilling** — the expected value comes from the helper or renderer under test; a
  self-comparison; a copier that asserts identity.
- **Mock-as-subject** — the mock implements the behaviour being asserted, or one identical mock
  stands in for different APIs; fixtures hand the code the receipt, ordering, or callback the
  real owner should produce; persistence asserted against a store the real path never writes.
- **Mirror tests** — a copied fixture, inventory, manifest, or export list; an exact source,
  import, or string grep that breaks on a rename and survives a behaviour change.
- **Implementation-coupled** — asserts private call shape or internal predicates already covered
  at a real boundary. The check: would it break under a behaviour-preserving refactor?
- **Duplicate proof** — the same contract invoked again at another layer with no new risk; a
  per-provider replay of a shared helper.
- **Test-only seams** — an export, flag, getter, reset hook, or injection parameter that no
  production caller uses and that exists so a test can reach inside. Also production code whose
  only callers are tests.
- **Flag restatement** — a capability test that re-reads a declared flag instead of exercising
  the delivery or acknowledgement the flag promises.
- **Vacuous negative** — a rejection test that passes for an unrelated reason: a different guard
  fires, or the production path never reaches the branch.
- **Regression that never went red** — a test added with a fix, with no record of failing on the
  pre-fix code. It proves the mock, not the fix (`SUBSTANCE.md` §6.3). Always an `F` (reintroduce
  the defect, record the red, repair the test if it stays green), never a `D`.

## Retention bar — keep, even when a class above matches

- It independently guards a public API, SDK, protocol, config, migration, storage, security,
  platform default, prompt-byte, package, release, or architecture contract.
- Call order is observable behaviour.
- It is a regression test with a credible failure mode.
- A source inspection is the cheapest independent guard: it breaks when the user-facing key,
  byte, or path changes and survives an identifier-only rename.
- It fails on the current code. That is a possible product bug: file it under Bugs, not as a
  test to delete.

Slow, static, or "E2E probably covers it" is not a removal reason. Coverage elsewhere counts only
when you can name the keeper test and the assertion in it.

## Recording a finding

Each `T` finding carries one recommendation and its evidence:

- `D` delete — name the keeper that still proves the contract; or, when the test guards nothing
  (an assertion-free probe, a self-comparison), state that and name the mutation that leaves it
  green, which is the proof;
- `C` consolidate — name the owner that absorbs the assertion (a table case, a stronger suite);
- `F` fix the assertion — the contract is real, the check is vacuous;
- `seam` — the test-only production seam its removal unlocks.

Add the non-test callers of any seam, and the focused command that runs the keeper. A candidate
missing both a keeper and a guards-nothing mutation, or missing its command, goes to
**Worth a look**, not to `T`.
