---
description: "Deprecated alias for /harden-nt — the same loop, reframed around a path map (constructive + adversarial discovery) instead of attack rounds. Runs /harden-nt unchanged."
argument-hint: "[surface, e.g. \"the public API\" | budget, e.g. \"6 rounds\" | resume]"
allowed-tools: ["Bash", "Glob", "Grep", "Read", "Edit", "Write", "Task"]
entry: "same as /harden-nt"
exit: "same as /harden-nt"
writes: "plan/harden-<date>.md"
---

`/spar-nt` was renamed to **`/harden-nt`** in ntkit v1.3. The loop is the same — independent agents from different model families, rounds, and the rule that a check must prove it can fail — but it now runs from a **path map** and exits on coverage ("every path hardened") rather than on absence of findings ("nobody found anything").

Say so in one line, then run `/harden-nt` with the arguments as given. This alias is kept for one release; use `/harden-nt` directly.
