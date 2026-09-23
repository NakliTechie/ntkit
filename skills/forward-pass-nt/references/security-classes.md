## Deeper security hunting (optional, Phase 2)

The Security lens in `lenses.md` is the default pass — always run it. Read this
file too when the app is security-sensitive: it takes untrusted input over a
network, holds another user's data, runs an LLM agent or MCP server, or ships
to Cloudflare/cloud infra. Skip it for a solo local tool with no external input.

Condensed from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)
(MIT) — its `ATTACK-CLASSES.md` plus the domain files below.

**What counts as a finding, not a checklist deviation.** Name the lower-trust
principal, the input or action they control, the control that should stop them,
the boundary it crosses, and the concrete result: what they read, wrote, ran, or
broke that they should not have. A missing best-practice with no reachable
result is a hardening note, not a finding — say so and move on. Defense-in-depth
gaps are hardening notes too: if an outer layer already stops the attack, the
missing inner layer isn't a vulnerability.

**Which sections apply:**

| The app | Read |
|---|---|
| Any app | Universal classes (below) — always |
| LLM chat, RAG, an agent loop, an MCP server or client | AI & agents |
| A web app, API, or anything with sessions/JWT/OAuth | Web & auth |
| A browser SPA, extension, or single-file browser app | Client-side |
| Deploys to Cloudflare Workers, containers, or cloud IAM | Cloud & deployment |
| C/C++/Rust-`unsafe`/FFI, a parser, or a native binary | Memory safety & binary |
| A native desktop/mobile app, installer, helper, or webview bridge | Desktop, mobile & local IPC |
| gRPC/GraphQL/Protobuf, a queue, broker, or webhook | Protocols & messaging |
| Untrusted input can cost CPU/memory/disk/paid-API spend | Resource exhaustion |
| Multi-tenant storage, export/backup, or a delete/revoke promise | Data isolation & lifecycle |

Not covered here — pull the matching file from the upstream repo above when a
run needs that depth: none held back at the moment. If a domain this portfolio
doesn't touch shows up later, treat the upstream repo as the source to pull
from rather than inventing coverage from memory.

### Universal classes

- **Injection** — trace untrusted input to a dangerous sink: SQL, shell, HTML,
  template, file path, deserialization, log line. Check indirect paths too —
  data stored safely, then pulled into a dangerous context later.
- **Access control** — a check existing isn't the bar; it must check the *right*
  permission on the *right* resource. Look for a second path to the same state
  change that checks a weaker permission, a request field that overrides what
  the permission system meant to lock, and bulk/export endpoints that skip
  per-item checks.
- **Resource & file handling** — path traversal (incl. via symlinks/encoding),
  SSRF (incl. via redirects/DNS rebinding), unsafe deserialization, zip-slip,
  TOCTOU races on file operations.
- **Crypto & secrets** — weak randomness for tokens/keys/nonces, hardcoded
  secrets (incl. in logs/errors/URLs), missing HMAC verification, nonce reuse,
  timing side-channels on secret comparison, and what a failed crypto op falls
  back to.
- **Business logic** — can a flow's steps be skipped, reordered, or replayed?
  What does a concurrent double-call do (double-spend, double-approve, lost
  update)? Negative/zero/overflow values. Data trusted because "we validated it
  on the way in," read back from a path that never validated it.
- **Feature abuse & data leakage** — can export/backup pull data above the
  caller's access? Can import bypass normal validation? Does search/filter/sort
  leak the existence of things the caller can't see? Do error messages, timing,
  or response size distinguish "not found" from "no access"? Can a
  notification/webhook URL be pointed at an internal address?
- **Chained vulnerabilities & trust boundaries** — component A validates and
  hands off to B; does B assume more than A guarantees (truncation, type
  coercion, tenant scope)? Data safe in storage becoming a file path, regex, or
  template when reused elsewhere. A token/capability growing broader after
  refresh, cache, or role change than it started.
- **Wildcard** — no assigned category. Read the strangest code in the repo and
  ask why it exists. Read what a comment claims is safe and check the claim.
  What API calls are possible but the UI never makes them? Anything reverted in
  git history that looks like a security fix?
