# Contracts

Three boundaries where something outside this repo plugs in. Each is a plain JSON shape with no dependency on a particular vendor. The point is that Intune, ConfigMgr, Autopatch, a Citrix or Omnissa image pipeline, or ServiceNow can sit on either side of the gate without the gate knowing which one it is.

None of these are implemented yet. This document fixes the shapes so the implementations, when they come, do not have to negotiate.

All timestamps are UTC ISO 8601 with millisecond precision and a `Z` suffix, for example `2026-09-11T20:30:15.250Z`. All ids are strings. Unknown fields must be ignored by readers and preserved by anything that copies a document.

## 1. Change adapter contract

A change adapter puts the validation target into the changed state and can take it back out. The gate calls it; the adapter owns everything about how the change is applied. The reference adapter will install a pinned application update. A real one might call Intune, run a ConfigMgr deployment, or swap a Citrix image layer.

### Invocation

An adapter is a script or executable with three operations. The gate invokes one operation per call and passes the same three inputs each time:

| Input | Type | Meaning |
|---|---|---|
| `operation` | `apply`, `verify`, or `revert` | What to do |
| `changeId` | string | The change under validation. Same value the gate uses for the test run name and the evidence folder. |
| `target` | string | Identifier of the validation target. Meaning is adapter-specific: a hostname, a device id, an image name. |
| `parameters` | object | Adapter-specific settings from the policy or workflow inputs. May be empty. |

For a PowerShell adapter that is `.\adapter.ps1 -Operation apply -ChangeId CHG-1 -Target vt-01 -Parameters '{...}'`. For anything else it is the equivalent. The adapter writes exactly one JSON document to standard output and exits 0 when it produced a valid document, non-zero only when it could not.

### Result document

Every operation returns the same shape.

| Field | Type | Required | Meaning |
|---|---|---|---|
| `status` | `succeeded`, `failed`, or `skipped` | yes | Outcome of this operation. `skipped` means the target was already in the requested state, which makes `apply` and `revert` idempotent. |
| `changeId` | string | yes | Echo of the input. |
| `operation` | string | yes | Echo of the input. |
| `target` | string | yes | Echo of the input. |
| `details` | object | yes | Adapter-specific evidence. Free-form, but see below. |
| `startedAt` | timestamp | yes | When the operation began. |
| `finishedAt` | timestamp | yes | When it ended. |
| `message` | string | no | One line a person can read. |

`details` is where the adapter proves what it did: package name and version before and after, the deployment id it created, the command it ran, the reboot it needed. The gate copies `details` into the evidence manifest without interpreting it, so put in whatever a reviewer would want to see.

A `failed` status from `apply` stops the gate with `preflight-failed` and INCONCLUSIVE, because a target that never received the change tells you nothing about the change. A `failed` status from `verify` does the same. A `failed` status from `revert` is logged and surfaced but does not change the verdict, since the verdict was already produced.

### Example

```json
{
  "status": "succeeded",
  "changeId": "CHG-2026-0911-01",
  "operation": "apply",
  "target": "validation-target-01",
  "details": {
    "package": "ExampleApp",
    "versionBefore": "3.4.1",
    "versionAfter": "3.4.2",
    "installer": "ExampleApp-3.4.2.msi",
    "installerSha256": "0000000000000000000000000000000000000000000000000000000000000000",
    "rebootRequired": false
  },
  "startedAt": "2026-09-11T20:01:02.000Z",
  "finishedAt": "2026-09-11T20:03:40.512Z",
  "message": "Installed ExampleApp 3.4.2 over 3.4.1"
}
```

## 2. Gate output contract

The gate produces two documents plus the raw files they point at. Together they are the evidence bundle. The bundle is produced on every run, PASS or not.

### verdict.json

Defined in `docs/verdict.md`. Repeated here so this page is complete.

| Field | Type | Meaning |
|---|---|---|
| `verdict` | `PASS`, `FAIL`, or `INCONCLUSIVE` | The one thing a downstream system branches on. |
| `reasonCodes` | array of strings | Empty on PASS. On FAIL and INCONCLUSIVE, one or more codes from the list in `docs/verdict.md`. |
| `changeId` | string | The change under validation. |
| `testName` | string | Application test name as resolved on the appliance. |
| `testRunId` | string | The appliance run id the verdict was evaluated from. |
| `policyName` | string | `name` from the policy file. |
| `policyHash` | string | SHA-256 of the policy file, `sha256:` prefixed. |
| `promotionMode` | `manual` or `auto` | Requested mode. |
| `evaluatedAt` | timestamp | When the evaluator ran. |
| `summary` | string | One paragraph a person can read. |

```json
{
  "verdict": "PASS",
  "reasonCodes": [],
  "changeId": "CHG-2026-0911-01",
  "testName": "Patch Gate - Office",
  "testRunId": "3f1c9a2e-0000-4000-8000-000000000001",
  "policyName": "default-functional",
  "policyHash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "promotionMode": "manual",
  "evaluatedAt": "2026-09-11T20:45:10.004Z",
  "summary": "All 4 required applications executed with 0 failures across 3 sessions. Results complete."
}
```

