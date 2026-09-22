# Runbook

## Offline checks

Try scripts/Invoke-OfflineScenario.ps1 as shown in [user setup](setup.md). Contributors run the full suites and lint in both shells using [contributor instructions](contributing.md). FullFlow.Tests exercises real orchestration, collectors, normalization, evaluator, exporter, publication, approval parser and handoff while replacing external HTTP/remoting boundaries. Synthetic examples alone are narrower than these tests.

## Configure the disposable lab

1. Create/configure existing LE tests named patch-gate-app and patch-gate-continuous. Both must exercise Notepad and the selected demo application with a visible action. The gate does not create tests.
2. Disable continuous scheduling in the LE UI and wait until its active sessions have drained. The gate requires isEnabled=false and no active sessions for that continuous test. No stop endpoint is implemented; keep unrelated tests/operators off the reserved target too.
3. Prepare a restorable target with the initial pinned MSI version in C:\LEGateDemo\<application>. Workloads must launch that exact executable. The adapter only supports its validated demo-app path and executable.
4. Copy policies/default.policy.json to policies/demo.local.json, examples/changes/app-update.json to examples/changes/demo.local.json, and the response profile example to config/response-profile.local.json. Configure real application IDs, both MSI versions, HTTPS URLs, SHA-256 checksums, product codes, MSI directory property and observed file versions. Verify these privately from the actual installers. Placeholders are rejected.
5. Follow [first private capture and restoration](first-live-capture.md) to bootstrap genuine success/failure responses before invoking the gate. It includes exclusive ownership, independent recovery, LE UI steps, draft mappings, adapter commands and verification. Do not change synthetic provenance merely to bypass preflight. See [API assumptions](api-assumptions.md).

