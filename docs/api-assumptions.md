# API assumptions awaiting genuine captures

No matching OpenAPI file or genuine run captures are present locally. Use [api-notes.md](api-notes.md) for endpoints. Synthetic data demonstrates code behavior, not vendor response shapes.

The response profile is a small set of dot selectors and list modes. The example is synthetic. Do not relabel it to pass preflight. A live profile needs provenance: capture-confirmed and confirmedFrom identifying reviewed private captures. This is an operator attestation, not automated proof.

| Unresolved detail | Capture required |
|---|---|
| overviewApplications, overviewAppId, overviewLogin | Success/failure overview, documented appExecutionSuccessful, and comparison if used. |
| sessionId, sessionRunId | All session pages with matching run and loginState. |
| executionId, executionAppId, executionSessionId, executionRunId | Every session's executions, states, and relationships. |
| List envelopes: sessions, executions, events, measurements, screenshots | Small-page request count/offset/includeTotalCount, response totals/offsets and final page. Notes describe arrays and totals. Envelope mode requires items/totalCount/offset. Array mode needs confirmed short-page termination, never a guess. |
| eventType and infrastructure events | Login/session/launcher/connection failures plus cancelled/internal-error examples. |
| screenshotId and binary response | Failed-execution list, download and matching execution. Missing screenshots make failure retrieval incomplete. |
| appFailureResults counts and retry semantics | Overview and every execution alongside successful/failed run counts. Gate retry allowance remains zero. |

Capture tooling retains unexpected responses and errors. Without a usable profile, it saves partial evidence and exits 2. Inspect it, correct mappings from evidence, and recapture to a new directory.

GitHub review history documents reviewer identity but no approval timestamp. Manual handoff blocks without matching authoritative time evidence. The runbook's local time envelope is our contract, not a GitHub API field.