### manifest.json

The evidence manifest lists what is in the bundle, where it came from, and how to check it has not changed.

| Field | Type | Meaning |
|---|---|---|
| `manifestVersion` | string | `1` for this shape. |
| `changeId` | string | The change under validation. |
| `generatedAt` | timestamp | When the manifest was written. |
| `appliance` | object | `apiVersion` used and `currentVersion` from `GET /system/version`. No hostname. |
| `test` | object | `id` and `name` of the application test. |
| `testRun` | object | `id`, `state`, `result`, and `testRunName` from the run. |
| `policy` | object | `name`, `hash`, and `path` relative to the repo root. |
| `adapter` | object or null | The `apply` and `verify` result documents from the change adapter, or null when no adapter ran. |
| `files` | array | One entry per file in the bundle. |
| `files[].path` | string | Relative to the bundle root. |
| `files[].kind` | string | `run`, `verdict`, `sessions`, `app-executions`, `events`, `measurements`, `screenshot`, `report`, or `summary`. |
| `files[].sha256` | string | Hex digest of the file. |
| `files[].bytes` | integer | File size. |

```json
{
  "manifestVersion": "1",
  "changeId": "CHG-2026-0911-01",
  "generatedAt": "2026-09-11T20:45:11.200Z",
  "appliance": { "apiVersion": "v8-preview", "currentVersion": "6.8.6" },
  "test": { "id": "7a0d4c11-0000-4000-8000-000000000002", "name": "Patch Gate - Office" },
  "testRun": {
    "id": "3f1c9a2e-0000-4000-8000-000000000001",
    "testRunName": "CHG-2026-0911-01",
    "state": "completed",
    "result": "successful"
  },
  "policy": {
    "name": "default-functional",
    "hash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "path": "policies/default.policy.json"
  },
  "adapter": null,
  "files": [
    { "path": "run.json", "kind": "run", "sha256": "1111111111111111111111111111111111111111111111111111111111111111", "bytes": 2048 },
    { "path": "verdict.json", "kind": "verdict", "sha256": "2222222222222222222222222222222222222222222222222222222222222222", "bytes": 512 }
  ]
}
```

Today the module writes only `run.json` into `evidence/{changeId}/`. The manifest and verdict come with the evaluator.

## 3. Promotion handoff contract

What a downstream system receives when the gate says a change may be promoted. It is emitted only on PASS, after manual approval or after the auto-mode guardrails were checked. FAIL and INCONCLUSIVE never produce one.

The receiving system decides what promotion means. For Intune that might be moving an assignment to the next group. For ConfigMgr, advancing a phased deployment. For a Citrix image pipeline, publishing the image. For ServiceNow, attaching the evidence to the change record and moving it to implement. The gate does none of that; it hands over this document and stops.

| Field | Type | Meaning |
|---|---|---|
| `handoffVersion` | string | `1` for this shape. |
| `changeId` | string | The change to promote. |
| `verdict` | string | Always `PASS`. Present so a receiver can assert it. |
| `promotionMode` | `manual` or `auto` | How the approval happened. |
| `approvedBy` | string | Reviewer identity for manual, `policy` for auto. |
| `approvedAt` | timestamp | When approval happened. |
| `testName` | string | From the verdict. |
| `testRunId` | string | From the verdict. |
| `policyName` | string | From the verdict. |
| `policyHash` | string | From the verdict. |
| `evidence` | object | `bundleName` is the workflow artifact name. `manifestSha256` lets a receiver check the bundle it fetches is the one that was approved. `url` is optional and points at the artifact when the platform offers a stable link. |
| `summary` | string | From the verdict. |

```json
{
  "handoffVersion": "1",
  "changeId": "CHG-2026-0911-01",
  "verdict": "PASS",
  "promotionMode": "manual",
  "approvedBy": "reviewer",
  "approvedAt": "2026-09-11T21:02:33.000Z",
  "testName": "Patch Gate - Office",
  "testRunId": "3f1c9a2e-0000-4000-8000-000000000001",
  "policyName": "default-functional",
  "policyHash": "sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "evidence": {
    "bundleName": "evidence-CHG-2026-0911-01",
    "manifestSha256": "3333333333333333333333333333333333333333333333333333333333333333",
    "url": null
  },
  "summary": "All 4 required applications executed with 0 failures across 3 sessions. Results complete."
}
```

A receiver that gets anything other than `verdict: PASS` in this document should refuse it. That is a bug in the emitter, not a judgment call.

## Changing a contract

Bump the version field, keep the old shape readable for one release, note it in `CHANGELOG.md`, and update the examples here in the same commit. Readers ignore unknown fields, so adding an optional field does not need a version bump. Removing or renaming one does.
