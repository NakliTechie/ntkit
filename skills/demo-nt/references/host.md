## Phase 5 — Host it: a public URL from this laptop (hosted mode only)

Run this phase only when the run was given `host=<hostname>`. Without it the demo stays local, and this file is not read.

The shape: the app, its worker and its storage run on this machine and listen on `127.0.0.1`. A **named Cloudflare tunnel** (`cloudflared`) carries one public hostname per local service. Three launchd agents (app, worker, tunnel) keep it up across crashes and reboots. Nothing is deployed anywhere else.

### Authority (repeats the root stop-lines)

- The zone is the registered domain of `host=`. Passing it grants exactly: one tunnel named `<project>-demo`, and one DNS record per hostname the run was given (`host=`, and `files=` when present), all in that zone.
- **Never** create a Cloudflare account, an API token, or a record in any other zone. Never pass `--overwrite-dns`. An existing record at a hostname stops the phase: report it and ask.
- **User step:** `cloudflared tunnel login` opens a browser, where the user signs in and picks the zone. The command cannot do this and must not try. Print the command, say which zone to pick, and wait.

### Steps

1. **Check the tools.** `cloudflared --version` (macOS: `brew install cloudflared`). No Cloudflare account, or the zone is not on it → stop with that reason.
2. **Authorise (user step).** If `~/.cloudflared/cert.pem` is missing, ask the user to run `cloudflared tunnel login` and pick the zone of `host=`. A `cert.pem` that already exists may be for another zone; step 4 catches that.
3. **Create or reuse the tunnel.** `cloudflared tunnel list` first; reuse `<project>-demo` if it exists, else `cloudflared tunnel create <project>-demo`. The credentials file lands in `~/.cloudflared/<tunnel-id>.json`. It stays there: never copy it, its id or `cert.pem` into the repo, a commit, or a report.
4. **Route each hostname.** `cloudflared tunnel route dns <project>-demo <hostname>`, once per hostname. Read the FQDN the command prints. If it is not exactly the hostname (a cert for another zone appends that zone), stop: tell the user which stray record to delete in the dashboard and to re-run `cloudflared tunnel login` for the right zone.
5. **Write the ingress config** at `~/.cloudflared/<project>-demo.yml`:

   ```yaml
   # <project> public demo (fictional data), served from this laptop.
   tunnel: <tunnel-id>
   credentials-file: <home>/.cloudflared/<tunnel-id>.json
   ingress:
     - hostname: <host>
       service: http://127.0.0.1:<demo-port>
     - hostname: <files-host>          # only when the app hands out presigned storage URLs
       service: http://127.0.0.1:<storage-port>
     - service: http_status:404        # everything else
   ```

6. **Write the demo settings file** outside the repo, `~/.config/<project>-demo/env`, mode `0600`. It holds, by the app's own names:
   - the demo port, and the non-production mode (Phase 3 says why);
   - `ORIGIN=https://<host>`, and `RP_ID=<host>` when the app uses passkeys (a passkey enrolled on `localhost` does not work on the public host);
   - a **separate demo database** URL and name (never the dev or any real database);
   - a **fresh random secret** (`openssl rand -base64 48`), never the dev default;
   - `TRUST_PROXY=1` or the app's equivalent: every request now arrives from `cloudflared` on `127.0.0.1`, so client-address rate limits and audit rows need the address from the forwarded header;
   - the public storage endpoint (`https://<files-host>`) when there is one;
   - the persona-file env var (Phase 2), and the base URL the seed calls.

   No mail or SMS provider key goes in it; the dev stand-ins stay active.
7. **Public-origin settings in the app.** Check each, and fix the app where it reads a hard-coded origin:
   - **CSP**: `img-src`, `connect-src` and `media-src` name the storage origin the browser actually fetches (`https://<files-host>`), taken from settings.
   - **Presigned URLs** are signed for the public storage host, because the signature covers the `Host` header. Sign with the public endpoint, not the internal one.
   - **Cookies** are `Secure` on an `https` origin; origin checks on state-changing requests compare against `ORIGIN`.
8. **Install three launchd agents** in `~/Library/LaunchAgents/`, labelled `<reverse-domain>.<project>-demo.{app,worker,tunnel}`. Shape of each:

   ```xml
   <key>Label</key><string><reverse-domain>.<project>-demo.app</string>
   <key>WorkingDirectory</key><string><repo></string>
   <key>ProgramArguments</key><array><string>/bin/sh</string><string>-c</string>
     <string>set -a; . "$HOME/.config/<project>-demo/env"; set +a; exec <absolute-path-to-runtime> <entrypoint></string></array>
   <key>RunAtLoad</key><true/><key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>10</integer>
   <key>StandardOutPath</key><string><home>/Library/Logs/<project>-demo/app.log</string>
   <key>StandardErrorPath</key><string><home>/Library/Logs/<project>-demo/app.log</string>
   ```

   The worker is the same with its own entrypoint. The tunnel runs `<absolute-path>/cloudflared --no-autoupdate --config <home>/.cloudflared/<project>-demo.yml tunnel run <project>-demo`. Use absolute paths: launchd's `PATH` is minimal. Load with `launchctl bootstrap gui/$(id -u) <plist>`; stop with `launchctl bootout gui/$(id -u)/<label>`. On Linux, three `systemd --user` units with `Restart=always` take the same shape.
9. **Database and storage survive a reboot** through the container runtime (`restart: unless-stopped`), which needs Docker Desktop, or its equivalent, set to start at login. That is a user setting; name it, do not change it.
10. **Check from outside.** `curl -s https://<host>/health` returns the app's healthy body, and `https://<host>/demo` lists the personas. Then Phase 6, before anyone gets the link.

Worked example: samvad serves `samvad.<zone>` (app on 8090) and `samvad-files.<zone>` (local S3 storage on 8333) from one tunnel, with settings in `~/.config/samvad-demo/env` and three launchd agents.
