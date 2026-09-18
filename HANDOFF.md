# Handoff: Login Enterprise Patch Validation Gate

Updated 2026-09-18. Owner: Joshua Kennedy, Login VSI.
Repository: LoginVSI/LoginEnterprise-PatchValidationGate, public, MIT.

This is project context. Joshua supplies future task prompts separately. Code establishes implementation; genuine captures establish API shapes. Synthetic data and mocked tests are never live results.

## Product rationale

Security teams need fixes deployed while EUC teams carry application consequences. Deployment-ring dwell time often substitutes for evidence about the organization's own workflows. This project collects that evidence before promotion, so dwell time can be a policy decision.

The loop is change, lab apply/verify, existing LE application test, collection, deterministic policy, approval/guardrails, simulated production promotion, continuous testing, and issue outcome. Login Enterprise validates; policy evaluates; a person or existing deployment system approves and promotes. PASS only describes covered workflows on the tested target. Coverage is the ceiling, not a safety guarantee. No AI is in the verdict path.

This does not replace Intune, ConfigMgr, Autopatch, image tooling or ServiceNow. The lab adapters are not a production rollback service. Use continuous testing or continuous validation, not monitoring. Do not claim percentages of time saved, reduced exposure, compressed rings, or specific customer results.

## Implemented offline

The PowerShell 5.1-compatible module now includes strict paging; overview/comparison, sessions, executions, events, measurements and screenshot collection; explicit response normalization; pure functional evaluation; policy validation; evidence export/integrity; and allowlisted public copies.

App-update, break and noop implement apply/verify/revert with explicit credentials or deliberate local/current credentials. Pinned MSI provenance, checksum, bounded execution and file-version verification protect the demo path. Break verification proves the intended executable-only broken state. Restoration is separate.

Invoke-Gate establishes evidence before preflight, binds durable resume identity to exact configuration and target, serializes target mutation, retains ownership after timeout, collects/evaluates/exports, and reports issues. Promotion and continuous handoff consume immutable evidence hashes and retain separate outcomes. Production promotion is simulated.

The live Actions workflow is dispatch-only with trusted-ref checks, target-aware concurrency, pinned actions, protected manual environment, explicit credentials and artifact transfer. Hosted CI is independent of lab secrets/access. External runner/environment protections are not configured merely by naming them.

The read-only evidence-explainer skill is included now, with synthetic PASS/FAIL/INCONCLUSIVE examples and adversarial text checks. It cannot call APIs, run adapters/tests, change policy, approve promotion or override a verdict.

## Verification and limits

See docs/implementation-progress.md for the latest executed checks. Full-flow synthetic tests use the real gate, collectors, normalizer, evaluator, exporter, integrity checker, publisher, approval parser and handoff, replacing external HTTP/remoting boundaries. Separate adapter tests exercise real file operations with mocked installer/download boundaries.

There are no genuine successful, failed, infrastructure or screenshot captures in this repo. Live acceptance, runner settings, actual restoration and actual GitHub approval remain pending. The historical version-call report does not validate this pipeline.

All unresolved response fields/envelopes and required captures are centralized in docs/api-assumptions.md. The example response profile is synthetic and cannot be used for live evaluation. Capture-confirmed is an operator attestation backed by reviewed private evidence, not a label to change to unblock a run.

GitHub review history establishes reviewer identity but documents no approval timestamp. Manual handoff fails unless matching authoritative time evidence is supplied and retained. GITHUB_ACTOR is not the reviewer. Auto mode supports only functional PASS and complete-results guards.

## Next live checkpoint

Joshua should perform one private baseline/failure capture session on the disposable target. Configure patch-gate-app and patch-gate-continuous with Notepad and the chosen demo application, keep continuous testing stopped, capture a genuine success and verified reversible app-only failure, then restore and verify the initial state.

Use scripts/Export-LiveCapture.ps1 with supplied run IDs, new private directories and reviewed response mappings. Completion: all session/execution/page relationships are accounted for, the failed execution links to actual screenshot bytes, the profile is confirmed against captures/spec, both required application IDs are configured, and restoration is recorded.

Then follow docs/live-acceptance.md: fresh IDs for good update and break, real PASS/manual approval/simulated promotion/continuous start/issue closure, real FAIL/skipped promotion/open issue, and verified reset between demos. Stop continuous testing before modifying the shared target. Never delete a timeout lease to assume the target is free.

## Part 2 deliverables and editorial preferences

Part 1, Your Deployment Ring Is a Waiting Room | Workspace Weekly, is published and its socials are posted.

Part 2, Show Me the FAIL, opens on a genuine failure: dispatch, issue, verified break, LE failure and screenshot, skipped promotion, open issue, restored target. Follow with a good pinned application update, PASS, approval, simulated promotion, continuous testing and issue closure. The existing tests must show visible application actions. Use 7-Zip or Notepad++ with verified private installer/version data; do not invent package values or fake a failure with edited success JSON.

The code, runbook, sanitized examples, portability notes and explainer are included. Genuine workflow demonstrations, reviewed public screenshots, the finished article and socials remain live/editorial deliverables. Do not write the finished article from synthetic examples. Capture the two LE runs, failure detail, both issue trails, approval wait/provenance, artifact integrity, simulated promotion and continuous state.

Joshua prefers terse, practical guidance and concrete checkpoints. Public prose should be conversational, problem before product, without hype or partner bashing. Use at most one metaphor per piece. No em dashes; avoid actually, critical and matters in editorial copy. Vary sentence/paragraph lengths and remove repeated openings, symmetrical lists and canned transitions. Prefer prose for articles/socials, technical tables for reference.

Review article drafts using Joshua's separate codex-writing-skills repository in order: workspace-weekly, voice-and-tone, avoid-ai-style. Preserve factual claims/links, flag unsupported claims and reread for cadence. This is a review preference, not an embedded coding prompt.

## Deferred scope

Production deployment integrations, Windows cumulative-update orchestration, scanners/catalog detection, real ServiceNow integration, baseline/performance policy and statistical qualification, advanced auto guardrails, and customer interviews remain extensions. Optional appliance comparison is retrieval only. No release/tag should be created before live acceptance.
