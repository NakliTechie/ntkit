# fold — move inbox lines into the files they belong in

1. Read `inbox.md`. With no entries below its header line, report "inbox empty" and stop.
2. For each entry, decide where it goes. An entry from a hand edit keeps its indented block as written.
   - a fact or preference true for every agent → the matching `core/` file. Keep its date and reason.
   - true for one agent only → `agents/<agent>.md`, named exactly as that agent's row in
     `targets.tsv` (sync uses the file whenever it exists).
   - about one project only → append a dated bullet to that project's `plan/pending.md` when the
     project is on this machine; else leave the entry in the inbox and say why.
   - "removed N line(s), see drift/<file>" → open the drift copy, compare it with the current
     generated file, and treat the removal as a proposal for the owner. Do not delete the rule.
3. **Contradictions.** When an entry conflicts with an existing rule, keep both. Mark the new one
   `(conflicts with: "<short quote>", awaiting owner)` and list it in the report with your
   recommendation. Never pick a winner.
4. Remove only the entries you placed. Keep the header and every entry you could not place.
5. Run `python3 "$SKILL/bin/prefs_sync.py" --dir <folder>`, adding `--push` only when the owner granted
   it for this run. A non-zero exit is a failure: report its output and stop.
6. Run `python3 "$SKILL/bin/prefs_sync.py" --dir <folder> --check`; it must exit 0.
7. Report: how many entries went where, each contradiction with both quotes, what is left in the inbox
   and why, and the size of the largest generated file.
