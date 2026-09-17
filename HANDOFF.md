# HANDOFF: Login Enterprise Patch Validation Gate

Last inspected: 2026-09-17
Owner: Joshua Kennedy, Login VSI
Repository: https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate (public, MIT)

This is project context, not a set of coding prompts. Joshua will provide future task prompts separately. Follow applicable agent instructions. Use code as evidence of implementation, docs as intended behavior, and genuine appliance captures as evidence of response shapes. Mocked tests do not establish live validation.

## Product rationale and boundaries

Security fixes arrive faster than deployment rings can absorb them. Security teams want patches out; EUC teams carry the consequences when an application breaks. Time in a ring often stands in for evidence about whether an organization's own applications still work on its changed image. Produce that evidence before users encounter the change, and dwell time becomes a policy decision.

The nine-stage loop remains: change detected, change applied to a validation target, Login Enterprise application test, results retrieval, deterministic policy verdict, approval or auto guardrails, deployment-system promotion, continuous testing, wait for the next change. The published figure places the reference implementation around stages 2 through 6 and the existing deployment system at stage 7, with preserved evidence and a person notified on FAIL or INCONCLUSIVE.

Login Enterprise validates. Policy evaluates. A person or the existing deployment system approves and promotes. PASS means policy passed for the tested workflows on the tested target. Coverage is the ceiling; it never means a patch is safe. Timeouts, infrastructure failures, and untrustworthy evidence are INCONCLUSIVE and require a person. Only PASS can proceed, with approval or satisfied auto guardrails. There is no AI in the verdict path.

This does not replace Intune, ConfigMgr, Autopatch, Citrix/Omnissa image tooling, or ServiceNow. Lab adapters own apply, verify, and revert; they are not a production deployment or rollback service. Production promotion is simulated in Part 2. Use continuous testing or continuous validation, never monitoring. Do not claim percentages of time saved, exposure reduced, or rings compressed, or make claims about specific customers. The defensible value is earlier workflow evidence, reproducible verdicts, and evidence preservation. The appliance already provides run comparison; the gate adds policy and orchestration.

## Local inspection baseline

The checkout was on `main`, tracking `origin/main`, at `580b6a71add260e4915cce83fb59c06632285b1d` (`Add project handoff`). No pre-existing tracked or untracked changes were reported. Origin fetch and push point to the repository above. Recent commits cover the handoff, workflow YAML, README status, contracts/setup/security docs, developer scripts, and lint/hosted CI. Remote state was not refreshed or checked online.

This inspection read the module, scripts, policies, workflows, tests, and project docs. It made no appliance calls, installed no dependencies, registered no runner, changed no GitHub settings, and ran no fresh tests. Documentation edits remain local for review.

### Built

The module manifest is `0.1.0`; the changelog still marks the release Unreleased. Five exported functions build a session (`Connect-LEGate`), read the version (`Get-LEGateVersion`), resolve an exact application-test name (`Resolve-LEGateTest`), start or reuse a named run (`Start-LEGateRun`), and poll/write `evidence/{changeId}/run.json` on completion or timeout (`Wait-LEGateRun`). Private helpers provide bearer authentication, GET-only retries, paging, token redaction, logging, UTC timestamps, and reason codes.

The smoke script supports a version check or a start-and-wait check. A successful smoke exit is not a policy PASS. Hosted `ci.yml` installs tooling and runs lint and mocked unit tests in Windows PowerShell 5.1. The saved September 11 report records 68 tests with zero failures. Earlier docs report successful tests on 5.1 and 7 and a version call against appliance 6.8.6. These are historical reports, not fresh verification here. Integration tests currently read version and resolve test names; the optional start test mentioned in their header does not exist.

### Scaffolded or missing

`validate-patch.yml` is dispatch-only with validate, manual promotion, auto promotion, and continuous-testing jobs. Its steps are TODOs and evaluation emits a fixed INCONCLUSIVE. It has no orchestration, credential wiring, issue integration, target serialization, approval-record capture, or cross-job evidence downloads. Upload points at the entire `evidence/` directory. Naming an environment in YAML does not establish that reviewer or branch protections exist.

