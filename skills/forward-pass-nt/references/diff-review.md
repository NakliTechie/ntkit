# Diff-time review and the scanner list

Phase 2 reads the whole app. A pre-push review reads one change. Borrow its method for the Security and Stray lenses, and use its scanner list as the checklist of tools to run.

## Method

- Freeze the change first: unpushed commits plus uncommitted work, copied to a read-only snapshot.
- Run the scanners that fit the changed files. Keep only findings on changed lines. Lines next to a deletion count as changed, so a removed check can carry a finding.
- Start a separate reviewer with read-only tools in the snapshot and none of the user's settings, hooks, plugins or memory. The reviewer checks every scanner finding and sees every changed line.
- Check the reviewer's answer with scripts, not by trusting it.
- Completeness rule: a review is complete only when every stage ran, every scanner finding was raised or dropped with a reason, and every changed line reached the reviewer. Otherwise report "review incomplete" and name what is missing.
- A suppression comment the change adds (`# nosec`) or a changed scanner settings file silences a scanner. Show each one and check it.
- Report each finding under its line of code, with a verdict and one line per finding. Fix only the findings the user names.
- A push gate warns by default and blocks only when a severity threshold is configured.
- Limits to state in any report: the review needs a logged-in reviewer agent, takes one to three minutes, finds not everything, and queries an online vulnerability database unless run offline.
- A custom scanner runs only after the user approves its version, release asset, sha256 and run line. An edited entry needs a new approval.
- Ask the code graph (callers of a symbol, blast radius) with evidence per item and a note when the list may be short.

## Scanners (22)

Pin each scanner to one version and check its sha256 on download.

| Scanner | Version | Runs when the change holds |
|---|---|---|
| semgrep | 1.94.0 | any file |
| gitleaks | 8.21.2 | any file |
| bandit | 1.9.4 | `.py`, `.pyi` |
| ruff | 0.8.4 | `.py`, `.pyi` |
| oxlint | 1.86.0 | `.js` `.jsx` `.ts` `.tsx` `.mjs` `.cjs` `.mts` `.cts` |
| osv-scanner | 2.6.0 | a lockfile (`package-lock.json`, `bun.lock`, `uv.lock`, `go.mod`) |
| actionlint | 1.7.7 | `.github/workflows/*.yml` |
| hadolint | 2.15.1 | a Dockerfile |
| shellcheck | 0.10.0 | `.sh`, `.bash`, or a `#!` sh/bash/dash/ksh file |
| golangci-lint | 2.12.2 | `.go` |
| brakeman | 6.2.1 | a Rails app (non-OSS licence; download at run time) |
| rubocop | 1.69.2 | `.rb`, `.rake`, `.gemspec`, `Rakefile` |
| sqllint | built in | `.sql` |
| squawk | 2.66.0 | `.sql` |
| SQLFluff | 4.3.0 | `.sql` |
| zizmor | 1.30.1 | GitHub workflow, `action.yml`, `.github/dependabot.yml` |
| trivy | 0.75.0 | Terraform, Kubernetes manifest, CloudFormation (config checks) |
| Checkov | 3.3.22 | same files as trivy |
| TFLint | 0.64.0 | `.tf`, `.tf.json` |
| kube-linter | 0.8.3 | a YAML file holding a Kubernetes object |
| kubeconform | 0.8.0 | same files as kube-linter |
| cargo-deny | 0.20.2 | `Cargo.lock` |

Network: scanner downloads (GitHub releases, PyPI, RubyGems); semgrep rule packs on each run; osv-scanner sends dependency names and versions, never code; the reviewer sends its brief and the files it reads to its model. An offline run skips osv-scanner, semgrep and downloads. Runtimes the scanners need but a pass does not install: Ruby 3.0+ (brakeman), Ruby 2.7+ (rubocop), Go (golangci-lint), Cargo (cargo-deny).
