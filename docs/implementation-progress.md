# Implementation progress

Updated 2026-09-18. Repair pass from 90189be verified offline. No appliance access or live workflow dispatch.

## Repair checkpoint

Fixed: restoration invalidation/recovery before mutation, successful restoration before optional reporting, locked promotion state check/recording, scalar event validation and polling/request deadlines. Regression tests exercise interrupted/failed restoration, reporting failure, stale promotion/continuous handoff, lock ownership, malformed events and late completion through the affected functions.

Partially resolved: approval-file delivery waits at most 120 seconds and checks repository/run/attempt/environment/reviewer. Authoritative approval-time acquisition remains externally blocked; matching envelope fields do not prove provenance. The exact source/access/correlation prerequisite is in [approval evidence](approval-evidence.md). The [first-capture bootstrap](first-live-capture.md) now includes exclusive ownership, independent recovery, actual commands/UI steps and restoration verification.

| Final repair verification | Windows PowerShell 5.1 | PowerShell 7 |
|---|---|---|
| Full offline Pester suite | 112 passed, 0 failed, 0 skipped | 112 passed, 0 failed, 0 skipped |
| PSScriptAnalyzer | No findings | No findings |
| Synthetic scenarios and bundle integrity | PASS, FAIL, INCONCLUSIVE; all verified | PASS, FAIL, INCONCLUSIVE; all verified |

Workflow YAML/pins/gate conditions and promotion state-variable checks, skill structure/example integrity, and the bundled skill validator passed. A PowerShell 5.1 lock holder blocked a PowerShell 7 contender using the same local state directory and case-normalized target. New documentation command blocks parsed without execution, and local links passed. Final diff/whitespace and private-data review passed; private audit/captures, NUnit reports and scenario output remain ignored and excluded from the repair commit.

Failure encountered and resolved: the initial approval/deadline targeted run had 6 passes and 2 failures because the new delivery function was absent from the module manifest export list. Added the export; both final full suites include and pass those tests. The earlier 36-test PowerShell 7 lifecycle/normalization/polling run also passed. No assertions were weakened. All results are offline; they do not establish actual MSI recovery, appliance semantics, shared-runner locking or live approval provenance.

Next concrete operator action: reserve exclusive ownership of the disposable target, stop continuous testing and verify an independent recovery baseline, then follow first-live-capture.md for the supervised baseline/failure/export/restore session. Private capture is conditional on those prerequisites. Full demonstration remains blocked on genuine API/installer/restoration acceptance, runner protections and authoritative approval-time acquisition.

## Original implementation checkpoint

- [x] Paths, certificate isolation, strict paging, policy validation and pure evaluator.
- [x] Retrieval, normalization, private evidence integrity and publication projection.
- [x] Lab adapters, credentials, durable target identity/locking, resume and recovery.
- [x] GitHub reporting, approval checks, simulated promotion, continuous handoff and workflows.
- [x] Synthetic scenarios, private capture tooling, evidence-explainer skill and documentation.
- [x] Fresh full suites, lint, static checks, bundle inspection and staged review.
- [x] Implementation committed and pushed normally to origin/main as 2d12b87.

## Original verification on 2026-09-18, before this repair

| Check | Windows PowerShell 5.1.26100.9444 | PowerShell 7.6.6 |
|---|---|---|
| Complete offline Pester suite | 98 passed, 0 failed, 0 skipped | 98 passed, 0 failed, 0 skipped |
| PSScriptAnalyzer | No findings | No findings |
| Synthetic scenarios | PASS, FAIL, INCONCLUSIVE; all bundles verified | PASS, FAIL, INCONCLUSIVE; all bundles verified |

The tests run the actual gate, collection, normalization, evaluator, exporter, publication, approval parser and continuous handoff together with external HTTP/remoting replaced. Covered cases include successful manual and auto simulation, application failure with binary screenshot retrieval, timeout, infrastructure/API errors, malformed/partial/cancelled/internal-error results, failed adapter verification, incompatible resume, tampering, reporting and later handoff failure, and restore behavior. Adapter worker tests also exercise real file operations and mocked installer failure/checksum boundaries. None proves real target restoration.

Workflow YAML, pinned action references, non-PASS/skipped-job gate checks, skill frontmatter/references/adversarial fixture and example hashes passed. The skill-authoring validator reports valid. These are structural checks, not actual Actions execution or model-based skill evaluation.

Staged example bytes independently passed manifest hashes and listed sizes. Whitespace review passed; no private capture/config/report additions or credential/local-account patterns were found. The generated NUnit report is removed from tracking and preserved locally. Ignored .private output remains local. CRLF example bytes are preserved by attributes, with CR recognized as a line ending.

Implementation commit 2d12b87 was pushed normally to origin/main. No release, live workflow dispatch, lab mutation or GitHub settings change was performed. This documentation checkpoint records the delivery result.

Next unfinished project action: Joshua's private baseline/failure capture session in live-acceptance.md. Keep continuous testing stopped; capture genuine success and a reversible application failure, then restore and verify the target.

Live prerequisites remain: reviewed genuine response mappings/pagination, configured application IDs and pinned installers, real success/failure screenshots, verified restoration, isolated runner/protected environment settings, and authoritative approval-time evidence. GitHub review history alone does not document approval time. See api-assumptions.md. Manual handoff stays incomplete without that evidence. The blog's live results remain pending.
