# Live acceptance

Current continuation status: live Actions validation produced the expected good-update
PASS and deliberate application FAIL. Both artifact downloads passed digest and bundle
checks. Independent restoration and fresh baseline workloads passed after each scenario.
Temporary runner access and runtime secrets were removed. Authoritative approval-time
evidence, simulated promotion, Actions Continuous Test handoff and good-issue closure
remain blocked. See the [one-off acceptance record](one-off-actions-acceptance.md).
The setup-pass narrative below describes the earlier machine and is historical.

The 2026-09-23 public Actions setup pass found an empty execution repository and
verified separate personal administration credentials. Its current machine has no
previous private handoff or recovery material, and no isolated runner access route
has been supplied. Public export hardening does not satisfy the live checklist.
Do not dispatch mutations until those inputs, independent recovery supervision
and authoritative approval acquisition are established.

Local lab acceptance completed on 2026-09-22 (local date) using LE 6.8.6 and v8-preview over validated TLS. The supported repository validation and revert paths were exercised. See [tested lab walkthrough](tested-lab-walkthrough.md) for scope, recovery behavior and remaining gaps. No GitHub workflow was dispatched and no promotion was performed.

Verified privately: recovery from interrupted mutation; good-update PASS; deliberate-break FAIL with native application failure and screenshot bytes; exact baseline file/version/hash and fresh passing workloads after each restoration; Continuous Test workload execution followed by scheduling disablement and observed session drain. The snapshot remains operator-confirmed, not independently inspected or restore-tested.

The full workflow demonstration still requires the following. Local completion does not satisfy GitHub approval or issue-reporting acceptance.

- [ ] Verify isolated runner, protected branch/environment, permissions, shared private state and TLS.
- [ ] Configure patch-gate-app and patch-gate-continuous for Notepad plus the chosen demo app.
- [ ] Disable continuous scheduling, drain sessions and establish a restorable working baseline.
- [ ] Capture genuine success, then a verified reversible app-only failure with failure events and screenshot metadata/bytes. Restore immediately and verify the initial version/workload.
- [ ] Resolve every row in api-assumptions.md from captures and matching spec. Configure explicit application IDs and pinned installer provenance.
- [ ] Verify authoritative approval event access, timestamp semantics, repository/run/attempt/environment/reviewer correlation and private delivery before the manual demonstration.
- [ ] Run a good update under a fresh ID. Verify PASS, sanitized artifact integrity, actual reviewer/time evidence, simulated promotion, continuous start and issue closure.
- [ ] Stop continuous testing, revert and verify restoration.
- [ ] Run the break under another fresh ID. Verify FAIL, screenshot relationship, skipped promotion/continuous start and open issue.
- [ ] Revert and verify restoration. Capture recovery behavior without claiming mocked restore is real restore.

Private acceptance evidence: LE UI with both named runs; failed execution and reviewed screenshot; FAIL workflow with skipped promotion; open failure issue; PASS workflow waiting for approval; actual approval provenance; sanitized artifact and hashes; simulated promotion record; continuous scheduling enabled, an observed successful workload iteration and closed success issue; restoration evidence.

Keep originals private. Review any proposed public screenshot pixels and metadata. Specification review and synthetic checks do not fulfill this checklist.
