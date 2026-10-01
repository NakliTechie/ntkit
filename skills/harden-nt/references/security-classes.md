## Attack-class briefs for adversarial rounds (Phase 3)

When the surface is security-sensitive (takes untrusted input over a network,
holds another user's data, runs an LLM agent or MCP server, or ships to
Cloudflare/cloud infra), brief each adversarial agent with the contract plus one
class or domain section of this file, nothing else and no hint toward which one
is weak. Skip this file for a surface with no external input.

Condensed from [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill)
(MIT) — its `ATTACK-CLASSES.md` plus the domain files below.

**What counts as a finding, not a checklist deviation.** Name the lower-trust
principal, the input or action they control, the control that should stop them,
the boundary it crosses, and the concrete result: what they read, wrote, ran, or
broke that they should not have. Cite the ingress as `path:line`: where that
principal's data enters the code, or where an untrusted writer sets the field
that reaches the sink (adapted from
[google/mantis](https://github.com/google/mantis) `mantis-review`, Apache-2.0).
A source that only trusted code ever writes, such as server-authored config or
the app's own constants, is not attacker-controlled, and the finding falls.
Intrinsic flaws stand without a live caller: a hardcoded secret, broken crypto,
an injection inside a library function others will call. A missing best-practice
with no reachable result is a hardening note, not a finding. So is a
defense-in-depth gap where an outer layer already stops the attack.

**Which sections apply:**

| The app | Read |
|---|---|
| Any app | Universal classes (below) — always |
| LLM chat, RAG, an agent loop, an MCP server or client | AI & agents |
| A web app, API, or anything with sessions/JWT/OAuth | Web & auth |
| A browser SPA, extension, or single-file browser app | Client-side |
| Deploys to Cloudflare Workers, containers, or cloud IAM | Cloud & deployment |
| Has dependencies or CI workflows | Supply chain & CI |
| C/C++/Rust-`unsafe`/FFI, a parser, or a native binary | Memory safety & binary |
| A native desktop/mobile app, installer, helper, or webview bridge | Desktop, mobile & local IPC |
| gRPC/GraphQL/Protobuf, a queue, broker, or webhook | Protocols & messaging |
| Untrusted input can cost CPU/memory/disk/paid-API spend | Resource exhaustion |
| Multi-tenant storage, export/backup, or a delete/revoke promise | Data isolation & lifecycle |

### Universal classes

- **Injection** — including data stored safely, then reused in a dangerous sink.
- **Access control** — a second path to the same change with a weaker check; bulk skipping per-item checks.
- **Resource & file handling** — traversal via symlink or encoding; SSRF via redirect or DNS rebinding.
- **Crypto & secrets** — nonce reuse, and what a failed crypto op falls back to.
- **Business logic** — replayed steps, concurrent double-calls, data trusted as validated that never was.
- **Feature abuse & data leakage** — export bypassing checks; errors or timing revealing hidden records.
- **Chained vulnerabilities & trust boundaries** — B assuming more than A guarantees: truncation, coercion, tenant scope.
- **Wildcard** — the strangest code, comments claiming safety, API calls the UI never makes.
- **Obvious things** — debug routes, prod-switchable dev mode, credentialed wildcard CORS; trace impact first.

### AI & agents

Trace untrusted content → model or memory → capability or sink. Prompt
injection alone is not a finding: it needs a code-level boundary failure
downstream (authority, data, or a sink the requester can't reach directly). A
guardrail prompt is not a boundary; deterministic checks, scoped authorization,
isolation, and constrained credentials are.

- **Indirect injection via retrieved content** — attacker-writable docs or tool output in another principal's context.
- **Cross-tenant context bleed** — history, embeddings or prompt caches keyed too broadly.
- **Memory poisoning** — attacker content in durable memory shaping a later session.
- **Tool-argument injection** — a tool schema narrows shape, not authority; validate in the handler.
- **Excessive agency / confused deputy** — a handler that never re-checks the requesting principal.
- **Action-confirmation binding** — arguments swapped after approval, or a retry re-authorizing them.
- **MCP identity confusion** — routing by server or tool name, not the authenticated connection.
- **Insecure output rendering** — model output reaching HTML or command sinks unencoded.
- **Sensitive context extraction** — secrets or another user's data in the prompt, disclosed by the output.

### Web & auth

Ask whether the HTTP or identity layer can confuse *which* principal, request,
or token an operation belongs to; access control already asks whether the
principal *may* do it.

- **Request smuggling / desync** — front and back end disagreeing on request length.
- **Cache poisoning / cache deception** — unkeyed input changing the response; a private path cached as static.
- **Host/forwarded-header trust** — untrusted `Host` or `X-Forwarded-*` building reset links or routing tenants.
- **CSRF** — inventory every cookie-authenticated mutation, not only form posts.
- **Session fixation** — no rotation on login or privilege change; alive after logout.
- **JWT verification** — algorithm pinned server-side, never read from the header.
- **OAuth/OIDC callback binding** — exact `redirect_uri`, session-bound `state`, PKCE.
- **MFA/passkey assurance downgrade** — a first factor alone replacing the second.
- **Password reset / recovery** — one-time, expiring tokens; earlier tokens invalidated.
- **API-key scope** — a key reaching beyond its server-side record, or leaking into bundles.

### Client-side

Needs a controllable source (URL fragment, `postMessage`, storage,
`window.name`) and an executing or disclosing sink, with impact reaching
another origin or another user's session, not only the attacker's own data.

- **DOM-based XSS** — check framework auto-escaping before reporting.
- **Prototype pollution + gadget** — no reachable gadget, no finding.
- **`postMessage` trust** — acting on `event.data` without an exact origin check.
- **Credentialed CORS** — a reflected `Origin` with credentials allowed.
- **Service-worker cache confusion** — personalized responses served after logout.
- **Storage disclosure** — tokens readable by less-trusted same-origin script, or used after logout.
- **Clickjacking** — a state-changing action framable without `frame-ancestors`.

### Cloud & deployment

Source shows intent, not always live fact. Separate a control-flow bug the
source confirms from one that needs a deployed-environment check; the second
stays an open candidate naming the missing fact (see Applying it), never a
guess either way.

- **Workload identity overreach** — untrusted input choosing a target beyond the workload's role.
- **Unexpected reachability** — admin, debug or metrics ports open to a lower-trust network.
- **Trusted-proxy bypass** — identity headers trusted from peers outside the ingress.
- **Config precedence drift** — overlays disabling auth when deployed; render the *final* config.
- **Secret exposure** — secrets in logs, process args, build output, or shared volumes.
- **Signed-URL / bucket policy confusion** — principal, namespace and expiry not bound together.

### Supply chain & CI

- **Floating sources** — an unintended registry or namespace; pins to a branch, `@main`, or a floating major.
- **Privileged triggers** — `pull_request_target` or another fork-triggered event running contributor code with write tokens or secrets.
- **Script injection** — a branch name, PR title or issue body interpolated into a shell step, not passed via env.
- **Cache and artifact poisoning** — a lower-trust job writing what a higher-trust job restores and runs.
- **Known advisories** — run the ecosystem audit on the lockfile (`npm audit`, `pip-audit`, `osv-scanner`); rank each hit per the dependency-CVE cap.

### Memory safety & binary

For C/C++/Objective-C, Rust `unsafe`, FFI, parsers, loaders, and JITs. Re-derive
every bound and lifetime from attacker input and the worst caller. A crash or
sanitizer hit is a finding only when realistic untrusted input reaches it.

- **Out-of-bounds read/write** — recompute headroom after prefixes and padding.
- **Integer overflow/underflow/truncation** — `a - b` with `b > a`, `count * size`, `-1` as a size.
- **Use-after-free / double-free** — callbacks or iterators outliving the owner on error and cancel paths.
- **Type confusion** — a discriminant checked differently from the representation later read.
- **TOCTOU / data races** — unconfirmed without a repeatable schedule or thread sanitizer: name that missing fact.
- **FFI/ABI mismatch** — who frees the buffer; struct layout varying by build flag.
- **Untrusted loader path** — a privileged process loading code from a writable path.

### Desktop, mobile & local IPC

For native apps, installers, privileged helpers, deep links, and webview
bridges. Name the realistic local attacker first (another app or OS user, a
sandboxed child, an untrusted document); self-harm in your own account isn't a
boundary violation.

- **Deep-link / custom-scheme ambiguity** — a route mutating state without a one-time session binding.
- **Webview bridge origin confusion** — a native bridge reachable after navigation; check origin per call.
- **IPC peer-authentication gaps** — a claimed PID or bundle ID is not authentication.
- **Exported component overreach** — an app-internal operation invokable by other apps.
- **Privileged helper as confused deputy** — a helper that never authorizes its normalized argument.
- **Credential-store exposure** — token files or notification previews readable by another app.

### Protocols & messaging

For gRPC, GraphQL, Protobuf, custom binary protocols, queues, brokers, and
webhooks. "Internal" is not authentication: name the peer identity at every hop
and show how it becomes the principal used for authorization.

- **Interceptor coverage gaps** — auth on unary methods but not streams or gateway paths.
- **Peer identity vs. claimed principal** — mTLS authenticates the channel; a payload field picks the tenant.
- **Topic/queue scope gaps** — selecting another tenant's topic, wildcard or dead-letter route.
- **Idempotency gaps** — dedup missing, or keyed so it collides across tenants.
- **Replay / stale-message acceptance** — older state overwriting newer with no version check.

### Resource exhaustion

For anywhere untrusted input, files, or agent work can cost CPU, memory, disk,
connections, or paid-API spend. A missing rate limit alone isn't a finding;
check body caps, concurrency limits, and per-tenant quotas first. Never validate
by stress-testing a live or shared service; use small local fixtures and
asymptotic reasoning.

- **Superlinear parsing/matching** — regex backtracking or unbounded template expansion.
- **Decompression amplification** — limits re-checked after *every* expansion stage.
- **Unbounded accumulation** — sessions or jobs with no aggregate cap or cleanup on cancel.
- **Pre-auth work imbalance** — expensive work before authentication and the first rate gate.
- **Reachable fatal error** — untrusted input crashing a shared process.
- **Retry storms** — retries with no jitter, ceiling or circuit breaker.

### Data isolation & lifecycle

For multi-tenant storage, derived caches and search, exports and backups, and
any delete or revoke promise. A tenant field on a record is not isolation; find
the query, key, or policy that enforces it on every read and write path.

- **Missing tenant enforcement** — check background jobs, admin tools and imports, not only the API.
- **Cache/search/index ACL drift** — derived copies readable at the old permission.
- **Export/backup scope creep** — other tenants' data or soft-deleted rows in an export.
- **Soft-delete bypass** — a lookup, index or job ignoring the deleted flag.
- **Stale authorization after revocation** — sessions or queued jobs acting on revoked state.

### Applying it

A finding an agent returns is a path the map forgot: add it per Phase 5, then run
it through the same constructive → harden → verify sequence as any other path. A
candidate that needs a live dependency, provider config, or browser you can't
reach from this surface is not yet a path: name the missing fact and leave it
uncovered rather than guessing either way.