Use trusted appliance TLS. Set LE_BASE_URL, LE_API_TOKEN, LE_TARGET, LE_STATE_ROOT and LE_PRIVATE_ROOT privately. Set LE_API_VERSION explicitly to v8-preview; follow [version assessment](api-notes.md#version-comparison-and-upgrades) before changing it. State/evidence directories must be access-controlled, outside checkout for workflows, and shared consistently by all callers. Set LE_TARGET_TRANSPORT=HTTPS and LE_TARGET_PORT=5986 for a trusted HTTPS listener as described in [target remoting setup](setup.md#target-powershell-remoting). Supply PSCredential for remote execution or explicitly choose -UseCurrentCredentials. Add -Local only for deliberate execution on the target itself. Credentials are never manifest inputs.

## Capture an existing run

After configuring private environment variables:

```powershell
pwsh -NoProfile -File scripts/Export-LiveCapture.ps1 -TestRunId <actual-run-id> -OutputPath <new-private-directory> -ResponseProfile config/response-profile.local.json
```

Angle-bracket values are placeholders, not runnable values. Without ResponseProfile, collection preserves partial responses for profile review. It starts no tests and publishes nothing. Use a new output directory for each capture. Save version/spec and before/change/restore observations privately too.

## Validate and restore

In a PowerShell session:

```powershell
$credential = Get-Credential
.\scripts\Invoke-Gate.ps1 -ChangeId <fresh-id> -PolicyFile policies/demo.local.json -ChangeManifest examples/changes/demo.local.json -ResponseProfile config/response-profile.local.json -Adapter app-update -Credential $credential -TargetTransport HTTPS -TargetPort 5986
```

Use -Adapter break for the deliberate failure demonstration. It renames only the selected demo executable after establishing the desired version. Verify means the intended broken state exists, so LE can observe failure. It does not break login or launcher components. Noop is available with examples/changes/noop.json for externally changed targets, but it does not verify installation or restore the external change. See [external-change integration](portability.md#existing-external-changes).

The script exits 0 PASS, 1 FAIL, 2 INCONCLUSIVE or orchestration/reporting failure. Smoke exits remain separate: 0 successful smoke/completed successful run, 1 request/start error, 2 timeout, 3 completed non-success. Smoke success is not gate PASS. Add -ReportIssue with explicit GITHUB_TOKEN and GITHUB_REPOSITORY only when authorized to post. Add -PublicationPath pointing to a new directory to create a sanitized projection. Review it before sharing.

Resume with the same arguments and -Resume only. Exact configuration bytes, target, adapter, mode, test and change identity must match. The lease also records target transport and port; changing either blocks resume and revert before mutation. Leases from earlier releases have no recorded transport. Supply the intended settings explicitly when recovering them, including HTTPS/5986 if an earlier HTTP attempt failed. The next lease write records those settings without changing the original identity. Interrupted apply/start still requires -RecoveryConfirmed after investigation. Resume does not reapply. Fresh demonstrations require fresh IDs and restored state.

After the run is confirmed completed and continuous testing is stopped, repeat the original arguments with -Revert. Before adapter mutation, the gate persists reverting under the target lock. Verified restoration is recorded as reverted before optional issue reporting. A reporting error exits 2 but cannot make the old PASS reusable. Failed restoration records recovery-required; an interrupted process can leave reverting. Both block resume, promotion and continuous handoff. These uncertain stages, like interrupted apply/start, require -RecoveryConfirmed after an operator has checked LE and target state. That switch acknowledges recovery investigation; it does not prove restoration.

## Recovery

Timeout leaves durable ownership in place because LE may still be using the target. Wait or stop using supported LE UI controls, confirm completion/idle, then resume collection or explicitly revert. Never delete the lease to release a possibly active target. A process crash after PUT may leave no run ID; investigate in LE and perform explicit recovery rather than issuing another start.

Polling checks its deadline before requests and before accepting completion, including late responses. HTTP timeout, retry backoff and polling sleep use the remaining budget where the underlying cmdlet permits. Subsecond request budget is treated as exhausted, never as an unlimited timeout. A transport operation can return late; its available response is retained and the gate remains INCONCLUSIVE. Collection afterward can preserve more evidence and is separate from the run observation budget.

Failed installer, reboot-required exit, failed restore, or ambiguous version requires operator recovery. Preserve the lease and private diagnostics. Installer timeout is bounded; it is not proof the system has returned to its prior state. Restore the lab snapshot if necessary and document/verify the result before a fresh change.

Policy/profile/manifest mismatch requires the original configuration for recovery. Do not edit state to reuse another change's success. A later continuous or issue failure preserves validation and writes a separate handoff error; investigate before retrying the handoff.

## GitHub Actions

Before dispatch, complete [security settings](security.md). Configure secrets LE_BASE_URL, LE_API_TOKEN, LE_TARGET, TARGET_USER, TARGET_PASSWORD, LE_POLICY_JSON, LE_CHANGE_JSON and LE_RESPONSE_PROFILE_JSON. Configuration JSON materializes at the default *.local.json paths. Dispatch paths must match those files. Variables LE_STATE_ROOT and LE_PRIVATE_ROOT point outside checkout. LE_SKIP_CERT_CHECK uses explicit true/false; the PowerShell 5.1 workflow requires trusted TLS.

Configure these repository Actions variables for target HTTPS:

| Variable | Value |
|---|---|
| LE_TARGET_TRANSPORT | HTTPS |
| LE_TARGET_PORT | 5986 |
| LE_SKIP_CERT_CHECK | false (appliance TLS only) |

Keep LE_TARGET as a secret containing the target DNS name matching its certificate, such as validation-target.example.test. TARGET_USER and TARGET_PASSWORD remain secrets for the explicit target credential; do not put them in variables, manifests or committed files. Configure the target HTTPS listener, TCP 5986 reachability and certificate trust for the runner account using [setup](setup.md#target-powershell-remoting). The workflow uses Negotiate authentication and normal target certificate validation. HTTP compatibility requires LE_TARGET_TRANSPORT=HTTP and LE_TARGET_PORT=5985; omitted settings retain that default. There is no automatic HTTPS-to-HTTP fallback.

The live workflow does not restore automatically. For operator restoration, run Invoke-Gate.ps1 with the original inputs, -Revert, -TargetTransport HTTPS and -TargetPort 5986, using the same durable state root and target credential. Do not change remoting variables while a target has an unrestored lease.

Use the canonical demo-lab target alias. All jobs must reach the same durable state store; they do not rely on the same checkout. The workflow downloads and checks exact validation artifacts and keeps later promotion/continuous records separate. Only complete successful PASS validation enables either promotion job; the unselected job being skipped does not block continuous handoff.

Manual mode uses protected promotion-approval. GET review history supplies the actual reviewer. Authoritative approval-time acquisition remains an external blocker. See [approval evidence](approval-evidence.md) for the researched limits and exact prerequisite. No supported, verified collector is supplied by this repository.

The protected job waits at most 120 seconds for atomic delivery to LE_APPROVAL_TIME_EVIDENCE, then requires matching repository, workflowRunId, workflowRunAttempt, environment and reviewer. The file must also contain kind github-approval-time-evidence, an actual approvedAt (UTC Z), and source (GitHub URL). Delivery alone, matching fields or a URL do not establish authoritative provenance. Preserve the underlying source privately. Missing, malformed, stale or ambiguous evidence fails closed. Never use environment created_at/updated_at, observation time or GITHUB_ACTOR as substitutes.

Auto mode records policy as approver after both supported guardrails. Unknown guardrails block it. Promotion is simulated in both modes. The issue closes only after continuous handoff and required reporting succeed. Handoff confirms isEnabled=true on readback, not a completed workload session. If enablement is not observed, investigate before retrying; a start request is never blindly retried.

Both promotion jobs now require LE_STATE_ROOT and LE_TARGET. Promotion holds the shared target lock while checking the exact validation identity and reusable state and writing the record. It releases that lock before continuous handoff acquires it independently and rechecks state. A restoration between those stages prevents continuous start; the earlier promotion record remains a historical event, not current authorization to start.

## Evidence explainer

Use [Explain existing evidence](explain-evidence.md) for Codex discovery, explicit Claude loading and copy/paste prompts. The skill stays read-only; structural checks do not establish model compliance.
