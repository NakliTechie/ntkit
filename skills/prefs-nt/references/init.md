# init — create the folder and draft core/ from what the agents already have

1. **Resolve the folder.** `dir=` if given, else `${NT_PREFS_DIR:-~/.agent-prefs}`, made absolute. If it
   holds `targets.tsv`, stop (guard). Announce the path, and say that `NT_PREFS_DIR` in the shell
   profile moves it. A folder inside another git repo works, but sync skips git there: say so.
2. **Copy the template.** Copy `$SKILL/references/template/` into the folder. Rename `gitignore` to
   `.gitignore`. Create `drift/`.
3. **Find each agent's real file.** For each row of `targets.tsv`, note whether its parent folder exists
   (the agent is installed) and whether the file exists, with its size. Drop no rows: an agent installed
   later is picked up by the next sync. Then check the settings that move or hide a file:
   - Codex: `$CODEX_HOME` (default `~/.codex`) sets the folder. A non-empty `AGENTS.override.md` there
     makes Codex ignore `AGENTS.md`; report it and ask whether to fold its rules in and empty it.
   - Gemini CLI: `context.fileName` in `~/.gemini/settings.json` can rename `GEMINI.md`. When it is
     set, change the row to that name.
   - amp also loads `~/.config/AGENTS.md`. Read it as another original in step 5.
   - goose reads `.goosehints` only with its Developer extension on; say so when goose is installed.
   Report each setting you cannot check, not as a pass.
4. **Save the originals.** Copy every existing file from step 3 to
   `drift/<agent>-before-adoption-<YYYY-MM-DD>.md`, never overwriting a file already there.
5. **Draft core/.** Read every saved original. Sort each rule or fact into the template section it
   belongs to:
   - true for every agent → the matching `core/` file, replacing its HTML comment;
   - true for one agent only (its tool names, its own memory habits) → `agents/<agent>.md`;
   - about one project only → leave it out and list it in the report, with the project it names.
   Keep each rule's wording, date and reason. Where two agents' files disagree, put the rule in each
   agent's own `agents/` file, not in `core/`, and list the disagreement.
   A long section such as a style guide or a playbook goes into its own file in the folder, and `core/`
   gets one line saying when to read it. Keep each generated file small: every agent loads it in every
   session. Codex reads its global file in full; its 32 KiB budget (`project_doc_max_bytes`) applies
   to the project `AGENTS.md` files it gathers, which share the context with this one.
6. **Preview.** Run `python3 $SKILL/bin/prefs_sync.py --dir <folder> --dry-run` and show its output:
   which files the first sync would write, and their sizes.
7. **Offer git.** If the folder is not inside a git repo, run `git init` and make a first commit. Do
   not create a remote: that is outward-facing, so offer it as a command the owner runs.
8. **Report** in plain prose: the folder path, each agent found, each setting from step 3, the rules
   sorted per file, every disagreement between agents, every project-only fact left out, and the next
   step: "read `core/`, then run `/prefs-nt sync`".
