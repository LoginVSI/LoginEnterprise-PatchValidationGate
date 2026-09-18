# Integrating the gate into a change pipeline

This repository provides PowerShell entry points, scoped disposable-lab adapters, JSON evidence, GitHub issue reporting and dispatch-only GitHub Actions orchestration. Detection of a new package, patch or image is external. A person or your pipeline decides when to invoke validation.

The reference uses accessible building blocks, not a promise of zero-cost operation. Login Enterprise, Windows targets, runner capacity and your deployment infrastructure have separate licensing and operating requirements.

## Existing external changes

The `noop` adapter can validate a target changed by another system. After user setup, private capture confirmation and exclusive ownership, a caller can use:

```powershell
$changeId = 'external-' + [guid]::NewGuid().ToString('N')
& .\scripts\Invoke-Gate.ps1 -ChangeId $changeId -PolicyFile policies/demo.local.json -ChangeManifest examples/changes/noop.json -ResponseProfile config/response-profile.local.json -Adapter noop
```

This uses the private environment variables from [setup](setup.md). Noop performs no installation, independent version check or restoration. Its skipped apply/verify results do **not** prove an external installation succeeded. Your deployment system must finish and verify the intended change before invoking the gate and retain that outcome separately. A gate PASS describes the observed workload state only. If restoration is needed, use the external system's approved recovery procedure, verify the target independently and follow the [durable-state recovery rules](runbook.md#recovery). A noop revert only updates this gate's lifecycle; it cannot undo the external change.

## Extension examples

These are integration designs, not shipped connectors:

| Platform | Where it could fit | Obligations retained by the integration |
|---|---|---|
| Azure DevOps | Invoke scripts from a protected pipeline; use environment approval and pipeline artifacts. | Exclusive target ownership, independent artifact hash and actual reviewer/time evidence. |
| GitLab | Invoke from protected jobs, serialize with resource_group and transfer artifacts. | Trusted runners/variables, explicit approval contract and durable recovery across jobs. |
| Jenkins | Use credential binding, a lockable target resource and audited input approval. | Immutable evidence transfer, verified hashes and recorded deployment outcomes. |
| ServiceNow | Map change issues to change records, work notes and sanitized attachments. | An authorized connector must implement the reporting/approval contract; ticket status alone is not deployment success. |
| Intune or Configuration Manager | Deploy to an isolated validation ring before calling this gate. | Confirm installation/version and reboot completion using that platform; implement production-ring promotion and verify its outcome. |
| Image tooling | Build and boot a candidate image, invoke workload validation, then publish through your image pipeline. | Retain image identity, recovery baseline and verified publish/deployment results. |

Preserve the [adapter, verdict, evidence and promotion contracts](contracts.md). FAIL and INCONCLUSIVE block promotion. PASS can enter approval/guardrails but the supplied promotion stage only writes a **simulated** record. A real integration must replace that stage and adjust its downstream validation to require genuine deployment success before continuous handoff; changing a label or reusing a simulated record is insufficient.

The supplied handoff starts an existing continuous test and checks enabled scheduling. LE performs subsequent sessions and native notifications. There is no resident gate controller watching later Events, creating new changes or automatically repeating apply/validate/promote/revert. Configure operational monitoring separately.