- **Obvious things** — grep for hardcoded secrets/passwords/tokens; an
  unprotected `/debug`, `/admin`, `/status`, `/.env` route; dev-mode reachable
  via env var, query param, or header in prod; unpinned dependencies with known
  CVEs; `eval`/`exec`/dynamic `import()` on untrusted input; wildcard CORS with
  credentials; cookies missing `HttpOnly`/`Secure`/`SameSite`; open redirects
  via `redirect`/`next`/`url`-style params; stack traces or SQL errors in prod
  responses. Trace impact before reporting — a missing flag on a
  non-sensitive cookie isn't a finding.

### AI & agents

Untrusted content → model or memory → capability or sink is the shape to trace.
Prompt injection alone is not a finding — it needs a code-level boundary
failure downstream: authority the requester lacks, data they can't read, or a
sink they can't reach directly. A guardrail prompt is not a security boundary;
only deterministic checks, scoped authorization, isolation, and constrained
credentials count.

- **Indirect injection via retrieved content** — a RAG doc, indexed page, email,
  or tool response an attacker can write, entering another principal's context.
- **Cross-tenant context bleed** — conversation history, embeddings, or prompt
  caches keyed too broadly; check the query and every cache key, not just a
  stored tenant field.
- **Memory poisoning** — attacker content or a model summary written into
  durable memory that shapes a later task, user, or privileged session.
- **Tool-argument injection** — model-produced arguments reaching SQL, shell,
  file, or URL-fetch without handler-side validation; a tool schema narrows
  shape, it doesn't establish authorization.
- **Excessive agency / confused deputy** — the agent runs under a broad service
  identity while the tool handler skips re-checking the requesting principal.
- **Action-confirmation binding** — a user approves one action; can execution
  swap the arguments, resource, or principal after approval? Does a retry
  re-authorize a mutated or duplicate side effect?
- **MCP identity confusion** — calls/results routed by attacker-influenceable
  server or tool names instead of the authenticated connection; can one server
  claim another's tool identity?
- **Insecure output rendering** — model output reaching HTML/Markdown/template/
  command sinks without that sink's required encoding.
- **Sensitive context extraction** — assembled prompt context containing
  credentials or another user's data that model output then discloses.

### Web & auth

Ask whether the HTTP/identity layer can confuse *which* principal, request, or
token an operation belongs to — access-control review already asks whether a
principal *may* do it.

- **Request smuggling / desync** — front end and back end disagreeing on
  request length (`Content-Length` vs `Transfer-Encoding`, HTTP/2 downgrade).
- **Cache poisoning / cache deception** — a request value that changes cached
  content but isn't in the cache key; a private dynamic path cached as if
  static.
- **Host/forwarded-header trust** — untrusted `Host`/`X-Forwarded-*` driving
  absolute URLs, tenant routing, or reset-link generation.
- **CSRF** — a state-changing endpoint reachable with only ambient cookies, no
  effective token or strict Origin/Referer check. Inventory every
  cookie-authenticated mutation, not just the obvious form posts.
- **Session fixation** — session ID not rotated on login/MFA/privilege change,
  or still valid after logout/password change/revocation.
- **JWT verification** — signature + algorithm pinned server-side (not from the
  token header), then `exp`/`nbf`/`aud`/`iss` checked; `kid`/`jku`/`x5u` treated
  as untrusted input.
- **OAuth/OIDC callback binding** — exact `redirect_uri` match, session-bound
  `state`, PKCE, ID-token audience/nonce.
- **MFA/passkey assurance downgrade** — can a valid first factor alone enroll
  or replace the second factor, with no fresh-auth requirement?
- **Password reset / recovery** — token randomness, one-time use, expiry, and
  invalidation of prior tokens on completion.
- **API-key scope** — a key authenticating to broader tenants/resources than
  its server-side record grants; keys leaking into client bundles, URLs, or
  logs.

### Client-side

Needs a controllable source (URL fragment, `postMessage`, storage,
`window.name`) and an executing or disclosing sink, with impact reaching
another origin or another user's session — not just the attacker's own data.

