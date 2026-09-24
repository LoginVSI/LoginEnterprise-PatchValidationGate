# One-off Actions acceptance

This exercise supports a tested preview, blog, Storylane walkthrough and product
requirements. Production promotion is simulated. The execution repository remains
public, and the development repository remains the sole source of reusable code.

## Verified results, 2026-09-23

Live validation used execution commit
`8ac4d9eabe60185886dd0ef79b318f3bf2b6f767`, exported from source
`c4e80c84f1bb1185a3117086ba49d387dcf715b8`. New source fixes were tested separately
and did not replace protected execution main during the exercise.

| Requirement | Result | Evidence |
| --- | --- | --- |
| Good update | Verified: both required applications PASS, one execution each | [Validation run](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35925744830) |
| Deliberate failure | Verified: one required application FAIL, the other PASS | [Failure run](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35926329590) |
| Failure evidence | Verified: unique failed execution joined to an application-failure Event by run/session/application; screenshot directly references that execution | Exact identifiers, image bytes and hash retained privately |
| Sanitized artifacts | Verified: both downloaded ZIPs match GitHub SHA-256 digests; manifests, private-evidence backlinks and private-value scans pass | [PASS artifact](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35925744830/artifacts/10779011660), [FAIL artifact](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35926329590/artifacts/10779940069) |
| Restoration after each scenario | Verified: 23.01 executable/version/hash, no disabled copy, fresh required-application PASS and drained sessions | Separate private supervision and readiness records |
| Failure issue | Verified open; promotion and Continuous Testing skipped | [Issue #4](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/issues/4) |
| Good-update issue closure | Not exercised: the validate-only runner could not execute promotion/handoff | [Issue #3 remains open](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/issues/3) |
| Manual approval and manual simulated promotion | Blocked: no verified authoritative approval-time producer satisfies the existing correlation contract; runner access was also validate-only | [Approval evidence](approval-evidence.md) |
| Actions Continuous Test handoff and new iteration | Not exercised: promotion did not complete and the runner allowed validation only | Earlier independent local workload observations remain in the [local walkthrough](tested-lab-walkthrough.md) |
| Protected execution-copy publication | Pending normal source and protected-main PR review | [Source PR #3](https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/pull/3), [source PR #4](https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/pull/4), [generated-copy PR #2](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/pull/2) |

The good workflow's validation job succeeded. The independent supervisor canceled
its blocked downstream flow, so the overall run is canceled. The deliberate-failure
workflow is failed, as expected. LE reported its run orchestration as successful
while the application execution failed. Neither top-level status replaces the
required-application verdict.

Raw responses and screenshot pixels remain private. The public artifacts contain
only the allowlisted projection. The screenshot was decoded and its relationships
and hash verified; it is not approved for public display without a separate visual
privacy review. GitHub artifacts have limited retention; private downloaded copies
and digest records are preserved for audit.

## Approval boundaries

The supervised runner authorized only the validate job and deregistered after one
job, so promotion and continuous jobs could not have run in this configuration even
with approval evidence. The promotion-approval environment did hold the manual
promotion job pending review. No approval was given.

The existing automatic path is separate: a fresh validation must bind auto mode,
pass both required applications and produce complete integrity-checked evidence.
Promotion requires identical policy bytes, the supported verdict:PASS and
results-complete guards, an issue record and the matching shared target lease.
The workflow then schedules validate, promote-auto and continuous-testing in that
order; promote-manual is skipped. All three required jobs need scoped runner access,
and recovery supervision must allow the handoff before stopping scheduling,
draining sessions and restoring the baseline. Automatic-mode acceptance does not
establish manual-approval provenance.

Protected-main PR review governs publishing the generated execution copy. The
protected environment governs human authorization of simulated promotion. The
existing handoff parser additionally requires an authoritative timestamp bound to
repository, workflow run, attempt, environment and reviewer.

The configured environment permits the operator to review their own workflow.
Neither that setting nor the parser requires a second independent human. Independent
time-evidence provenance does not mean an independent person's identity. Two GitHub
accounts owned by one person do not establish independent human review. No additional
collaborator was granted access, no approval-request PR mechanism was introduced,
and no environment or branch protection was bypassed.

The environment button alone cannot supply the missing timestamp provenance.
Job-start time, observation time and an operator-written timestamp are not substitutes.
The historical manual-mode good-update issue was therefore left open; that pass
did not accept promotion or its Continuous Test handoff. The later automatic-mode
results are recorded separately below. The operator's general authorization to test is not a
fabricated per-run approval record.

## Execution setup findings

The operator chose a temporary supervised laptop runner under a dedicated non-admin
account. Real processes under that account could not enumerate the everyday profile,
SSH/configuration directories or either control checkout tree, and could not read
the original encrypted lab credential files or Git configuration. Account-specific
deny entries were needed on the checkout roots because their prior ACLs allowed
Authenticated Users to modify files.

The runner shared the original canonical state directory and received access only
to that state and a new evidence directory. Path safety checks walk parent directories,
so the account also needed non-inherited attribute/traversal rights on those parents.
Those grants did not permit directory listing or reading credentials; the denial
probes passed again afterward. All temporary grants were journaled for cleanup.
This remains a shared Windows host, not VM isolation.

The reviewed execution workflows have no PR, pull_request_target, workflow_run or
reusable-workflow entry points and no caches. Hosted CI uses hosted runners. Live
execution requires the exact repository and main ref. Pinned actions, read-only
default permissions, protected main/environment, concurrency and artifact checks
remain intact. A controller-owned pre-job guard additionally restricted the runner
to one run, attempt, execution SHA, workflow, actor, validation job and input set.
It rejected synthetic alternate-ref, trigger, SHA, job and attempt mismatches in
both supported shells. One-job registration bounded lifetime; it was not treated
as an isolation mechanism.

Authenticated WinRM stalled for the control account until an explicit per-session
`NoProxyServer` setting was selected. Normal TLS checks remained enabled. The
runner account authenticated with its default proxy selection. The optional source
helper provides the explicit choice for installer checks and adapter operations,
including recovery. Acceptance recovery used the private supervisor's global
NoProxyServer session option on execution 8ac4d9e, which does not contain the helper.
The helper was live-checked only by a read-only installer-state query at source
2a065cf; adapter apply and revert through it have offline coverage only. See
[setup](setup.md#target-powershell-remoting).

The first Actions attempt failed during checkout, before configuration or target
mutation. A launched process must use the dedicated account's HOME, USERPROFILE,
APPDATA, LOCALAPPDATA, TEMP and PowerShell module paths. Explicitly setting those
paths resolved the checkout failure without exposing the control profile. The
failed setup attempt is retained as [run 35925205462](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35925205462).

A pre-dispatch baseline workload also exposed an offline assigned launcher. LE
returned launcherCapacityExceeded with zero application executions, and the gate
returned INCONCLUSIVE. After the existing launcher was brought online, a fresh
baseline workload passed and drained. Manual RDP responsiveness alone was not used
as proof of bootstrapper readiness. Unrelated tests and sessions were left unchanged.

## Recovery and closeout

The public validation command does not automatically restore after every verdict.
Recovery supervision ran in a separate control process with the original credentials
and byte-matched runtime inputs. It observed validation, terminated remaining workflow
work, checked natural test/session completion and installer idle state, restored the
baseline, and required a fresh passing workload. Cancellation was never used as proof
that guest sessions had drained. Uncertainty retained recovery-required status.

Both scenario journals reached restoration-verified with recoveryRequired=false.
The final designated state is the 23.01 baseline, executable present, disabled copy
absent, Application Tests finished, Continuous Testing disabled and sessions drained.
No production deployment or snapshot restoration occurred.

The one-job runners deregistered. Live workflow dispatch was disabled again, and all
eight task-created runtime secrets and five variables were removed. Original private
recovery credentials, evidence and journals remain available through the independent
audit. Local cleanup verified removal of the temporary account, profile, runner
directory, account password file and every journaled account-specific ACL entry.

The source fix passed 150 tests in PowerShell 5.1 and 7, lint in both shells, synthetic
PASS/FAIL/INCONCLUSIVE bundle verification and static workflow/pin checks. Its hosted
[source CI](https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/actions/runs/35922822624)
also passed. Final [source CI at 37df135](https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate/actions/runs/35928123767)
and [candidate CI at 2ac0b86](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35928425557)
each recorded 150 passed, zero failed and zero skipped in both shells. These are
offline checks; they do not establish live recovery through the helper or manual
approval acceptance.

## Automatic-mode acceptance, 2026-09-24 UTC

The authorized bounded batch used the existing `promotion_mode=auto` path in
[run 35938835197](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35938835197).
It ran execution `8ac4d9eabe60185886dd0ef79b318f3bf2b6f767`, exported from source
`c4e80c84f1bb1185a3117086ba49d387dcf715b8`. The newer source proxy helper was not
executed. Its live verification remains the earlier read-only query; apply and
revert through that helper remain covered offline.

| Stage | Observed result | Evidence |
| --- | --- | --- |
| Application validation | PASS; both required applications executed once with zero failures | [Validation artifact](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35938835197/artifacts/10783618332) |
| Automatic simulated promotion | Succeeded; `promotionMode=auto`, `approvedBy=policy`, `simulated=true` | [Promotion artifact](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35938835197/artifacts/10784171868) |
| Actions Continuous Test handoff | Succeeded; enabled scheduling confirmed, without claiming a completed workload | [Continuous artifact](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/actions/runs/35938835197/artifacts/10783643381) |
| Scenario issue lifecycle | Created, received validation/promotion/continuous results and closed by the workflow | [Issue #5](https://github.com/JoshuaKennedy234/LoginEnterprise-PatchValidationGate-Lab/issues/5) |
| Restoration | 23.01 version/hash independently verified; fresh baseline application workloads PASSed | Private identity-preserving recovery and baseline-readiness records |
| Bounded Continuous Test workload continuation | Both applications passed in fresh sessions on restored 23.01; controller-started after the Actions handoff | Separate private continuation observations, stop/drain and final preflight |
| Final cleanup | Continuous Testing disabled, designated appliance and native target sessions drained, recovery-required false; temporary runner resources removed | Private final preflight and cleanup journals |

All three downloaded artifact ZIPs matched GitHub's digests and their retained
runner output bytes. Validation bundle integrity and the private-manifest backlink
passed. Promotion and continuous records matched the validation hash; the continuous
job also consumed the independently transferred promotion hash. Artifact and workflow
log scans found none of the checked private configuration or credential values.

The dependency graph required `validate`, `promote-auto`, then `continuous-testing`.
The manual job was skipped. Three separate ephemeral registrations each authorized
only the required job in that run, attempt 1, trusted main SHA, workflow, actor and
exact automatic-mode input set. The pre-job guard passed 36 positive/negative checks
across both shells. Current public-repository controls required approval for all
external contributors. Actual non-admin exposure probes passed. This was a scoped
account on a shared laptop, not VM isolation.

The private supervisor initially assumed Continuous Testing would create a new run
ID. The appliance instead reused its persistent run identity. The supervisor stopped
scheduling during the new session's login, which was aborted before successful
application execution. Its recovery wait also encountered an uninitialized local
flag. Both errors and the original journal remain retained. No new update or break
was dispatched: identity-preserving recovery resumed with the original auto-mode
inputs, restored 23.01 and required fresh passing baseline workloads.

A separate bounded controller continuation then correlated fresh session timestamps
and execution relationships under that persistent Continuous Test run ID. Both
required applications completed successfully. Scheduling was disabled again and
appliance plus native target sessions were confirmed drained. This verifies a
controller-started workload continuation on the restored baseline, not a successful
Actions-started workload iteration on the updated target. The Actions handoff itself
verifies scheduling enablement, as its contract specifies.

GitHub runner registrations, all eight temporary secrets and five variables were
removed; live dispatch was disabled. Local account, profile, runner directory,
temporary credential file and journaled account-specific grants were removed.
Original evidence, recovery journals and controller credentials remain private.
The earlier deliberate-break evidence was reverified and reused without repeating
that scenario.

Manual approval remains separately blocked by authoritative approval-time provenance.
No manual approval was given, no upper-bound timestamp was substituted, and the
manual approval contract was unchanged. Historical manual-run issue #3 remains open;
deliberate-failure issue #4 remains open as expected. Only the fresh automatic-mode
scenario issue #5 closed through successful handoff. The generated execution
candidate requires normal protected review; tested execution main remains 8ac4d9e.

## Product requirements grounded in this pass

The reference provides application verdicts, immutable evidence checks, allowlisted
publication, durable target leases and separate handoff records. A native product
would need an approval decision with a native immutable audit timestamp; launcher
availability/capacity checks before mutation; secure worker identity and credential
lifecycle; and recovery supervision that survives worker failure.

It should expose orchestration status and application outcomes separately, explain
infrastructure INCONCLUSIVE results without requiring raw-log inspection, observe an
actual Continuous Test workload after enabling scheduling, and keep issue closure
aligned with the stages that completed. Temporary runner labels and registration
must not be presented as a security boundary. These are product requirements, not
capabilities newly proven by this reference.
