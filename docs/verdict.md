# Verdict model

Three states. No fourth.

**PASS.** Every required application executed. Zero application failures after the allowed number of step retries. Results complete.

**FAIL.** At least one required application failed or did not execute after retries. Results are complete, so the failure points at the change or the workflow, not at the gate itself.

**INCONCLUSIVE.** The gate could not produce evidence it trusts. Never treated as PASS. Never treated as FAIL. A person looks at it.

## Reason codes

- `test-not-found`
- `preflight-failed`
- `run-timeout`
- `launcher-or-connection-error`
- `results-incomplete`
- `policy-invalid`

## verdict.json

```json
{
  "verdict": "PASS | FAIL | INCONCLUSIVE",
  "reasonCodes": [],
  "changeId": "",
  "testName": "",
  "testRunId": "",
  "policyName": "",
  "policyHash": "",
  "promotionMode": "manual | auto",
  "evaluatedAt": "",
  "summary": ""
}
```

Field names may shift once the appliance OpenAPI spec tells us what a run identifier is called.