# schedule and unschedule — run sync every 15 minutes

A scheduled job does not load the shell profile, so resolve everything to absolute paths first:

- **Interpreter:** `command -v python3`, then confirm it runs the script:
  `"<python>" "$SKILL/bin/prefs_sync.py" --dir "<folder>" --dry-run` exits 0. Use that interpreter.
- **Script:** the absolute form of `$SKILL/bin/prefs_sync.py`.
- **Folder:** the absolute folder path. `NT_PREFS_DIR` is not set inside the job.
- **Push:** add `--push` only when the owner granted it for this run.
- **Environment:** when `CODEX_HOME` is set in the shell, carry its value into the job, or the job
  writes Codex's file to `~/.codex` instead. Carry any other variable a `targets.tsv` path uses.

## macOS (launchd)

`schedule`: write `~/Library/LaunchAgents/com.ntkit.prefs-sync.plist` with `ProgramArguments` set to
the interpreter, the script, `--dir`, the folder (and `--push` when granted), one array entry each, so
spaces need no quoting; `StartInterval` 900; `RunAtLoad` true; `StandardOutPath`
`/tmp/prefs-sync.out`; `StandardErrorPath` `/tmp/prefs-sync.err`; and `EnvironmentVariables` holding
the variables from the list above. Run `launchctl load <plist>`, wait 10
seconds, then check that `launchctl list | grep com.ntkit.prefs-sync` shows last exit status 0 and that
`/tmp/prefs-sync.err` holds no error.

`unschedule`: `launchctl unload <plist>`, delete that plist by name, and check that `launchctl list`
no longer shows the label.

## Linux (cron)

`schedule`: add one crontab line tagged `# ntkit prefs-sync`, every argument in single quotes, with
each `'` inside a path written as `'\''`, and the variables from the list above in front:
`*/15 * * * * CODEX_HOME='<dir>' '<python>' '<script>' --dir '<folder>' >> /tmp/prefs-sync.log 2>&1 # ntkit prefs-sync`.
Then run that command once by hand and check it exits 0, because cron gives no feedback until the
first run.

`unschedule`: remove only the line carrying that tag, and check `crontab -l` no longer shows it.

## Report

Name the job, its interpreter, its schedule, where its log goes, whether it pushes, the result of its
first run, and the `unschedule` command that removes it.