Results retrieval, screenshot downloads, the pure evaluator, evidence manifest/summary, change adapters, issue handoff, promotion record, continuous-test start, and `scripts/Invoke-Gate.ps1` are absent. The adapter directory contains only its README. There are no change manifests, example bundles, runbook, or portability notes. The default policy still has a placeholder test name and an empty required-app array; its schema permits that array and does not enforce all planned preconditions.

### Real fixture coverage: none

`tests/fixtures/` contains only its README. No genuine successful, deliberately failed, infrastructure-error, failure-detail, or screenshot fixtures exist in this checkout. No local `evidence/` captures were found. Unit tests construct synthetic responses inline. Even the reported version call has no committed capture here. Modified mock data can test an edge case but cannot be the real failed run promised for Part 2.

## Approved Part 2 deliverables

Part 2, working title **Show Me the FAIL**, demonstrates a pinned third-party application update and an intentional application break on a disposable lab target. Choose 7-Zip or Notepad++ and record genuine before/after versions and installer provenance privately. Do not invent versions or substitute a registry flag for an application failure. Windows cumulative updates remain deferred.

The planned existing-test names are `patch-gate-app` and `patch-gate-continuous`; their existence is unconfirmed. Both should exercise Notepad plus the chosen demo app, with a visible action in that workload. The pipeline does not create tests. Two application runs of the same test, with distinct change IDs as run names, are the hero screenshot.

Remaining work includes:

- Retrieval of overview, sessions, executions, events, and failed-execution screenshots, retaining raw evidence before evaluation. Record performance signals without judging them while performance policy is disabled. Baseline policy remains deferred.
- A pure evaluator, policy validation, and manifest/verdict/summary export following `docs/contracts.md` and `docs/verdict.md`. Tests must cover PASS, FAIL, INCONCLUSIVE, malformed evidence, and retrieval failures using real fixtures plus clearly synthetic edge cases.
- `app-update`, `break`, and `noop` lab adapters with apply/verify/revert; orchestration, preflight, logging, and failure preservation. Planned gate exit codes are 0 PASS, 1 FAIL, 2 INCONCLUSIVE, distinct from current smoke exit codes.
- A GitHub Issue per change: open/reuse the matching change record, comment at stages, leave FAIL/INCONCLUSIVE open for investigation, and close after successful continuous-testing handoff.
- Manual approval via `promotion-approval`, auto promotion only after functional guardrails pass, a contract-compliant simulated promotion record, and starting the pre-existing continuous test.
- Sanitized PASS and FAIL bundles, change manifests, a reproducible runbook including restore/reset, README quickstart, and short Azure DevOps, GitLab, Jenkins, and ServiceNow translation notes. ServiceNow maps comments to work notes and evidence to attachments; it is not an integration.
- Live PASS and FAIL workflow demonstrations, screenshots, a reviewed Part 2 article, and socials. Offline tests and live acceptance are separate checks.

## Requirements to reconcile during implementation

### API shapes and evidence completeness

Use `docs/api-notes.md` for allowed appliance endpoints and parameters. Its source is an exported appliance spec, not fixtures in this repo. Several responses are labeled arrays, while its paging paragraph and `Get-LEGateAllPages` assume `{ items, totalCount, offset }`. Confirm each envelope, nested application fields, screenshot metadata/binary response, and pagination behavior from genuine captures and the matching spec. Record corrections in the notes; never guess fields or paths.

The paging helper stops on an empty page or missing total count and returns accumulated items; its page limit only warns. Retrieval must establish completeness and report unexpected termination, malformed pages, or truncation. Exercise real pagination with a small documented page size where possible, preserving request parameters and page provenance.

Require expected demo applications explicitly in policy. Do not derive required coverage from whatever appears in an overview. Missing, malformed, empty, or truncated evidence cannot yield PASS, including zero executions whose equal zero counts might otherwise appear successful. Complete evidence proving an expected app failed or never executed is FAIL; inability to establish coverage is INCONCLUSIVE. Infrastructure errors and timeouts take precedence. Confirm retry semantics before claiming the configured retry allowance is enforced.

