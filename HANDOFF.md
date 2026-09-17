# HANDOFF: Login Enterprise Patch Validation Gate

Last updated: 2026-09-17 (final handoff version)
Owner: Joshua Kennedy, Login VSI (product/technical marketing, builds the engineering himself with AI coding agents)
Repo: https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate (public)

This document is the complete handoff. A model or person picking this up should be able to guide Joshua from here to a finished Part 2 without the original conversation.

---

## 0. If you are the model reading this

You are the guide. Joshua is the go-between: you tell him what to do, he does it himself or pastes your prompts into Codex (a coding agent working inside the repo), and he brings the results back to you. Codex reads this file too; you read the repo through GitHub if you can browse, otherwise ask Joshua for `git log --oneline` and a file tree.

Do these before advising anything:

1. Read this whole file.
2. Read the repo (public: https://github.com/LoginVSI/LoginEnterprise-PatchValidationGate). Priority order: `README.md`, `CLAUDE.md`, `docs/architecture.md`, `docs/verdict.md`, `docs/api-notes.md`, `docs/contracts.md`, `policies/default.policy.json`, `.github/workflows/validate-patch.yml`, `src/LEGate/Public/`, `scripts/Invoke-Smoke.ps1`, `CHANGELOG.md`, git log. That tells you where engineering stopped.
3. Compare the repo against section 4 here. If they differ, the repo wins; tell Joshua what changed.
4. Ask Joshua only for values in section 7 that are still blank. Do not ask for context that is in this file.
5. Then walk him through section 8 (manual setup) and section 9 (prompts), in order, one chunk at a time. Each chunk: the goal, exactly what to do, what "good enough" looks like, and when to stop. Do not summarize this document back to him. Do not re-plan.

When you hand him a prompt for Codex, prepend the line "Read HANDOFF.md first." and give it verbatim from section 9.

How Joshua works: direct, terse, casual. He wants confident recommendations, not menus. He will scope-creep toward the whole vision; hold the line at Part 2 and push everything else to section 15. Credits are limited, so prompts stay one-shot friendly and offline where possible. If he says "next chunk", give the next chunk and nothing else.

---

## 1. The project in one page

**What it is.** A public reference implementation showing Login Enterprise as an evidence gate inside a patch promotion process, plus a Workspace Weekly blog series (Part 1 written, Part 2 to build and write).

**Why it exists.** Login Enterprise customer advisory board conversations surfaced one theme: security fixes arrive faster than deployment rings can absorb them. Security teams push for speed. EUC teams get blamed when a patch breaks an application. The usual answer is to let the patch sit in Ring 1 for days and see if anyone complains.

**The thesis.** Time in a deployment ring is a stand-in for evidence. The ring is where an organization finds out whether its own apps, on its own image, still work after the change, with real users as the test harness. Produce that evidence directly, before anyone in Ring 1 touches the patch, and the dwell time becomes a policy decision instead of a default.

**What Login Enterprise does in this.** It runs the application test against the changed target (stage 3) and, after promotion, the same workflow keeps running as a continuous test (stage 8). Nothing else.

**What we never claim.** That PASS means a patch is "safe". That the gate deploys, rolls back, or replaces Intune, ConfigMgr, Autopatch, Citrix/Omnissa image tooling, or ServiceNow. That Login Enterprise is a monitoring tool (use "continuous validation" or "continuous testing"). Any percentage of time saved, exposure reduced, or rings compressed. Anything about specific customers.

**What we do claim.** Shorter elapsed time between "patch available" and "workflow evidence exists". Reproducible, machine-readable verdicts. Preserved evidence. Deterministic policy, no AI in the verdict path. The comparison against a base run already exists in the Login Enterprise API; the gate adds policy and a pipeline around it.

**Sentiment.** Friendly-controversial, value-driven, honest about what is built and what is not. A gate that has only ever said yes is not a gate; Part 2 exists to show a real FAIL.

---

## 2. The loop and its boundaries

Matches the published diagram `patch-validation-loop-figure-1.png` (nine boxes, dashed box around 2 to 6 labeled "reference implementation", dashed box around 7 labeled "your deployment system", FAIL/INCONCLUSIVE branch to "stop, evidence kept, person notified", evidence bundle icon under 5, return arrow from 9 to 1).

1. Change detected (scanner, catalog, or a person)
2. Change applied to a validation target
3. Login Enterprise application test runs against it
4. Results retrieved, optional baseline compare
5. Deterministic policy evaluates: PASS, FAIL, INCONCLUSIVE
6. Gate: manual approval, or auto with guardrails
7. Existing deployment system promotes (simulated in the reference)
8. Same workflow handed to Login Enterprise continuous testing
9. Wait for next change

Boundaries that never move:
- Login Enterprise validates. The policy evaluates. A person or the existing deployment system promotes.
- PASS means the policy passed for the tested workflows on the tested target, nothing more. Coverage is the ceiling.
- Timeouts and infrastructure errors are INCONCLUSIVE, never FAIL, and always go to a person.
- Only PASS can auto-promote, and only when policy guardrails are met.
- Generic foundation for any change class; security patch is the first showcase.

Verdict model (`docs/verdict.md`): PASS, FAIL, INCONCLUSIVE. Reason codes: `test-not-found`, `preflight-failed`, `run-timeout`, `launcher-or-connection-error`, `results-incomplete`, `policy-invalid`.

Run-to-verdict mapping (`docs/api-notes.md`): run `result` internalError or cancelled -> INCONCLUSIVE; incomplete -> INCONCLUSIVE results-incomplete; events launcherOffline or connectionInitializationTimeout -> INCONCLUSIVE; state never reaches completed in maxWaitMinutes -> INCONCLUSIVE run-timeout; result successful -> every required app has appExecutionSuccessful true and appFailureResults.successCount == totalCount and loginSuccessful true -> PASS, else FAIL. Performance signals are recorded, not judged, while `policy.performance.enabled` is false.

---

## 3. Decisions already made (do not reopen)

- Repo name `LoginEnterprise-PatchValidationGate`, public from day one under the LoginVSI org, MIT.
- PowerShell 5.1 compatible everywhere. Thin `Invoke-RestMethod` wrapper. No generated client. Do not add the PSLoginEnterprise module.
- Login Enterprise Public API **v8-preview**, pinned as a config value. v7 was diffed against the same appliance's export and lacks the run overview with base-run comparison, `testRunName` on start, and `eventTypes` filtering. Rationale is in `docs/api-notes.md`. Appliance is Login Enterprise 6.8.6.
- CI/CD: GitHub Actions. Hosted `windows-latest` for lint and unit tests (`ci.yml`). Self-hosted Windows runner inside the network for the gate itself (`validate-patch.yml`, `workflow_dispatch` only).
- Pipeline jobs: `validate`, `promote-manual` (GitHub environment `promotion-approval` with a required reviewer), `promote-auto`, `continuous-testing`. Inputs: `change_id`, `policy_file`, `promotion_mode` (manual|auto), and Prompt A adds `change_manifest`, `adapter`, `target_computer`, `continuous_test_name`.
- The "patch" in the demo is a pinned third-party application update (7-Zip or Notepad++) installed by a change adapter. A `break` adapter damages that app so a FAIL is real. No mocked results, no registry-flip fakes, no real Windows cumulative update (Part 3).
- Login Enterprise tests pre-exist. The pipeline never creates tests. It runs `patch-gate-app` (application test) and starts `patch-gate-continuous` (continuous test).
- What differs between runs: the target's state, and the run's `testRunName` (the change id) and `comment` (policy hash plus description). Two runs of the same test, side by side in the LE UI with different names, is the Part 2 hero screenshot.
- The "ticket" is a GitHub Issue per change id that the pipeline opens, comments on at each stage, and closes. This is the reference promotion-handoff adapter. ServiceNow is a one-page translation note, not an integration.
- Stage 7 is simulated: write `promotion-record.json` and log the handoff. Optionally run the adapter against a second VM named "prod". Nothing more.
- AI: no AI in the verdict path. A read-only evidence explainer skill is Part 3 and only if credits remain (section 13).
- Model budget: Fable 5.1 credits are nearly gone. Remaining work runs on Opus/Sonnet 5 or equivalent at medium effort.

---

## 4. What exists in the repo (as of 2026-09-11 evening, verify against git log)

- `src/LEGate/`: manifest, loader, five public functions: `Connect-LEGate` (session from `LE_BASE_URL`, `LE_API_TOKEN`, `-ApiVersion`, `-SkipCertificateCheck`), `Get-LEGateVersion`, `Resolve-LEGateTest` (exact name, applicationTest only, throws on 0 or >1), `Start-LEGateRun` (idempotent: reuses an existing run whose `testRunName` equals the change id, else PUT start), `Wait-LEGateRun` (polls to `completed`, returns `timedOut` on timeout, writes `evidence/{changeId}/run.json`). Private: HTTP helper with bearer header, retry on GET only, token redaction; paging; JSON-lines logging; reason codes; UTC clock.
- `tests/`: 68 Pester unit tests (mocked HTTP) green on Windows PowerShell 5.1 and PowerShell 7; integration tests that skip without env vars; `Invoke-Tests.ps1`; `fixtures/` with a README (empty of fixtures so far).
- `.github/workflows/ci.yml` (hosted lint + unit, green) and `validate-patch.yml` (skeleton with the four jobs, parses, never run).
- `scripts/Invoke-Smoke.ps1` (version call; with `-TestName` and `-ChangeId` it starts and waits), `Invoke-Lint.ps1`, `Initialize-DevEnvironment.ps1`.
- `docs/`: architecture, verdict, api-notes (14 endpoints mapped from the appliance's OpenAPI export), setup, contributing, security, ai-agents, contracts (change adapter apply/verify/revert, verdict, promotion handoff).
- `policies/default.policy.json` (functional-only, performance disabled, promotion mode) and `policy.schema.json`.
- `adapters/change/README.md` (contract only, no scripts yet).
- `CLAUDE.md`, `CHANGELOG.md`, `SECURITY.md`, `CONTRIBUTING.md`, `.editorconfig`, `PSScriptAnalyzerSettings.psd1`.
- Verified: version call against the 6.8.6 appliance. Not yet: any real test run.

Known machine quirk: Joshua's Windows PowerShell has PowerShellGet 2.2.5 without matching PackageManagement, so `Install-Module` fails in 5.1; modules were installed from PowerShell 7 with `Save-Module` into the 5.1 user module path. `docs/setup.md` documents it.

---

## 5. Content

### Part 1 (written, in review): "Your Deployment Ring Is a Waiting Room | Workspace Weekly"

Arc: opening scene (patch lands, security wants it out, EUC parks it in a ring) -> the clock got shorter this summer -> what promoting blind cost this year -> time in a ring is evidence in disguise -> what the gate produces (verdict table) -> where Login Enterprise fits -> what exists today (repo) -> what Part 2 builds -> send me your patch scenarios -> demo CTA.

Assets: Figure 1 is the loop diagram. The repo link. Nothing else (a Figure 2 line was removed).

Verified claims and their sources (do not re-flag these in reviews):
- CISA BOD 26-04, issued 2026-06-10, risk-scored model, three-day deadline for publicly exposed, automatable, known-exploited vulnerabilities. https://www.cisa.gov/news-events/directives/bod-26-04-prioritizing-security-updates-based-risk
- Microsoft Graph expedite doc says expediting is not designed for every month. https://learn.microsoft.com/en-us/graph/windowsupdates-deploy-expedited-update
- January 2026 out-of-band updates: KB5077795 (sign-in failures in remote connection apps) https://support.microsoft.com/kb/KB5077795 and KB5078131 (apps hanging on cloud-backed storage, Outlook with PST on OneDrive) https://support.microsoft.com/help/5078131
- Test Base for Microsoft 365 end of life 2024-05-31. https://learn.microsoft.com/en-us/microsoft-365/test-base/faq
- Rapid7 2026 threat report (exploit windows mostly internet-facing). https://www.rapid7.com/about/press-releases/rapid7-2026-global-threat-landscape-report-shows-exploited-high-and-critical-severity-vulnerabilities-surged-105-as-attack-timelines-collapsed/
- Login Enterprise v8-preview API has `application-test-run-overview` with base-run comparison; application tests carry `appThresholds` and `sessionThresholds` (login time, latency). Verified in the appliance spec.

Softened on purpose: KEV as a reference point "regulated industries and government contractors cite" (unsourced, kept vague); "conversations with customers" instead of "customer advisory board" (change back only if approved); no test count in the blog ("a unit test suite"); "Part 2" instead of dates.

Socials doc exists (LinkedIn, Slack external; sales and engineer emails internal; six short blurbs) with public-facing share blurbs and a trimmed engineer email. `[Paste blog URL]` placeholders remain.

Loose ends before publish: Schedule a demo link is the homepage placeholder; Workspace Weekly hub link (https://www.loginvsi.com/tag/workspace-weekly/) needs adding at the bottom; paste the live URL into the socials; Asana title, shared doc link, ready-for-review comment, marketing, posting.

### Part 2 (to build and write): "Show Me the FAIL | Workspace Weekly"

Target draft: as soon as the live runs exist, ideally 2026-09-19. If live runs slip, publish with offline pieces and say the live runs follow. Never fake a run.

Arc: Part 1 promised a gate that can say no; here it is. Open on the FAIL run. Walk the loop with real screenshots: dispatch, issue opens, adapter applies the broken update, LE runs, verdict FAIL with the failed step's screenshot, promote jobs skipped, issue stops, target reverted. Then the PASS run: same test, good update, approval, continuous test starts, issue closes. Then what a reader needs to do this themselves (two LE tests, a runner, secrets, one policy file). Portability note (Azure DevOps, GitLab, Jenkins, ServiceNow). What Part 3 covers. Scenario request. Demo CTA.

Assets to capture: LE UI with both runs by name; failed app execution with its screenshot; GitHub issue trail for FAIL and for PASS; workflow graph waiting on approval; the artifact; the continuous test running. Diagram can be reused or Claude Design can produce a second figure with the FAIL branch highlighted.

Socials: same doc structure as Part 1. Lead with the FAIL.

### Part 3 (later)

Baselines and performance policy on top of the appliance's own thresholds and run comparison; image-level gate with a real Windows CU on a snapshot-reverted VM; real ServiceNow/Intune/Autopatch handoff; detection adapters; AI evidence explainer.

---

## 6. Editorial rules (every draft, every doc, every commit message)

No em dashes. No "actually", "critical", "matters". Prose over bullets except link lists. Vary paragraph length; single-sentence paragraphs next to long ones. Strip AI patterns: concession-contrast tics, negate-then-reframe, "not X but Y", symmetrical parallel sentences, rule-of-three cadence, vague openers, "worth", "seamless", "leverage", "robust". Reads like a person who works there. One metaphor per piece at most. Problem before product. No partner bashing. No roadmap promises with dates.

Review every blog and socials draft with the codex-writing-skills repo (`C:\personalRepos\codex-writing-skills`) in this order: workspace-weekly, voice-and-tone, avoid-ai-style. Prompt in section 10.

---

## 7. Values Joshua provides (the runtime sheet)

Everything the repo needs to run in his lab. None of this goes in the repo. The model asks for blanks; it never guesses.

| Value | Where it is used | Status |
|---|---|---|
| `LE_BASE_URL` (https://host, no trailing slash, no /publicApi) | env var locally; repository secret | known to Joshua |
| `LE_API_TOKEN` (system access token; role must read tests/runs and start tests) | env var locally; repository secret | exists, verified with version call |
| `LE_SKIP_CERT_CHECK` (true if lab cert is self-signed) | env var / repository variable | decide |
| Application test name `patch-gate-app` | policy file, smoke, workflow | to create |
| Continuous test name `patch-gate-continuous` | workflow input | to create |
| Target computer name (the VM the launcher logs into and the adapter changes) | workflow input `target_computer` | to decide |
| `TARGET_USER` / `TARGET_PASSWORD` (local admin on target for WinRM) or "runner is the target" | repository secrets | to decide |
| Demo app and pinned versions (e.g. 7-Zip 24.08 -> 24.09, winget id `7zip.7zip`) | `examples/changes/7zip-update.json` | to decide |
| Launcher name (for the model's awareness only) | not in repo | known |
| Test account name (for awareness only) | not in repo | known |
| Runner machine name and labels (`self-hosted`, `windows`) | workflow `runs-on` | to install |
| GitHub environment `promotion-approval` with Joshua as reviewer | `promote-manual` job | to create |
| Change ids for the demo: e.g. `CHG-noop-1`, `CVE-2026-DEMO-7zip-pass`, `CVE-2026-DEMO-7zip-fail` | dispatch input; each must be unique because start is idempotent by run name | pick when running |
| Test ids and run ids | returned by the API; recorded in evidence manifests | produced at runtime |

---

## 8. Minimal manual setup, with a check for each step

Everything here is Joshua's hands, no agent, no credits. Do them in order. Each has a check; do not move on until the check passes.

1. **Target VM.** A Windows VM the Login Enterprise launcher can log into (RDP connector is fine) with a test account. Snapshot it once configured so demo runs can be reset.
   Check: you can RDP to it with the test account.
2. **Launcher.** Registered and online in the appliance.
   Check: launcher shows online in the appliance UI.
3. **Demo app.** Pick 7-Zip (winget `7zip.7zip`, MSIs on 7-zip.org) or Notepad++ (`Notepad++.Notepad++`). Install the "before" version on the target. Write down before and after versions and sources.
   Check: the before version is installed and opens.
4. **Workload for the demo app.** Record one with the Script Recorder or write it by hand: launch the app, do one visible action (7-Zip File Manager: expand a folder; Notepad++: open a file), close. The app the adapter breaks must be exercised by the test or breaking it changes nothing. Notepad can use a built-in or template workload.
   Check: the workload runs green on its own in a test.
5. **Application test `patch-gate-app`.** One account, one launcher, run once then stop. Applications: Notepad plus the demo app. Default thresholds.
   Check: run it from the UI; result successful, all apps green.
6. **Continuous test `patch-gate-continuous`.** Same applications, schedule always-on, left stopped.
   Check: exists, state not running.
7. **WinRM from runner to target** (skip if using the fallback): on target `Enable-PSRemoting -Force`, firewall port 5985 open; if not domain-joined, add target to TrustedHosts on the runner. Choose a local admin credential for `TARGET_USER`/`TARGET_PASSWORD`.
   Check: `Invoke-Command -ComputerName <target> -Credential <cred> { hostname }` returns the target's name.
   Fallback: install the self-hosted runner on the target VM itself and run adapters with `-TargetComputer localhost`. Removes the whole class of remoting failures.
8. **Smoke run.** In a terminal with `LE_BASE_URL` and `LE_API_TOKEN` set: `.\scripts\Invoke-Smoke.ps1 -TestName 'patch-gate-app' -ChangeId 'baseline-2026-09-17' -SkipCertificateCheck`.
   Check: reaches `completed`, `result = successful`, `appFailureResults.successCount == totalCount`, and `evidence/baseline-2026-09-17/run.json` exists. A 403 on start means the token's role cannot start tests.
9. **Fixtures.** From that run, via Swagger UI (Authorize with the bearer token): `GET /test-runs/{id}`, `GET /application-test-run-overview/{id}`, `GET /test-runs/{id}/events?count=500`, `GET /test-runs/{id}/user-sessions?count=100`, and `GET /test-runs/{id}/user-sessions/{sessionId}/app-executions?count=200`. Save as JSON in `tests/fixtures/` per its README. Sanitize: remove hostnames, launcher names, account names; ids are fine.
   Check: `git grep -i "<hostname-fragment>"` and `git grep -i "<account-name>"` return nothing.
10. **Screenshot** the passing run in the LE UI test run list showing the run name.
11. **Self-hosted runner.** GitHub repo Settings > Actions > Runners > New self-hosted runner > Windows. Install as a service on a machine inside the network that reaches the appliance and the target (or on the target, per the fallback). Labels `self-hosted`, `windows`. Then Settings > Actions > General: require approval for all outside collaborators on fork PRs.
   Check: runner shows Idle in the Runners page.
12. **Secrets, variables, environment.** Secrets `LE_BASE_URL`, `LE_API_TOKEN`, `TARGET_USER`, `TARGET_PASSWORD`. Variable `LE_SKIP_CERT_CHECK` if needed. Environment `promotion-approval` with Joshua as required reviewer.
   Check: all present in Settings.

Steps 1 to 10 before Prompt A. Steps 11 and 12 before Prompt B.

Change ids: every run needs a new one. Re-running the same id resumes the existing run on purpose.

---

## 9. Remaining engineering: the prompts

Run in a coding agent opened at the repo root. Each starts by reading `CLAUDE.md` and the docs. Do not combine A and B.

### Prompt A: offline build against fixtures (one shot, medium effort)

```
Read HANDOFF.md first. Then read CLAUDE.md, README.md, docs/architecture.md, docs/verdict.md, docs/api-notes.md, docs/contracts.md, and tests/fixtures/README.md. Real fixtures from a completed application test run are in tests/fixtures/. docs/api-notes.md is the only source for endpoint paths and shapes. If you need an endpoint it does not list, stop and ask.

Build everything below offline. No appliance calls are needed; every new function is unit tested against the fixtures with Invoke-RestMethod mocked. PowerShell 5.1 compatible. One function per file. Update the module manifest, CHANGELOG, and docs as you go. Keep prose human: no em dashes, no "actually", "critical", "matters".

1. Results retrieval, in src/LEGate/Public/: Get-LEGateRunOverview (GET /application-test-run-overview/{id}, optional -BaselineRunId passed as testRunIds), Get-LEGateRunSessions, Get-LEGateRunAppExecutions (all sessions, paged), Get-LEGateRunEvents (optional -EventTypes), Get-LEGateRunScreenshots (list and download, only for executions in endedWithErrors, saved under evidence/{changeId}/screenshots/). Plus Export-LEGateRunResults that calls all of them and writes raw JSON under evidence/{changeId}/raw/ before anything evaluates.

2. Evaluator: src/LEGate/Public/Test-LEGatePolicy. Pure function. Inputs: the run object, the overview, the events list, the policy object. Output: a verdict object matching docs/verdict.md (verdict, reasonCodes, changeId, testName, testRunId, policyName, policyHash, promotionMode, evaluatedAt, summary, plus an applications array with per-app status). Rules: result internalError or cancelled -> INCONCLUSIVE; result incomplete -> INCONCLUSIVE results-incomplete; events launcherOffline or connectionInitializationTimeout -> INCONCLUSIVE launcher-or-connection-error; timedOut -> INCONCLUSIVE run-timeout; otherwise every required application (policy functional.requiredApplications, or all applications in the overview when empty) must have appExecutionSuccessful true and appFailureResults.successCount == totalCount and loginSuccessful true -> PASS, else FAIL. Performance is recorded (overThreshold, applicationThresholdExceeded, loginTimeThresholdExceeded) but does not affect the verdict while policy.performance.enabled is false. Policy hash is SHA-256 of the policy file bytes. Unit tests must cover every branch using the fixtures and modified copies of them (build a broken-app variant and an incomplete variant in the test).

3. Evidence bundle: Export-LEGateEvidence. Writes evidence/{changeId}/manifest.json (changeId, testName, testId, testRunId, testRunName, appliance version, apiVersion, policyName, policyHash, baselineRunId, git SHA from GITHUB_SHA or git rev-parse, timestamps, list of files with SHA-256), verdict.json, summary.md (human-readable: verdict, reason codes, per-app table, links to raw files and screenshots). Bundle hash written to manifest. Unit tested.

4. Change adapters in adapters/change/: the contract is in docs/contracts.md. Implement app-update.ps1 (parameters: -Action apply|verify|revert, -TargetComputer, -Credential or -UseCurrentCredentials, -Manifest path). The manifest is a JSON file in examples/changes/ describing the app, before version, after version, install source (winget id or MSI URL), and the executable path. apply installs the after version over WinRM via Invoke-Command (or locally when -TargetComputer is localhost); verify checks the installed version; revert reinstalls the before version. Also break.ps1 with the same parameters: apply installs the after version and then renames the executable to .disabled; revert renames it back. The break must surface in Login Enterprise as an application failure on that app (appExecution endedWithErrors) so the verdict is FAIL, not INCONCLUSIVE; it must only touch the app, never anything login or connection depends on. noop.ps1 returns success for pipeline testing. Every adapter returns JSON {status, changeId, action, details, timestamp}. Unit test argument handling and output shape with Invoke-Command mocked.

5. Handoff adapter (the "ticket"): src/LEGate/Public/ functions New-LEGateChangeIssue (opens an issue titled "[change] {changeId}" with the manifest summary, returns issue number; idempotent, reuses an open issue with that title), Add-LEGateChangeComment (stage name, message, optional links), Close-LEGateChangeIssue. Uses the GitHub REST API with GITHUB_TOKEN and GITHUB_REPOSITORY from the environment. Also Write-LEGatePromotionRecord that writes evidence/{changeId}/promotion-record.json (changeId, verdict, approver from GITHUB_ACTOR, promotionMode, timestamp, continuousTestStarted). Unit tested with mocks.

6. Continuous test handoff: Start-LEGateContinuousTest. Resolves a continuousTest by exact name, checks state is not running, PUT start. Unit tested.

7. Orchestration script: scripts/Invoke-Gate.ps1. Parameters: -ChangeId, -PolicyFile, -ChangeManifest, -PromotionMode, -Adapter (name), -TargetComputer, -BaselineRunId optional, -ContinuousTestName optional, -Revert switch. Steps in order with logging and an issue comment at each: preflight (policy parses against schema, test resolves, test state enabled, no run in progress), adapter apply and verify, start run, wait, export results, evaluate, export evidence, write verdict to $env:GITHUB_OUTPUT when present, exit 0 for PASS, 1 for FAIL, 2 for INCONCLUSIVE. -Revert runs only the adapter revert so the demo can leave the target changed for screenshots. Unit test the step sequencing with every module function mocked.

8. Wire .github/workflows/validate-patch.yml to the module. Add permissions: issues: write, contents: read at the top so GITHUB_TOKEN can open and comment on issues. validate job runs Invoke-Gate.ps1 with secrets LE_BASE_URL, LE_API_TOKEN, TARGET_USER, TARGET_PASSWORD (built into a PSCredential inside the step, never echoed), variable LE_SKIP_CERT_CHECK, inputs change_id, policy_file, promotion_mode, plus new inputs change_manifest (default examples/changes/7zip-update.json), adapter (choice: app-update, break, noop; default app-update), target_computer. Upload evidence/{changeId}/ as an artifact always. promote-manual and promote-auto call Write-LEGatePromotionRecord and comment on the issue. continuous-testing job calls Start-LEGateContinuousTest with input continuous_test_name (default patch-gate-continuous) and closes the issue. Keep the file parseable: every run: value is a block scalar.

9. Examples: examples/changes/7zip-update.json and examples/changes/7zip-break.json with placeholder versions for Joshua to fill in. examples/evidence/ with a sanitized PASS bundle generated from the fixtures by running the evaluator and exporter in a test.

10. Docs: update docs/architecture.md and the README "Repository layout" for the new pieces. Add docs/runbook.md: how to run one change end to end from dispatch to closed issue, how to run the FAIL demo, how to revert the target, how to reset with the VM snapshot. Add docs/pipelines/ with azure-devops.md, gitlab.md, jenkins.md, servicenow.md: same three jobs, same verdict.json and exit codes, where the approval gate and secrets live on each platform; for ServiceNow the issue comments become change-request work notes and the bundle becomes an attachment. One page each.

Run lint and all unit tests, fix what they flag, commit in logical chunks, push to origin main, and give me a report listing every new file and every test count.
```

### Prompt B: live wiring and the two runs (expect iteration, medium effort)

```
Read HANDOFF.md first, then CLAUDE.md and docs/runbook.md. The self-hosted runner is registered with labels self-hosted and windows. Secrets LE_BASE_URL, LE_API_TOKEN, TARGET_USER, TARGET_PASSWORD and variable LE_SKIP_CERT_CHECK are set. Environment promotion-approval exists with a reviewer. Application test patch-gate-app and continuous test patch-gate-continuous exist. The target computer is: <Joshua fills in>. examples/changes/7zip-update.json and 7zip-break.json have real versions.

Do not change the module's logic to make a run pass. If a run fails because of the environment, tell me what to fix in the environment. If it fails because of a bug, fix the bug with a unit test that would have caught it.

1. Run scripts/Invoke-Gate.ps1 locally on the runner machine with -Adapter noop -ChangeId CHG-noop-1 -PromotionMode manual. Confirm the issue opens, the run completes, the verdict is PASS, the evidence bundle is written.
2. Run it with -Adapter app-update -ChangeId CVE-2026-DEMO-7zip-pass -ChangeManifest examples/changes/7zip-update.json. Confirm PASS and that the LE UI shows the run named with the change id.
3. Run it with -Adapter break -ChangeId CVE-2026-DEMO-7zip-fail -ChangeManifest examples/changes/7zip-break.json. Confirm FAIL, the issue stops at the FAIL comment, and screenshots for the failed execution are in the bundle. Then run with -Revert.
4. Dispatch validate-patch from GitHub for the PASS case with promotion_mode manual. Confirm the validate job succeeds, the artifact uploads, promote-manual waits for approval, and after I approve, continuous-testing starts patch-gate-continuous and closes the issue.
5. Dispatch it again for the FAIL case. Confirm the promote jobs are skipped and the issue is left open at FAIL.
6. Copy the sanitized PASS and FAIL bundles into examples/evidence/. Update docs/runbook.md with anything that surprised you. Commit and push.

List the screenshots I should take for the blog: both runs by name in the LE UI, the failed app execution with its screenshot, the GitHub issue trail for both, the workflow graph waiting on approval, the artifact, the continuous test running.
```

### Prompt C: quickstart and polish (short, low effort)

```
Read HANDOFF.md first, then the whole repo. Write the README quickstart: clone, run tests, set env vars, create the two LE tests (link to docs/runbook.md), run the smoke, dispatch the workflow. Under ten steps. Sweep every file for em dashes, the banned words, hostnames, tokens, and account names. Confirm CHANGELOG 0.1.0 lists everything shipped and bump the module version to 0.1.0 released. Confirm ci.yml is green. Commit and push.
```

If credits die mid-prompt: "Read HANDOFF.md and git log --oneline. Continue Prompt A from step N." Every prompt commits in chunks for this reason.

---

## 10. Review prompt for blog and socials (codex-writing-skills repo)

```
Review <file>.md using workspace-weekly then voice-and-tone then avoid-ai-style. Overriding rules: no em dashes; no "actually", "critical", or "matters"; no bullet lists except link lists; vary paragraph length; strip AI patterns. Do not change factual claims or links. Do not add hedging. Give me <file>-edited.md and a short change list. Flag any claim you cannot back.
```

Tell it the verified claims from section 5 are confirmed so it does not re-flag them.

---

## 11. Definition of done for Part 2

- `validate-patch` dispatched from GitHub for the good update produces PASS, uploads an evidence artifact, waits for approval, and after approval starts `patch-gate-continuous` and closes the issue.
- Dispatched with the `break` adapter it produces FAIL, promote jobs are skipped, the issue stays open at the FAIL comment, and the failed execution's screenshot is in the bundle.
- The LE UI shows both runs under `patch-gate-app` with their change ids as run names.
- `examples/evidence/` holds a sanitized PASS and FAIL bundle.
- CI green, lint clean, evaluator unit tests cover every branch.
- `docs/runbook.md` lets someone else reproduce it.
- Part 2 blog draft reviewed by the writing skills; socials drafted.

---

## 12. Risks and fallbacks

- WinRM blocked or flaky: runner on the target VM, `-TargetComputer localhost`.
- Demo app has no workload: the break must hit an app the test exercises; record the workload (section 8 step 4) before anything else.
- Break produces INCONCLUSIVE instead of FAIL: the break touched something login or the launcher depends on. Narrow it to the app's executable.
- Test runs longer than `maxWaitMinutes`: raise it in the policy. INCONCLUSIVE run-timeout is correct behavior, never FAIL.
- Issue calls fail: `permissions: issues: write` in the workflow.
- Certificate errors: `LE_SKIP_CERT_CHECK=true`; never disable validation globally.
- Fixtures leak something: grep for hostname and account name before committing.
- Time runs out: publish Part 2 with offline evidence and say live runs follow. Do not fake.

---

## 13. AI skill (Part 3, only if credits remain)

Decision: no AI in the verdict path. The one piece that adds value without governance trouble is a read-only evidence explainer.

```
Read CLAUDE.md, docs/ai-agents.md, docs/verdict.md, docs/contracts.md, and one PASS and one FAIL bundle in examples/evidence/. Create skills/evidence-explainer/SKILL.md (Agent Skills format: frontmatter with name and description, then instructions) for an assistant handed a path to an evidence bundle. Its job: explain in plain language why the verdict happened, which applications or steps failed and where their screenshots are, which reason codes fired and what they mean, and what to investigate next. Every claim cites a file path inside the bundle. It may only read files. It must never start tests, call the appliance, edit policies or baselines, or restate the verdict as anything other than what verdict.json says. Include examples/ with one worked explanation for the FAIL bundle. Add a section to docs/ai-agents.md describing the skill and its limits. No code beyond SKILL.md and examples.
```

---

## 14. Rules for the public repo

- No appliance hostnames, IPs, tokens, launcher names, account names, or internal URLs anywhere: code, docs, fixtures, screenshots, commit messages.
- No customer names or test names that identify a customer.
- Screenshots from the lab only.
- The API spec may be referenced; every Login Enterprise customer can see it.
- Self-hosted runner on a public repo: fork PR workflows require approval; `validate-patch.yml` stays `workflow_dispatch` only.

---

## 15. Deferred (do not build this week)

Detection adapters (scanner webhook, patch catalog, Autopatch release). Real ServiceNow, Intune, Autopatch, Citrix, Horizon handoffs. Baselines and performance policy. Image-level gate with a real Windows CU. AI evidence explainer. Customer interviews (BankUnited, DTCC) fold in when they land; not blocking.

---

## 16. Trello

Card "Workspace Weekly: Your Deployment Ring Is a Waiting Room": done: define MVP, create repo, export and map spec, build module/tests/CI/docs, verify version call, diagram, blog draft, blog review, socials draft, socials review. Open: Asana, shared doc link, ready-for-review comment, marketing, posting, customer interviews.

Card "Workspace Weekly: Show Me the FAIL": checklist created (LE tests, fixtures, runner, results retrieval, evaluator, adapters, PASS and FAIL runs, evidence bundle, workflow wiring, pipeline notes, README, diagram, blog, review, socials, Asana, marketing, posting, customer scenarios). Nothing done.

---

## 17. Model budget

Prompt A: Opus 5 or Sonnet 5, medium. Prompt B: Sonnet 5, medium, several short turns. Prompt C: Sonnet 5 or Haiku, low. Reviews: whatever the writing-skills repo runs on. AI skill: only after Part 2 ships.
