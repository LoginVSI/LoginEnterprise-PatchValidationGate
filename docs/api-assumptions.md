# Specification facts and live acceptance gaps

The reviewed [v8-preview snapshot](api/login-enterprise-v8-preview.openapi.json) establishes the contracts summarized in [API notes](api-notes.md). All local references have been resolved for review. This replaces the earlier absence of a local specification; genuine run captures are still pending.

The example profile uses spec-derived selectors and envelopes. A live profile needs `provenance: capture-confirmed` and `confirmedFrom` identifying reviewed private captures. That is an operator attestation, not automated proof. Never change synthetic provenance to bypass preflight.

| Spec-confirmed fact | Remaining capture/operational check |
|---|---|
| ApplicationTestResultOverview.applicationTestResult[] contains ApplicationTestData keyed by testRunId, with platformSummary and applicationSummaries. | Success/failure rows agree with run, login and application evidence; optional comparisons select the candidate correctly. |
| UserSession and AppExecution declare run/session/application relationships and execution states. | Every page is visible to the token; completed workload coverage is consistent, including null/empty fields and retries. |
| ResultSet envelopes contain items, nullable totalCount and offset. | includeTotalCount=true produces stable usable totals and exact offsets. Missing totals or changing pages remain INCONCLUSIVE. Do not substitute guessed termination. |
| Event.eventType uses EventType; run/session/application relationships are nullable. | Confirm native failure and infrastructure examples. Supplied relationships must match; unknown/malformed types block complete evidence. Gate classification is our conservative policy, not a vendor severity field. |
| Screenshot[] is unpaged, with nullable string IDs and created timestamps; download schema is binary despite application/json labeling. | Metadata, ID encoding, media type and nonempty bytes map to the correct failed execution. Missing screenshots remain incomplete under this gate's evidence requirements. |
| ApplicationTestRun.appFailureResults uses SuccessCounts. | Validate conservative execution-count equality and the success denominator, including LE retry behavior. Schema descriptions do not prove aggregation semantics; gate retry allowance stays zero. |
| ContinuousTest has isEnabled; active sessions expose testId; start returns ObjectId. | Verify token visibility, disabled scheduling plus drained sessions before mutation, start/readback timing and enabled scheduling after handoff. Enablement does not prove immediate workload execution. |
| Security schemes include Bearer, OAuth2 and OpenID in one operation requirement object. | Confirm System Access Token authentication, effective read/start roles and TLS. API metadata does not establish an appliance version. |

The [bootstrap procedure](first-live-capture.md) obtains baseline, controlled-failure and restored captures before gate use. Export preserves unexpected responses and errors. Without a usable profile it retains partial evidence and exits 2; correct the private draft from evidence and recapture into a new directory. Explicitly record cases not yet observed instead of declaring blanket acceptance.

GitHub [authoritative approval-time acquisition](approval-evidence.md) remains a separate external blocker. Review history supplies reviewer identity but no approval timestamp. Bounded delivery checks repository/run/attempt/environment/reviewer fields; matching files do not establish authoritative provenance.