The six current reason codes describe INCONCLUSIVE cases. The contracts require reason codes on FAIL too, but do not define an application-failure code. Resolve this gap explicitly across contracts/verdict docs, policy, code, and tests. Do not silently overload an infrastructure code.

### Run identity and shared-target state

Use a fresh change ID for every fresh demonstration, including separate local and workflow demonstrations. Resume only evidence for the same target, change/manifest, policy hash, and test. `Start-LEGateRun` currently matches only `testRunName` within the test and returns before checking policy. An optional hash in the comment does not enforce identity. This falls short of the key described in `docs/architecture.md`; reject mismatched resumes and never reuse an old success for a newly changed target.

Serialize changes to a shared target across local runs and workflows. A change-ID-only concurrency key cannot protect one VM from different changes. Reset to a known state between demos, verify the reset, and retain restoration evidence. Stop continuous testing and confirm it has stopped before modifying that target again. No stop endpoint is documented here; use the appliance UI until an authorized API path is documented from the spec.

### Contracts and the intentional break

Follow `docs/contracts.md`: adapters receive `operation`, `changeId`, `target`, and `parameters`; results contain `status`, `changeId`, `operation`, `target`, `details`, `startedAt`, and `finishedAt`, with optional `message`. Preserve the distinction between a valid result with failed status and failure to produce a valid document. Do not substitute the old prompt's action/timestamp shape.

Break verification must prove the intended app-only break was successfully applied so Login Enterprise can detect it. The broken app's inability to launch is the expected changed state, not an adapter verification failure. Failure to apply/verify the intended break is preflight-failed/INCONCLUSIVE, not a demonstrated FAIL. Keep login and launcher dependencies intact. Revert must restore and verify the known state; a revert failure is recorded separately and does not rewrite a verdict already produced.

Use the nested manifest and promotion handoff shapes, policy hash format, file hashes/sizes, `approvedBy`, `approvedAt`, and approved evidence manifest hash from the contracts. Preserve unknown fields. Document deliberate extensions, such as per-app summaries, commit SHA, capture provenance, or continuous-test status, in contracts and changelog. Define representation of unavailable run/test metadata in partial evidence without fabricating values. Resolve manifest self-hashing and later-record handling explicitly rather than adding an undefined bundle hash.

### Failure preservation, job transfer, and approval

Establish a recoverable evidence context before preflight. Preserve obtained responses and adapter results when orchestration, polling, retrieval, or issue calls fail; emit INCONCLUSIVE with diagnostics when validation cannot finish. `Wait-LEGateRun` currently writes after polling, so a thrown request can bypass evidence writing. Always-upload cannot preserve files that were never written. Later promotion or continuous-handoff failures retain the original verdict and record the later failure separately, without claiming a successful handoff.

Transfer evidence explicitly between jobs: upload a reviewed sanitized validation bundle, download that exact artifact in promotion jobs, and verify identity and manifest hash. Never rely on a surviving self-hosted workspace or jobs sharing a machine. Keep the approved bundle immutable. Upload later promotion and continuous-testing records as separately identified artifacts linked to that bundle, and pass their identifiers onward. Records must survive cleanup without overwriting the approved evidence.

`GITHUB_ACTOR` identifies the workflow initiator, not necessarily the reviewer. Obtain manual reviewer identity and approval time from authoritative approval evidence and retain its provenance. Do not infer approval from dispatch identity or invent a timestamp. Leave the handoff incomplete if approval evidence is unavailable. Auto records identify `policy` only after guardrails pass. Production promotion remains simulated.

### Public evidence and runner isolation

Keep original captures private. Before public artifact uploads, issue comments, example commits, or blog screenshots, create reviewed sanitized copies. Inspect JSON, logs, exception details, filenames, metadata, and screenshot pixels for tokens, real hosts/IPs/internal URLs, launcher/account names, customer identifiers, and identifying desktop content. Token masking alone is not sanitization. Hash the published sanitized bytes and preserve their relationship to private originals.

The tracked `tests/results/pester.xml` includes machine/account metadata. `.gitignore` has a malformed `Thumbs.dbtests/results/` entry. Flag these for separate cleanup before further publication; fixing ignore rules alone will not untrack an existing file. Do not repeat that metadata in new docs or examples.

