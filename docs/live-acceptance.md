# Live acceptance

Status: pending. No live workflow or appliance call was made during the offline implementation.

Private capture is conditionally ready for a supervised operator session using [the bootstrap procedure](first-live-capture.md), once exclusive ownership and independent recovery are verified. Full demonstration is not ready: genuine response/installer/restoration acceptance and [authoritative approval-time acquisition](approval-evidence.md) remain prerequisites. Bounded envelope delivery does not establish source provenance.

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