- **DOM-based XSS** — `location`, `document.referrer`, `window.name`, or
  message data reaching `innerHTML`/`document.write`/eval-like sinks. Framework
  auto-escaping is a real control; check it before reporting.
- **Prototype pollution + gadget** — attacker key reaching a deep-merge/path
  assignment, *and* a reachable gadget that consumes the polluted property.
  Pollution with no gadget isn't a finding.
- **`postMessage` trust** — a handler acting on `event.data` without an exact
  origin (and, where relevant, `event.source`) check.
- **Credentialed CORS** — server reflects/weakly-matches `Origin` while
  allowing credentials on sensitive responses.
- **Service-worker cache confusion** — a worker caching personalized responses
  without tenant/auth state in the cache key, serving them after logout.
- **Storage disclosure** — tokens or private data in `localStorage`/IndexedDB
  readable by a less-trusted same-origin script, or still used after logout.
- **Clickjacking** — a state-changing action framable with no
  `frame-ancestors`/`X-Frame-Options`.

### Cloud & deployment

Source expresses intent, not always live fact — separate a source-confirmed
control-flow bug from something that needs a deployed-environment check
(`needs_validation`, not a guess either way).

- **Workload identity overreach** — a pod/function/Worker identity that can act
  on tenants or resources beyond its role, with untrusted input selecting the
  target.
- **Unexpected reachability** — an ingress/security-group/port mapping exposing
  an admin, debug, or metrics endpoint to a lower-trust network.
- **Trusted-proxy bypass** — a backend trusting forwarded identity headers from
  peers outside the intended ingress, with no header-stripping check.
- **Config precedence drift** — dev defaults, env vars, or per-region overlays
  that silently disable auth or tenant scoping in a real deployed environment —
  render the *final* config, not just the base file.
- **Secret exposure** — secrets in logs, process args, build output, or broad
  volumes reachable by another workload.
- **Signed-URL / bucket policy confusion** — a signed URL or object policy not
  binding principal, object namespace, and expiry together.

### Memory safety & binary

For C/C++/Objective-C, Rust `unsafe`, FFI, parsers, loaders, and JITs. Re-derive
every bound and lifetime from attacker-controlled input and the worst caller,
not a typical test vector — a crash or sanitizer hit is a finding only when a
realistic untrusted input reaches it.

- **Out-of-bounds read/write** — a length, offset, or terminator reaching a
  buffer without a correct bound; recompute headroom after prefixes/padding.
- **Integer overflow/underflow/truncation** — `a - b` with `b > a`,
  `count * element_size`, a 64-bit length narrowed to 32-bit, `-1` becoming a
  huge unsigned size.
- **Use-after-free / double-free** — an owner released while a callback,
  timer, iterator, or cached raw pointer can still reach it; check every error
  and cancellation path, not just the happy path.
- **Type confusion** — a tag/vtable/union discriminant checked differently
  from the representation later read.
- **TOCTOU / data races** — a check-then-use gap across threads, a shared
  cache mutated during a parse. Needs a repeatable local schedule or a thread
  sanitizer to confirm — a hypothetical interleaving without one stays
  `needs_validation`.
- **FFI/ABI mismatch** — caller and callee disagree on who owns/frees a
  buffer, or a struct layout differs by build flag/architecture.
- **Untrusted loader path** — a privileged process loading a library/plugin
  from a path a less-trusted principal can write to, or resolving a bare name
  through an attacker-influenceable working directory.

### Desktop, mobile & local IPC

For native apps, installers, privileged helpers, deep links, and webview
bridges. Name the realistic local attacker first (another app, another OS
user, a sandboxed child, an untrusted document) — self-harm within your own
account and authority isn't a boundary violation.

- **Deep-link / custom-scheme ambiguity** — another app or page invoking a
  route that mutates state or completes auth without a current-session,
  one-time callback binding.
- **Webview bridge origin confusion** — a JS-to-native bridge meant only for
  packaged content, reachable from a remote or attacker-controlled frame after
  a navigation, redirect, or popup. Check origin at call time, not just on
  initial load.
- **IPC peer-authentication gaps** — a Unix socket, named pipe, XPC, or
  loopback listener accepting a lower-trust peer without checking OS peer
  credentials or code identity. A claimed sender field (PID, bundle ID,
  process name) is not authentication.
