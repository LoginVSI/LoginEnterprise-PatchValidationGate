# Login Enterprise Patch Validation Gate

Patches show up faster than most teams can test them. Security wants the fix out this week. The workspace team knows what happened the last time an update went out without anyone checking whether the line-of-business apps still opened. Both of them are right, and the usual answer is to let the patch sit in a deployment ring for a while and hope nothing surfaces.

This repo is a reference implementation for doing that differently. A change lands on a validation target. Login Enterprise runs the application workflows you already care about against it. A policy you wrote turns the results into PASS, FAIL, or INCONCLUSIVE. The evidence is kept. Then whoever owns promotion today (a person, a change board, a deployment tool) makes the call with something in hand besides elapsed time.

The gate is generic. It works the same for a CVE fix, a security-agent update, or a monthly cumulative update. The first showcase leans on the security remediation case because that is where the pressure is right now.

## What this is not

It does not deploy patches. It does not replace Intune, ConfigMgr, Windows Autopatch, Citrix or Omnissa image tooling, or ServiceNow. It does not roll anything back or track compliance.

PASS does not mean a patch is safe. PASS means the validation policy you defined passed for the workflows you scripted, on the target you tested. If a workflow isn't in the test, the gate knows nothing about it.

## The loop

1. A change is detected or flagged: vulnerability scanner, patch catalog, or a person
2. The change is applied to a validation target
3. Login Enterprise runs an application test against the changed target
4. Results are retrieved, optionally compared to a baseline
5. Policy evaluation produces PASS, FAIL, or INCONCLUSIVE, and evidence is preserved
6. Gate: a person reviews the evidence and approves, or policy plus guardrails auto-approve a PASS
7. The existing deployment process promotes the change
8. The same workflow is handed to Login Enterprise continuous testing for post-deployment validation
9. Nothing happens until the next change

## Verdicts

- PASS: every required application executed, no application failures after allowed retries, results complete.
- FAIL: at least one required application failed or never ran, results complete.
- INCONCLUSIVE: the gate could not produce evidence it trusts. Always goes to a person. See [docs/verdict.md](docs/verdict.md).

## Status as of 2026-09-11

What exists: this skeleton, the policy and verdict model, a GitHub Actions workflow with the gate condition in place, and the Login Enterprise API mapping being filled in from the appliance OpenAPI spec.

What Part 2 adds: a thin PowerShell wrapper over the Login Enterprise Public API, a reference change adapter, start and poll of an application test, results retrieval, the evaluator, the evidence bundle, and one PASS run and one FAIL run you can look at.

## Requirements

- A Login Enterprise appliance with Public API access and at least one application test
- A Windows machine with PowerShell 5.1 or later, registered as a self-hosted GitHub Actions runner
- GitHub Actions