Before live wiring, verify isolated self-hosted runner access, a dedicated minimally privileged service account, trusted workflow/branch restrictions, environment reviewer restrictions, and no fork/untrusted PR access to that runner. Dispatch-only YAML is not the whole boundary. Review action pinning, job permissions, artifact exposure/retention, workspace cleanup, and target access. No runner or GitHub setting was verified here.

## Local execution and private prerequisites

PowerShell 5.1 compatibility, one function per file, the thin HTTP wrapper, centralized logging/clock/reason codes, GET-only retry, and a pure evaluator remain technical rules. Do not add PSLoginEnterprise or generate a client. API version stays configurable with `v8-preview` as default; the earlier v7 comparison is in `docs/api-notes.md`.

Inspection found PowerShell 7.6.6 and Windows PowerShell 5.1.26100.9444, plus Git, GitHub CLI, and ripgrep. Windows PowerShell discovers Pester 5.7.1 and PSScriptAnalyzer 1.25.0. PowerShell 7 discovers Pester 5.7.1 but did not list PSScriptAnalyzer. Discovery does not prove runnable tooling: imports in 5.1 failed because execution policy blocked scripts/type data. Its policy list had every scope Undefined; PowerShell 7 reported LocalMachine RemoteSigned. Resolve execution prerequisites under the applicable machine policy in the intended shell before running scripts. No policy was changed here.

Windows PowerShell lists PowerShellGet 2.2.5/1.0.0.1 and PackageManagement 1.0.0.1. PowerShell 7 also lists PackageManagement 1.4.8.1. The historical installation mismatch and Save-Module workaround remain in `docs/setup.md`; no installation was attempted. Do not assume that earlier installation issue is the only local blocker.

| Input | Current wiring and unresolved work |
|---|---|
| Appliance URL/token | Connect accepts BaseUrl/ApiToken overrides, otherwise reads `LE_BASE_URL`/`LE_API_TOKEN`. Keep runtime values private. Historical version access does not confirm current read-results/start rights. |
| Certificate flag | Smoke and Connect accept `-SkipCertificateCheck`; neither automatically reads `LE_SKIP_CERT_CHECK`. Integration translates only the exact value `1`. The old handoff's `true` example was inconsistent. Implement and document one explicit conversion in orchestration/workflow wiring. Prefer valid certificate trust. |
| PowerShell 5.1 bypass | Connect installs a process-wide `ServerCertificateValidationCallback` returning true without restoration. Correct this before adding GitHub API calls to that process. PowerShell 7 uses per-request skipping. Do not describe current 5.1 behavior as appliance-scoped. |
| Target credential | Target identity, WinRM reachability, and remote versus local execution are unconfirmed. Planned `TARGET_USER`/`TARGET_PASSWORD` secrets have no consumers. Define PSCredential transfer to every adapter operation or deliberate current-credential/local execution. Never serialize credentials into JSON/evidence. |
| Demo inputs | Confirm target snapshot/reset, launcher/account readiness, workload, real versions/installers, test identities, and explicit required-app identities privately. Old examples are not runtime values. |
| GitHub access | Wire `GITHUB_TOKEN`, `GITHUB_REPOSITORY`, and least-privilege job permissions for issue/handoff calls. Runner labels, secrets, reviewers, and branch restrictions remain unverified. |

The API notes still label continuous handoff Part 3, while approved Part 2 includes starting an existing continuous test. The no-deployment language in `docs/ai-agents.md` continues to protect production/appliance configuration; approved Part 2 permits scoped lab adapters. Reconcile phase labels when implementing those components. Neither this scope nor an old prompt authorizes undocumented endpoints.

## Next execution checkpoint: genuine success and failure captures

Joshua's next action is one private lab fixture-capture session, followed by reviewed sanitized copies for the offline build. Capture evidence before implementing retrieval/evaluation or wiring the pipeline.

Confirm the disposable target can be restored and its workload exercises Notepad plus the chosen demo app. Keep continuous testing stopped. Capture a genuinely successful application run with a fresh change ID. Reset as needed, apply and verify a reversible app-only break, and capture another run under a new ID showing an application failure with login/connectivity intact. Restore the target immediately after failure capture and verify its known working state. Keep before/change/restore observations privately.

