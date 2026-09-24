# Login Enterprise Patch Validation Gate

Use existing Login Enterprise workloads to check a Windows lab change before deciding whether to promote it. This PowerShell reference implementation is for endpoint, desktop and release teams who otherwise apply changes, start tests, collect results and assemble approval evidence by hand. It automates those steps so teams can review consistent evidence sooner.

You receive a **PASS, FAIL or INCONCLUSIVE verdict**, application results, a readable summary and an integrity-checked JSON evidence bundle. Private captures retain native LE responses and failure screenshots. Approval, simulated promotion and continuous-test handoff have separate records; they cannot rewrite validation.

**Preview: targets the v8-preview API. Local lab acceptance is verified against LE 6.8.6.** The supported validation path produced a passing update and a deliberate application failure, with independently verified restoration after each. A separate bounded Continuous Test check executed workloads, disabled scheduling and verified session drain. Live GitHub Actions validation was also verified on 2026-09-23 with a temporary supervised runner: a good update PASSed, a deliberate application failure FAILed, and independent restoration with fresh baseline workloads followed each scenario. Authoritative manual-approval time evidence remains blocked. Simulated promotion, the Actions Continuous Test handoff and good-update issue closure were not exercised in that validate-only runner configuration. See the [tested walkthrough](docs/tested-lab-walkthrough.md) and [Actions acceptance record](docs/one-off-actions-acceptance.md). The reviewed [OpenAPI snapshots](docs/api/README.md) establish API versions, not appliance provenance. v7 is a comparison reference, not a compatibility claim.

## Start here

1. **Try offline:** run the example below. No appliance, credentials or development dependencies are needed.
2. **Use your LE workloads:** follow [user setup](docs/setup.md), then the [first private capture](docs/first-live-capture.md) and [operations runbook](docs/runbook.md).
3. **Explain an existing bundle:** use the [read-only AI explainer](docs/explain-evidence.md), with copy/paste prompts for synthetic and private evidence.

From a fresh checkout's root, use Windows PowerShell 5.1:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/Invoke-OfflineScenario.ps1
Get-Content .private/offline/fail/summary.md
Get-Content .private/offline/fail/verdict.json
```

Or run the scenario with PowerShell 7 on Windows:

```powershell
pwsh -NoProfile -File scripts/Invoke-OfflineScenario.ps1
```

Follow your organization's execution policy. Expected output is three `SYNTHETIC, not live` lines for PASS, FAIL and INCONCLUSIVE, each with a verified bundle under `.private/offline/`. Inspect the FAIL reason and required-application results, then compare the other summaries. These authored examples demonstrate code behavior; they are not live acceptance. Contributor tests and lint have [separate setup](docs/contributing.md).

## Where this fits

A person or external pipeline detects a change and invokes the gate. Supplied disposable-lab adapters apply, verify and revert a pinned MSI update or a controlled application-only break. LE runs an existing application test and produces results and native Events. Code applies deterministic functional policy; AI does not choose the verdict.

FAIL and INCONCLUSIVE block promotion. PASS can enter manual approval or configured automatic guardrails, but **production promotion is simulated**. A real deployment integration must implement the [promotion contract](docs/contracts.md) and confirm its own outcome before handing off to an existing continuous test. Handoff confirms enabled scheduling, not that a session has already run successfully.

There is no change scanner or always-running controller that watches later Events and repeats the update lifecycle. Native LE Events describe workload observations; gate verdicts summarize configured policy, and optional GitHub issues track the change. A failure does not by itself prove the update caused it. See [verdict semantics](docs/verdict.md) and [portability](docs/portability.md), including external-change/noop limits.

## Before a live run

You need LE access and suitable System Access Token permissions, working application and continuous tests, launchers/accounts/connectors, a disposable Windows target with independent recovery, trusted TLS, and PowerShell 5.1 or 7. The supplied mutation adapters need verified installers and target execution credentials. All callers must share durable target state and protect private evidence. GitHub Actions additionally needs a suitably isolated Windows runner and the documented secrets/environment controls.

PowerShell, GitHub Actions, GitHub issues and JSON provide familiar building blocks that can be replaced through explicit contracts. LE licensing, runners and infrastructure have their own requirements and costs.

Private capture can proceed after its operational prerequisites are met. The full manual demonstration also requires [authoritative approval-time evidence](docs/approval-evidence.md), which remains an external blocker. Bounded file delivery and matching fields do not prove authoritative provenance.

Use [live acceptance](docs/live-acceptance.md) to assess readiness, [recovery](docs/runbook.md#recovery) for interrupted work, [security](docs/security.md) before sharing evidence, and [API notes](docs/api-notes.md) before changing API versions. [Architecture](docs/architecture.md) explains the components; [implementation progress](docs/implementation-progress.md) records verification status.
