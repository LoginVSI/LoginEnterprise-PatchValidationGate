# Login Enterprise Public API notes

The reviewed [v8-preview snapshot](api/login-enterprise-v8-preview.openapi.json) is the implementation target. All paths below are relative to its `/publicApi` server and `/v8-preview` path prefix. Connect-LEGate accepts an HTTPS origin only; Invoke-LEGateRequest appends both prefixes exactly once. API selection is explicit through LE_API_VERSION or -ApiVersion, never automatic.

The [v7 snapshot](api/login-enterprise-v7.openapi.json) is a comparison reference. Both snapshots declare OpenAPI 3.0.1. They establish API versions, not the exporting appliance version or date. A historical version-call check against LE 6.8.6 does not establish full gate compatibility. See [snapshot provenance](api/README.md).

## Authentication and request contracts

The implementation sends a System Access Token as `Authorization: Bearer {token}` over trusted HTTPS. `components/securitySchemes/Bearer` declares an Authorization-header apiKey. OAuth2 and OpenID Connect are also declared. Every exported operation puts all three in one security requirement object; that export is preserved, not rewritten as an authentication compatibility claim. Token-only access, effective roles and permissions must be checked on the intended appliance. Grant reads for the listed resources and start permission for the existing tests, with no unrelated administrative writes.

## Used endpoints and schemas

Each row names a path under `paths` in the v8-preview snapshot. Referenced schemas live under `components/schemas`.

| Operation | Response/parameters and implementation rule |
|---|---|
| GET /system/version | SystemVersionResult.currentVersion/latestVersion. A real response establishes the observed version. |
| GET /tests | TestResultSet; required count, optional offset/includeTotalCount, testType, filter, direction/orderBy/include. Exact client-side name matching. The filter description limits it to application/load tests; continuous resolution omits filter and pages all continuous candidates. |
| GET /tests/{testId} | ApplicationTest/LoadTest/ContinuousTest union. Optional include is an array of TestInclude values, including thresholds. ApplicationTest.state uses TestControlState. ContinuousTest instead has boolean isEnabled; no state property is declared. |
| PUT /tests/{testId}/start | Required StartRequest JSON (nullable comment and testRunName); 201 ObjectId.id; 409 conflict. Writes are never retried. |
| GET /tests/{testId}/test-runs | TestRunResultSet; required count. TestRunSortKey includes created; direction desc supported. Existing named runs cannot replace durable identity. |
| GET /test-runs/{testRunId} | ApplicationTestRun inherits TestRun.id/testId/testRunName. ApplicationTestState: created, testRunEnded, completed. ApplicationTestResult: successful, internalError, cancelled, incomplete. Only completed successful results can proceed to functional evaluation. |
| GET /application-test-run-overview/{baseTestRunId} | ApplicationTestResultOverview.applicationTestResult[] contains ApplicationTestData rows keyed by testRunId. Each has state, testResult, isBase, platformSummary.loginSuccessful and applicationSummaries[]. Select exactly one row for the candidate run. With a baseline, put the baseline in the path and candidate in testRunIds; never evaluate the baseline row as the candidate. |
| GET /test-runs/{testRunId}/user-sessions | UserSessionResultSet. Required direction and count. UserSession.id/testRunId and loginState establish membership/login evidence. |
| GET /test-runs/{testRunId}/user-sessions/{userSessionId}/app-executions | AppExecutionResultSet. Required direction and count. AppExecution.id/testRunId/userSessionId/applicationId and state (created, ended, endedWithErrors). Cross-check all relationships. |
| GET /test-runs/{testRunId}/events | EventResultSet; required count. Event.eventType refers to EventType; optional eventTypes query refers to EventTypes. Retrieve all events rather than filtering away failures. Event.testRunId/userSessionId/applicationId are nullable. Supplied relationships must match collected evidence. |
| GET /test-runs/{testRunId}/measurements | MeasurementResultSet; required direction/count; include=all is a valid MeasurementInclude value. Retained but not used for performance policy. |
| GET /test-runs/{testRunId}/app-executions/{appExecutionId}/screenshots | Unpaged Screenshot[] with string id and created. No count/offset/includeTotalCount parameters. Fetch once and require an array, then download each failed execution's screenshot. |
| GET /test-runs/{testRunId}/app-executions/{appExecutionId}/screenshots/{screenshotId} | Binary string schema. The export labels it application/json; retain downloaded bytes without JSON decoding. Actual media type/content and ID syntax need capture confirmation. |
| GET /user-sessions/active | ActiveUserSessionResultSet; required count, optional testTypes/direction. Read continuous sessions and match testId client-side before mutation; disabled scheduling alone is not proof of drained sessions. |

