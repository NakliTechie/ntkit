# Credits

ntkit borrows rules, methods and wording from the sources below. Skill text carries the rules only; the credits live here (AUTHORING §10).

## Adapted wording, with licence notices

These are adapted from their sources' text, so their licences apply to those passages.

| Source | Licence | Where in ntkit |
|---|---|---|
| [google/mantis](https://github.com/google/mantis) (`mantis-history`, `mantis-review`, `mantis-researcher`, `mantis-calibrate`, variant hunting, `neuter_matrix.py`) | Apache-2.0 | `forward-pass-nt` lenses (history seed, security habits), ranking (caps, challenge before ranking); `harden-nt` verify round and neuter matrix |
| [OpenQodex](https://github.com/openqodex/openqodex) | Apache-2.0 | `forward-pass-nt` diff-review method and scanner list |
| [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | MIT | `forward-pass-nt` severity anchor and "Not Security findings"; `live-check-nt` header checklist |
| [mattpocock/skills](https://github.com/mattpocock/skills) (`improve-codebase-architecture`, `codebase-design`, `DEEPENING.md`) | MIT | `forward-pass-nt` churn, structure tests, recorded-decision rule, test dependency categories |
| [LongCat-DeepResearch](https://github.com/meituan-longcat/LongCat-DeepResearch), © 2026 LongCat (Meituan) | MIT; full text in `skills/research-nt/references/LICENSE-longcat` | `research-nt` prompts |
| [openclaw](https://github.com/openclaw/openclaw) `test-audit` skill | not stated | `forward-pass-nt` test-value lens (paraphrased) |
| [brag](https://github.com/latent-spaces/brag) by Shunit Haviv Hakimi | MIT, vendored with its licence | `package-nt` launch video |
| [disktree](https://github.com/tobi/disktree) by Tobias Lütke | MIT | `reclaim-nt` scanner (a fork) |
| [pi-workflows](https://github.com/osolmaz/pi-workflows) | — | the skill authoring standard |

Apache-2.0 notice: portions of `skills/forward-pass-nt/` and `skills/harden-nt/` are adapted from google/mantis and OpenQodex, licensed under the Apache License, Version 2.0 (https://www.apache.org/licenses/LICENSE-2.0). The adapted passages were condensed and reworded.

## Ideas only (no text copied)

| Source | Idea used in |
|---|---|
| SWE-sweep, Lieret et al. 2026 ([paper](https://swesweep.com/paper)) | `forward-pass-nt`: hunt bugs by the repo's own contracts |
| [jnsahaj/skills](https://github.com/jnsahaj/skills) `zero-tech-debt` | `forward-pass-nt`: one rule, one owner; structure tests; `autopilot-nt` loop |
| Cursor `pstack` ([`model-the-domain`, `no-comments`](https://github.com/cursor/plugins/tree/main/pstack)) | `forward-pass-nt`: parallel state; comments as symptoms |
| Harel, "Statecharts: A Visual Formalism for Complex Systems" (1987); "make impossible states impossible" | `forward-pass-nt`: implicit state machine inventory and re-entry check |
| Argus, Mang et al., SIGMOD 2026 ([arXiv:2510.06663](https://arxiv.org/abs/2510.06663)) | `forward-pass-nt`: running a check beats judging it |
| Bombadil's zero-spec browser defaults | `walkthrough-nt`: floor invariants |
| Fork-and-Flush ([arXiv:2610.07447](https://arxiv.org/abs/2610.07447)) | `lab-nt`: forks with an empty conversation |
| TreeOPSD independent replication ([arXiv:2610.23181](https://arxiv.org/abs/2610.23181)) | `lab-nt` and `research-nt`: the simple-fix control |
| raea's quality floor; SenseNova Code2Video `code-video` skill | `package-nt`: `check-video.py` loudness, peak and file checks |
| Thorsten Ball, "How I work with Agents" | diagnostic batches test two to four hypotheses; `evals/run.sh --without` |
| MiniMax Code team, `independent-review` and `harness-experiment` skills | the three-input review brief; A/B eval report fields |
| TandemLLM conductor | `SUBSTANCE.md` §6.18–20 run guards |
| TokenEconomizer (arXiv:2610.22732) | `traces-nt` spend ranking |
| Anthropic, "The components of agent memory" (2026-11-06) | `MEMORY.md` W6; `prefs-nt` size budget |
| Mainplane; REMORY (arXiv:2610.11287) | `windup-nt` and `resume-nt` "Pick up here" block |