For both runs retain run, overview, events, sessions, and each session's app-execution responses. For failure include the relevant failure event/details present in documented responses, screenshot-list response, and actual screenshot download. Preserve request parameters, page boundaries/totals, API/appliance version, and consistent run/session/execution relationships. Confirm shapes against the spec; document discrepancies. If more failure detail requires an unmapped endpoint, add it from the spec first.

Completion check: sanitized genuine captures cover both scenarios; failed app and screenshot are traceable by their IDs; completeness/pagination is accounted for; and private restoration evidence confirms a usable target with continuous testing stopped. Editing successful JSON into a failed fixture does not satisfy this. Call these successful/failed appliance captures until the future evaluator produces PASS/FAIL bundles.

Joshua then supplies the implementation prompt. Offline implementation and tests precede runner/approval wiring and live acceptance. Each fresh demonstration uses a new ID and a verified target reset.

## Content, editorial preferences, and acceptance

Part 1, **Your Deployment Ring Is a Waiting Room | Workspace Weekly**, is published and its socials are posted. The old review/publish/Asana/posting checklist is historical. Its arc moves from patch pressure and ring dwell time to evidence, verdicts, Login Enterprise's role, the repo, and the Part 2 promise. Figure 1 is the loop. Keep public wording as conversations with customers rather than naming advisory-board participants; avoid test-count claims and dated roadmap promises.

Part 2 opens on the real FAIL: dispatch, issue, verified break, application failure, screenshot, skipped promotion, issue left open, restored target. Follow with good update, PASS, approval, simulated promotion, continuous test, and issue closure. Explain reproduction prerequisites and portability, then future scope, a scenario request, and a demo CTA. Never portray offline tests as a live demonstration. If live acceptance slips, state the limitation and leave those deliverables incomplete.

Capture the LE UI with both named runs, failed execution/screenshot, both issue trails, workflow awaiting approval, sanitized artifact, and continuous test running. Reuse the diagram or highlight its FAIL branch. Socials lead with the FAIL, following the existing LinkedIn/external Slack/internal sales and engineer email structure.

Joshua prefers direct, terse, casual guidance and concrete checkpoints. Keep work bounded to Part 2 and offline where possible. Public copy should be friendly, willing to challenge dwell time, and honest about what exists. Problem before product, no partner bashing, at most one metaphor per piece. No em dashes; avoid actually, critical, and matters in editorial copy. Vary sentence and paragraph lengths. Remove generic business language, repeated openings, concession/contrast formulas, symmetrical lists, and canned transitions. Prefer prose in articles/socials except link lists; technical tables/checklists are useful here.

Review drafts with Joshua's separate codex-writing-skills repository in this order: workspace-weekly, voice-and-tone, avoid-ai-style. Preserve factual claims and links, flag unsupported claims, and reread for repetition and unnatural cadence. This is a review preference, not an embedded prompt to execute verbatim.

Part 2 is done when real dispatches show both outcomes: good update produces PASS, reviewed evidence, manual approval, simulated promotion, continuous start and issue closure; verified break produces FAIL, failed-execution screenshot, skipped promotion and an open issue. Sanitized bundles, target restoration, lint/unit checks, reproducible runbook, README quickstart, portability notes, and reviewed article/social drafts must also exist. Current code does not meet this check.

## Deferred scope

Baselines/performance policy on top of appliance thresholds/comparison; image-level validation with a real Windows cumulative update on a snapshot-reverted VM; detection adapters for scanners/catalogs/Autopatch; real ServiceNow, Intune, Autopatch, Citrix, or Horizon handoffs; and customer interviews remain later work and do not block Part 2. Advanced auto guardrails beyond functional policy are deferred.

An optional Part 3 AI evidence explainer is read-only: explain the existing verdict, failures/screenshots, reason codes, and investigation leads with file citations. It must never run tests, call the appliance, edit policy/baselines, or replace the deterministic verdict. Consider it only after Part 2 ships. Production deployment remains outside this reference implementation.
