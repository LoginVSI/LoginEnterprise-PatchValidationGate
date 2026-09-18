# Login Enterprise Public API notes

Source of truth: the OpenAPI spec exported from the appliance. Nothing here comes from other documentation.

Appliance version: Login Enterprise 6.8.6
Spec exported: v8-preview (OpenAPI 3.0.1, base path `/publicApi`)
Target for the reference implementation: **v8-preview**, pinned as a config value. The spec header calls v7 the recommended version and v8-preview subject to breaking changes, so this was checked against the v7 export from the same appliance. v7 lacks three things the gate wants: the application test run overview with base-run comparison (`/application-test-run-overview`), `testRunName` on the start request (used to tag a run with the change id for idempotency), and `eventTypes` filtering on run events. v8-preview has shipped in every release since 6.0. The wrapper reads the API version from config so a move back to v7 is a one-line change plus dropping those three features.

## Authentication

Header `Authorization: Bearer {token}` where the token is a System Access Token created in the appliance (scheme name `Bearer`, type apiKey, header `Authorization`). OAuth2 client credentials and OpenID Connect are also declared but the reference uses the system access token. Create the token with a role limited to reading tests and test runs and starting tests; nothing else in this repo needs write access beyond `start`.

## Endpoints the gate uses

| Need | Method and path | What comes back | Notes |
|---|---|---|---|
| Sanity check / version | `GET /system/version` | `currentVersion`, `latestVersion` | First real call. Also recorded in the evidence manifest. |
| Resolve test by name | `GET /tests?testType=applicationTest&filter={name}&count=50` | `TestResultSet { items[], totalCount, offset }` | `filter` matches name or description, so match `name` exactly client-side. Refuse to proceed on zero or more than one exact match. |
| Read test | `GET /tests/{testId}?include=thresholds` | `ApplicationTest` | `state` is `disabled`, `enabled`, `running`, or `stopping`. Preflight requires `enabled`. `appThresholds` and `sessionThresholds` (loginTime, latency) are the appliance's own thresholds. |
| Start test | `PUT /tests/{testId}/start` body `StartRequest { comment, testRunName }` | `201 ObjectId { id }` = the test run id | 409 when the test can't be started (already running or disabled). Put the change id in `testRunName` and the durable identity hash in `comment`. |
| Existing runs (idempotency) | `GET /tests/{testId}/test-runs?count=20&orderBy=created&direction=desc` | `TestRunResultSet` | Refuse an existing matching name without durable identity; resume uses the locally persisted run ID. |
| Poll run | `GET /test-runs/{testRunId}` | `ApplicationTestRun` | `state`: `created` → `testRunEnded` → `completed`. Poll until `completed`. `result`: `successful`, `internalError`, `cancelled`, `incomplete`. `appFailureResults` and `appPerformanceResults` are `{ successCount, totalCount }`. |
| Run overview (with optional compare) | `GET /application-test-run-overview/{baseTestRunId}?testRunIds=...` | `ApplicationTestResultOverview` | Per application: `resultStatus` (`successful`, `overThreshold`, `error`), `appExecutionSuccessful`, `performanceSuccessful`, timer results, screenshots. Platform: `loginSuccessful`, login and latency performance. Pass a baseline run id in `testRunIds` and the appliance does the comparison. |
| Sessions | `GET /test-runs/{testRunId}/user-sessions?direction=asc&count=100` | `UserSession[]` | `loginState` (`succeeded`, `failed`, ...) and `sessionState`. |
| App executions | `GET /test-runs/{testRunId}/user-sessions/{userSessionId}/app-executions?direction=asc&count=200` | `AppExecution[]` | `state`: `created`, `ended`, `endedWithErrors`. |
| Measurements | `GET /test-runs/{testRunId}/measurements?direction=asc&count=1000&include=all` | `Measurement[]` | `duration`, `timestamp`, `applicationId`, `appExecutionId`. Raw evidence, not evaluated in the MVP. |
| Events | `GET /test-runs/{testRunId}/events?count=500&direction=asc` | `Event[]` | Filter with `eventTypes`. Useful ones: `applicationFailure`, `loginFailure`, `sessionFailure`, `launcherOffline`, `connectionInitializationTimeout`, `applicationThresholdExceeded`, `loginTimeThresholdExceeded`, `testRunFailed`, `testRunCancelled`, `testRunFinished`. |
| Screenshots | `GET /test-runs/{testRunId}/app-executions/{appExecutionId}/screenshots` then `.../screenshots/{screenshotId}` | list, then binary | Pull only for executions in `endedWithErrors`. |
| Report | `GET /test-runs/{testRunId}/reports` and `/reports/pdf` | `ApplicationTestReport`, PDF | Optional attachment for the evidence bundle. |
| Continuous test handoff | `GET /tests?testType=continuousTest`, `PUT /tests/{testId}/start` | | Same start call; the continuous test must already exist. Included in Part 2. |

Paging: every list takes `count` (required), `offset`, `includeTotalCount`. Walk pages until `offset + items.length >= totalCount`.

## How the run maps to a verdict

- `result` = `internalError` or `cancelled` → INCONCLUSIVE (`launcher-or-connection-error` or `results-incomplete`, decided by events)
- `result` = `incomplete` → INCONCLUSIVE (`results-incomplete`)
- `result` = `successful` → evaluate: required applications present in the overview, every one with `appExecutionSuccessful` true, `appFailureResults.successCount == totalCount`, `loginSuccessful` true → PASS, otherwise FAIL
- `state` never reaches `completed` inside `maxWaitMinutes` → INCONCLUSIVE (`run-timeout`)
- Events of type `launcherOffline` or `connectionInitializationTimeout` on the run → INCONCLUSIVE regardless of `result`

The appliance's own thresholds (`overThreshold`, `applicationThresholdExceeded`, `loginTimeThresholdExceeded`) are recorded as evidence in the MVP and not used for the verdict until the performance policy is enabled.

## Not used

Load test, continuous-test report configuration, EUX, session metrics, platform metrics, accounts, launchers, roles. `POST /test-runs/application-failures/details` (per-app failure details across runs) is v8-preview and worth revisiting once v7 is confirmed.

## Implementation and capture caveats

The preceding endpoint inventory is the historical transcription of the exported spec; the matching export itself is not in this repository. Nested field selectors and list envelopes are not live-verified. See [api-assumptions.md](api-assumptions.md) for the single capture checklist. A v7 switch requires revalidation, not merely changing a string.

Strict pagination rejects missing totals, inconsistent offsets, premature termination and page-limit exhaustion in envelope mode. Array termination is allowed only through an explicitly capture-confirmed profile. An empty/malformed overview cannot pass. The evaluator requires positive execution coverage and consistent relationships; infrastructure/evidence errors take precedence.

GitHub calls use official [workflow review history](https://docs.github.com/en/rest/actions/workflow-runs#get-the-review-history-for-a-workflow-run), [issues](https://docs.github.com/en/rest/issues/issues) and [comments](https://docs.github.com/en/rest/issues/comments) contracts. Review history identifies user.login but documents no approval timestamp. No environment timestamp is substituted.