- **Exported component overreach** — a mobile activity/receiver/provider, or a
  local automation endpoint, externally invokable for an operation meant only
  for the app itself.
- **Privileged helper as confused deputy** — a low-privilege caller selecting
  a privileged command/file/user through a sudo/polkit/UAC/XPC helper that
  doesn't independently authorize the normalized argument.
- **Credential-store exposure** — a keychain/keystore item, token file, or
  clipboard/notification preview readable by another app or profile with less
  authority than intended.

### Protocols & messaging

For gRPC, GraphQL, Protobuf, custom binary protocols, queues, brokers, and
webhooks. "Internal" is not authentication — name the peer identity at every
hop and show how it becomes the application principal used for authorization.

- **Interceptor coverage gaps** — an authn/authz interceptor wired to unary
  methods but not streams, reflection, health checks, or gateway-transcoded
  paths.
- **Peer identity vs. claimed principal** — mTLS/workload identity
  authenticates the channel, but a caller-controlled field in the payload
  selects the user or tenant used for the actual operation.
- **Topic/queue scope gaps** — a publisher or subscriber able to select
  another tenant's topic, wildcard, or dead-letter route; tenant text inside a
  payload is not isolation.
- **Idempotency gaps** — a retry or redelivery repeating a side effect because
  deduplication is missing or keyed wrong (colliding across tenants).
- **Replay / stale-message acceptance** — older state (a revoked membership, a
  canceled action) arriving after newer state and overwriting it, with no
  sequence/version check.

### Resource exhaustion

For anywhere untrusted input, files, or agent work can cost CPU, memory, disk,
connections, or paid-API spend. A missing rate limit alone isn't a finding —
check body/message caps, concurrency limits, and per-tenant quotas first. Never
validate by stress-testing a live or shared service; use small local fixtures
and asymptotic reasoning instead.

- **Superlinear parsing/matching** — small input driving catastrophic regex
  backtracking, recursive validation, or unbounded template expansion.
- **Decompression amplification** — a compressed/nested/encoded input
  expanding far past the checked transfer size (zip bombs and friends), with
  limits verified after *every* expansion stage, not just the first.
- **Unbounded accumulation** — sessions, cache keys, subscriptions, or pending
  jobs growing without a per-item and aggregate cap, or without cleanup on
  disconnect/timeout/cancel.
- **Pre-auth work imbalance** — expensive parsing, crypto, or external calls
  happening *before* authentication and the earliest rate gate.
- **Reachable fatal error** — untrusted input reaching a panic/abort/unhandled
  exception in a shared process, not an isolated per-request worker.
- **Retry storms** — timeouts or dependency errors triggering unbounded
  synchronized retries with no jitter, ceiling, or circuit breaker.

### Data isolation & lifecycle

For multi-tenant storage, caches/search built from primary data, exports and
backups, and any explicit delete/revoke promise. A tenant or owner field on a
record is not isolation by itself — find the query, key, or policy that
actually enforces it on every read and write path.

- **Missing tenant enforcement** — a read/update/delete/list query that
  identifies an object without binding to the authenticated tenant, or trusts
  a body field to supply that identity. Check background jobs, admin tools,
  and import paths, not just the main API.
- **Cache/search/index ACL drift** — a record's ACL changes but a cached,
  indexed, or preview copy isn't invalidated, and stays readable at the old
  permission level.
- **Export/backup scope creep** — an export or snapshot pulling in other
  tenants' data, soft-deleted rows, or fields above the requester's normal
  access.
- **Soft-delete bypass** — a direct lookup, search index, or background
  processor ignoring the "deleted" flag and returning or acting on the record
  anyway.
- **Stale authorization after revocation** — a membership removal or secret
  rotation not invalidating sessions, caches, or already-queued jobs that keep
  authorizing on the old state.

### Applying it

Same discipline as the base lens: `confirmed` needs source evidence plus, where
you can run it locally and safely, a bounded reproduction. A candidate that
needs a live deployment, provider config, or browser you can't check from
source becomes a normal forward-pass finding with the missing fact named
explicitly — don't guess it either way, and don't silently drop it.
