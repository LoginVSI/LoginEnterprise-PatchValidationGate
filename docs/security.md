# Security and publication

Keep original responses, screenshots, target names, credentials, approval originals and NUnit metadata private. Use access-controlled evidence/state roots outside the checkout. Cleanup must not destroy recovery state.

Publish-LEGateEvidence verifies the bundle and creates an allowlisted copy with aliased change/run/application IDs. It omits arbitrary text, raw responses, adapters, and all screenshot pixels. It hashes published bytes and links to the private manifest hash. Hash aliases are not a guarantee against correlation of low-entropy identifiers. Review before external sharing.

Images require explicit human review of pixels and metadata, redaction, and review of the resulting copy. Automated publication never includes screenshots. Private originals remain available.

SHA-256 detects changes relative to a trusted independent hash; it is not a signature. Consumers reject unsafe paths, reparse points, missing/extra files, and hash/size mismatches.

The persistent PS5.1 certificate bypass is removed. PS7's optional exception applies only to appliance requests. GitHub and pinned installer downloads use normal TLS without redirects. Target HTTPS remoting always validates its certificate normally, independently of LE_SKIP_CERT_CHECK. Target authentication uses Negotiate; no Basic authentication, TrustedHosts changes or certificate-check bypasses are supplied.

## External settings before live wiring

Follow [GitHub secure-use guidance](https://docs.github.com/en/actions/reference/security/secure-use). Repository controls include dispatch-only live execution, trusted main/repository checks, pinned actions, environment-variable inputs, scoped permissions, target concurrency without cancellation, and explicit artifact transfer.

YAML does not configure external protections. Verify an isolated Windows runner, least-privilege service account, runner-group restrictions to trusted workflows, no untrusted PR/fork access, protected main, promotion-approval reviewers and deployment branches, secret access, maintained Node 20-compatible runner, private storage ACLs and retention.

All operators/runners must use one canonical target alias and shared state location. Locks protect cooperating callers, not arbitrary admins. Cancellation does not prove a target idle. Disable continuous scheduling and drain active sessions in LE before restoration or another mutation.

Local GitHub authentication uses explicit GITHUB_TOKEN and GITHUB_REPOSITORY. Workflow jobs use github.token with declared permissions. GITHUB_ACTOR is the initiator, not the reviewer. Manual approval must retain real reviewer and timestamp evidence.