Continuous handoff uses the same existing-test start endpoint, checks the returned ID and reads the test again to confirm isEnabled. This confirms enabled scheduling, not that a workload session is already running or that future iterations will pass. If enablement cannot be observed, handoff fails closed and requires investigation before retrying. Stop-LEGateContinuousTest uses the documented stop endpoint, verifies disabled scheduling and separately waits for observed sessions to drain.

## Completeness and Events

TestResultSet, TestRunResultSet, UserSessionResultSet, AppExecutionResultSet, EventResultSet, MeasurementResultSet and ActiveUserSessionResultSet declare items[], nullable totalCount and offset. Request includeTotalCount=true; reject absent/changing totals, wrong offsets, oversize/premature empty pages and page-limit exhaustion. Screenshot[] is a separate unpaged contract, not a paged array termination guess.

ApplicationSummary contains applicationId and appExecutionSuccessful. The gate requires positive execution coverage, no contradictory overview/execution results, and consistent appFailureResults counts. SuccessCounts is reused for failure/performance fields and its description does not establish aggregation/retry semantics. The current conservative count equality remains a live acceptance requirement rather than a vendor guarantee.

Event.eventType is a nonempty scalar string. Known infrastructure, capacity, session, cancellation and evidence-loss events prevent PASS. Unknown types are incomplete evidence pending review. applicationFailure must agree with a collected failed execution; otherwise evidence is contradictory. Native Events are LE observations, not gate verdicts or GitHub issues. Performance threshold events remain evidence only. A failed application does not establish that the change caused it.

## Version comparison and upgrades

v7 **does** contain application overview and comparison: `/v7/application-test-run-overview/{testRunId}` with testRunIds. Its StartRequest lacks testRunName. Its run-events endpoint lacks the v8-preview orderBy and eventTypes query parameters; no v7 compatibility is claimed. Changing the API version string cannot translate these contracts.

Response profile version 2 adds overviewRuns/overviewRunId, selects fields within the matched row, uses eventType and removes screenshot paging configuration. Existing private profiles need review against these selectors and new genuine captures. Do not edit profile bytes beneath an active lease: restore/recover with its original inputs first, then use a fresh change identity. Preserve the original release/configuration if needed for that recovery.

Before selecting a later version, privately export its matching spec, review paths/authentication/parameters/enums/compositions/paging and binary responses against this inventory, adapt mappings and code where supported, and run offline contract regressions plus genuine success/failure/restore acceptance. A spec-derived profile is a starting point, not capture-confirmed provenance. See [remaining assumptions](api-assumptions.md).

GitHub approval-time acquisition remains independently blocked as described in [approval evidence](approval-evidence.md). Neither the LE spec nor bounded approval-file delivery resolves that prerequisite.

## Bounded continuous stop and drain

The reviewed v8-preview specification defines PUT /tests/{testId}/stop with
no request body and a 204 response. Stop-LEGateContinuousTest resolves only an
existing Continuous Test, sends that write once when enabled, confirms disabled
scheduling by GET /tests/{testId}, and polls /user-sessions/active until no
sessions belong to that test. It does not infer drained sessions from scheduling
alone. Unknown session identities and deadline expiry fail closed.

The run exporter requests include=testRunConfigurationSnapshot (TestRunInclude) to preserve the historical workload. The response field is testConfigurationSnapshot; historical workload application IDs use appId, unlike current configuration applicationId. An omitted snapshot is not proof of an empty historical workload.
