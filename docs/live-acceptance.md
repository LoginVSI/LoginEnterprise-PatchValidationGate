# Live acceptance and blog capture

Status: pending. No live workflow or appliance call was made during the offline implementation.

- [ ] Verify isolated runner, protected branch/environment, permissions, shared private state and TLS.
- [ ] Configure patch-gate-app and patch-gate-continuous for Notepad plus the chosen demo app.
- [ ] Stop continuous testing; establish a restorable working baseline.
- [ ] Capture genuine success, then a verified reversible app-only failure with failure events and screenshot metadata/bytes. Restore immediately and verify the initial version/workload.
- [ ] Resolve every row in api-assumptions.md from captures and matching spec. Configure explicit application IDs and pinned installer provenance.
- [ ] Run a good update under a fresh ID. Verify PASS, sanitized artifact integrity, actual reviewer/time evidence, simulated promotion, continuous start and issue closure.
- [ ] Stop continuous testing, revert and verify restoration.
- [ ] Run the break under another fresh ID. Verify FAIL, screenshot relationship, skipped promotion/continuous start and open issue.
- [ ] Revert and verify restoration. Capture recovery behavior without claiming mocked restore is real restore.

Blog screenshots: LE UI with both named runs; failed execution and reviewed screenshot; FAIL workflow with skipped promotion; open failure issue; PASS workflow waiting for approval; actual approval provenance; sanitized artifact and hashes; simulated promotion record; continuous test running and closed success issue; restoration evidence.

Keep originals private. Review every public screenshot's pixels and metadata. Write the finished article only from genuine accepted results. Part 1 and its socials are already published. Part 2 remains incomplete until these live checks and editorial work are done.
