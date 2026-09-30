# Research comparison protocol

Use the five rows in `plan/research-nt-bench-2026-09-30.prompts.json`, in their recorded order.
The design and preregistration records in plan/ govern the comparison. Do not select replacements.

## Before running

Identify the installed baseline `deep-research` skill and record its path, version and SHA-256.
Record the exact ntkit revision or working-tree diff hash. Record the models used for both arms.
Use the same host and model assignments for both where possible; disclose substitutions before scoring.
Do not silently replace a missing baseline with another workflow. Obtain authority before billable API calls.

## Produce reports

A = the identified baseline, B = `/research-nt "<verbatim prompt>" --go`.
Use a fresh coordinator and fresh role contexts for each run. Pass only the prompt and the relevant skill.
Do not pass the rubrics to the generators. Preserve each run's artifacts and measured agent count,
wall time, report word count, and available token usage. Missing cost information is unknown, not zero.
No vault capture or publication occurs during the comparison.

Store unchanged final reports at `<results>/<sample_id>/A.md` and `B.md`.
Run G3-style claim assessment for both reports with the same ten-claim sampling rule and fresh checkers.
For A, first fetch every cited URL with fetch.py into a separate evidence run; never use snippets as evidence.
When sampling A, adapt only a copy into one research unit if its headings are not ntkit-shaped.
Keep original report content and its blinded copy unchanged. Record the adapter and its hashes.
Unsupported and partial claims remain visible; failed reports are not replaced or rerun for a better score.

Write `A.metrics.json` and `B.metrics.json` next to the reports:

```json
{"agent_runs": 16, "wall_seconds": 420, "words": 5000,
 "claims": {"supported": 7, "partial": 2, "unsupported": 1}}
```

Values above illustrate the schema only. Populate them from the actual run.
Support rate means fully supported / all sampled; partial counts remain separate.
Apply any pipeline-authorised repair before the final comparison. Keep before/after results.

## Blind and judge

```sh
python3 evals/research-bench.py prepare plan/research-nt-bench-2026-09-30.prompts.json RESULTS OUT
```

The tool randomises A/B order independently for each pair. Give a fresh judge only one
`OUT/judge/<sample_id>/` folder. Never expose `manifest.json`, source paths or the arm names.
The judge reads question.md, rubrics.json and reports 1.md/2.md. It writes verdicts.json with one boolean
per criterion in rubric order, independently for each report. True means the criterion is met,
including negatively weighted criteria. It also writes reasons.md with evidence for every judgment.
Use fresh judges across pairs; do not disclose other pairs' scores.

```sh
python3 evals/research-bench.py score OUT
```

A report's score is the sum of satisfied signed weights divided by the sum of all positive weights.
A tie is not a win. Ship only if B's mean score is at least A's, B wins three of five,
and B's mean fully-supported rate is at least A's. The helper rejects incomplete judgments and changed reports.

A failed ship rule produces a recorded dead end; consider check.py alone. A missing report, baseline,
claim judgment or metric leaves L6 incomplete. Synthetic fixture tests never count as benchmark results.
