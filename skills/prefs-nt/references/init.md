# init — create the folder and draft core/ from what the agents already have

1. **Resolve the folder.** `dir=` if given, else `${NT_PREFS_DIR:-~/.agent-prefs}`. If it holds `targets.tsv`, stop (guard).
   Announce the path, and say that `NT_PREFS_DIR` in the shell profile moves it.
2. **Copy the template.** Copy `~/.claude/skills/prefs-nt/references/template/` into the folder.
   Rename `gitignore` to `.gitignore`. Create `drift/`.
3. **Find the agents.** For each row of `targets.tsv`, note whether its parent folder exists (the agent
   is installed) and whether the global file exists, with its size. Drop no rows: an agent installed
   later is picked up by the next sync.
4. **Save the originals.** Copy every existing global file to
   `drift/<agent>-before-adoption-<YYYY-MM-DD>.md`.
5. **Draft core/.** Read every saved original. Sort each rule or fact into the template section it
   belongs to:
   - true for every agent → the matching `core/` file, replacing its HTML comment;
   - true for one agent only (its tool names, its own memory habits) → `agents/<agent>.md`, and set that
     agent's third column in `targets.tsv` to its name;
   - about one project only → leave it out and list it in the report, with the project it names.
   Keep each rule's wording, date and reason. Where two agents' files disagree, put the rule in each
   agent's own `agents/` file, not in `core/`, and list the disagreement.
   A long section such as a style guide or a playbook goes into its own file in the folder, and `core/`
   gets one line saying when to read it. A generated file near 30 KB is at risk: Codex stops reading
   instruction files at 32 KiB by default.
6. **Preview.** Run `python3 ~/.claude/skills/prefs-nt/bin/prefs_sync.py --dir <folder> --dry-run` and show its
   output: which files the first sync would write, and their sizes.
7. **Offer git.** If the folder is not a git repo, run `git init` and make a first commit. Do not create
   a remote: that is outward-facing, so offer it as a command the owner runs.
8. **Report** in plain prose: the folder path, each agent found, the rules sorted per file, every
   disagreement between agents, every project-only fact left out, and the next step:
   "read `core/`, then run `/prefs-nt sync`".
