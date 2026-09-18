# Verdict model

**PASS** requires complete, consistent evidence, successful login, and successful execution of every explicitly required application.

**FAIL** requires complete evidence establishing required application failure or an explicit application row with zero executions. An absent row does not establish nonexecution.

**INCONCLUSIVE** covers timeout, infrastructure failure, cancelled/internal-error/incomplete or unknown run states, missing fields, mismatched identifiers, invalid policy, partial pages, empty overview, or retrieval failure. These take precedence over apparent success.

## Reason codes

- `test-not-found`
- `preflight-failed`
- `run-timeout`
- `launcher-or-connection-error`
- `results-incomplete`
- `policy-invalid`

Functional FAIL uses `application-failed` or `application-not-executed`, exposed separately by the centralized reason-code helper.

## verdict.json

Stable fields: verdict, reasonCodes, changeId, testName, testRunId, policyName, policyHash, promotionMode, evaluatedAt, summary. The applications extension records required IDs, individual verdicts, execution counts and failure counts. See [contracts](contracts.md).

Test-LEGatePolicy takes normalized results, policy and explicit context. It reads no files, network, hashes, or clock. Fixed inputs produce fixed output.

Only allowStepRetries: 0 is supported. The gate does not retry steps or hide reported failures. Appliance retry/count semantics require capture confirmation. Performance measurements and optional comparison are preserved without influencing policy. Unsupported settings are rejected.

Invoke-Gate exit codes: 0 PASS, 1 FAIL, 2 INCONCLUSIVE or orchestration/reporting failure. A reporting failure can return 2 while preserving completed PASS evidence. Later promotion/continuous failures never rewrite the validation verdict.
