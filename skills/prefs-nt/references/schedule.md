# schedule and unschedule — run sync every 15 minutes

The job runs `python3 ~/.claude/skills/prefs-nt/bin/prefs_sync.py --dir <folder>`, plus `--push`
only when the owner granted push for this run. Use the folder's absolute path: the job does not load
the shell profile, so `NT_PREFS_DIR` is not set there.

## macOS (launchd)

`schedule`: write `~/Library/LaunchAgents/com.ntkit.prefs-sync.plist` with `ProgramArguments`
`/usr/bin/python3`, the script's absolute path, `--dir`, the folder; `StartInterval` 900; `RunAtLoad`
true; `StandardOutPath` `/tmp/prefs-sync.out`; `StandardErrorPath` `/tmp/prefs-sync.err`. Then run
`launchctl load <plist>`, wait 5 seconds, and check `launchctl list | grep com.ntkit.prefs-sync`
shows exit status 0.

`unschedule`: `launchctl unload <plist>`, then delete that plist by name.

## Linux (cron)

`schedule`: add one crontab line tagged `# ntkit prefs-sync`:
`*/15 * * * * python3 <script> --dir <folder> >> /tmp/prefs-sync.log 2>&1 # ntkit prefs-sync`.

`unschedule`: remove only the line carrying that tag.

## Report

Name the job, its schedule, where its log goes, whether it pushes, and the `unschedule` command that
removes it.
