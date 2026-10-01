## Phase 6 — Probe every public hostname anonymously (hosted mode; not optional)

A tunnel publishes whatever listens on the local port, with the local port's trust model: a service safe on `127.0.0.1` is open to the internet once a hostname points at it. Probe each public hostname as a stranger with no cookie, no key and no signature, **before** the link goes to anyone.

Incident: a local S3 stand-in run with no identities accepted anonymous list, get and put; through the tunnel, anyone could have listed, read and written the bucket. The fix was an identities file giving the app's own key full rights and nobody else any.

### What to run, per hostname

Record each command and its status code. Use a probe object name that cannot collide (`ntkit-probe-<random>.txt`).

**Storage hostnames** (S3-compatible or any object store):
- List the root: `curl -s -o /dev/null -w '%{http_code}' https://<files-host>/` → must be 401 or 403.
- List the bucket: `curl … https://<files-host>/<bucket>/` and `…/<bucket>?list-type=2` → 401 or 403.
- Write: `curl … -X PUT --data probe https://<files-host>/<bucket>/ntkit-probe-<random>.txt` → 401 or 403.
- Read a known object without a signature (take a key from a presigned URL the app issued, strip the query) → 401 or 403.
- Positive control: the same object through the app's presigned URL → 200. A probe where everything fails, the app included, proves nothing.

**App hostnames:**
- A staff or admin page and a state-changing API route, with no cookie → the app's refusal (401, 403, or a redirect to sign-in), never data.
- `/.env`, `/.git/config`, `/node_modules/`, and any debug or metrics route → 404.
- `/demo` → 200 is expected (fictional personas, by design). It must not list anyone who is not in the personas file.

**Every hostname:** a hostname the ingress config does not name → 404 from the catch-all rule.

### Verdict

- Any anonymous list, read or write that succeeds is a **blocker**. The run does not print the public link. If an anonymous write succeeded, delete the probe object with the app's signed credentials. Then fix the service (require signed requests, drop the route, or bind it elsewhere), and probe again.
- All refusals plus the positive control → record the date and the codes in the protocol file's safety rails (Phase 7), and go on.
- Re-run this probe after any change to the ingress config, the storage settings, or the app's route guards.
