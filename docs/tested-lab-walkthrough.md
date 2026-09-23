# Tested local lab walkthrough

Local acceptance on 2026-09-22 used LE 6.8.6, the v8-preview API, PowerShell 7, and a disposable Windows target over HTTPS/5986 with explicit Negotiate credentials and normal certificate validation. Private configuration and DPAPI credentials stayed outside the checkout and OneDrive. The public module does not depend on that credential store.

## Observed sequence

| Step | Actual result |
|---|---|
| Recover an interrupted update | Restored 7-Zip 23.01; exact executable version/hash and fresh Notepad plus archive workloads passed |
| Public app-update validation, 23.01 to 26.03 | PASS |
| Public revert, then independent file and workload verification | 23.01 restored; both applications passed |
| Public break validation | FAIL with application-failed, a native failed execution, related Event and downloaded JPEG |
| Public revert, then independent file and workload verification | 23.01 restored; both applications passed |
| Bounded Continuous Test check | Both applications executed successfully; scheduling subsequently disabled and sessions drained |

The break adapter first installs 26.03 and renames its executable with the `.legate-disabled` suffix. This deliberately breaks the application after the otherwise passing update. Revert restores the executable name and reinstalls 23.01. It is not evidence that the unmodified 26.03 installer is defective. LE reported the failed run's overall orchestration result as successful, while the application execution endedWithErrors. The gate correctly used application evidence to return FAIL.

Validation and restoration used `Invoke-LEGateValidation` with the same target, transport, port, credentials, manifest, response profile, change ID and durable StateRoot. Revert used `-Revert -RecoveryConfirmed` after review of idle state. A private outer supervisor ran restoration in `finally`, then independently checked file version/hash and started a fresh workload. It stopped further scenarios unless restoration passed. The public validation command itself does not automatically restore after every verdict; callers must implement this supervision and retain recovery records on failure.

Continuous acceptance exercised `Start-LEGateContinuousTest`, run/session/execution collection and `Stop-LEGateContinuousTest`. The start response alone was not treated as workload proof. The stop function separately verifies disabled scheduling and absence of sessions belonging to that test. Other tests' sessions still need an all-target check before mutation. Final private checks observed no active sessions, no unfinished Application Tests, the baseline executable present, no disabled executable, and a reverted gate lease. Lock files and historical recovery records were retained; their file locks were released.

## Reproduce safely

Follow [setup](setup.md) and [first capture](first-live-capture.md) with your own target, workload identities and reviewed response profile. Preserve the initial baseline, independent recovery procedure and shared durable state. An operator-confirmed snapshot is bootstrap recovery evidence when its name, owner, procedure and access are recorded privately; it is not a claim of API verification or a tested restore.

Run the read-only `Get-LEGateInstallerState` preflight under exclusive ownership immediately before mutation. Require safeToInstall; inspect the full observation privately on failure. A running Windows Installer service can be idle. Accepted stop controls, service PID, client processes and the in-progress registry marker distinguish the observed idle service from busy or unknown state. Do not remove safety checks or terminate msiexec to proceed. This check is an observation, not a lock against an unrelated installer starting later.

The adapter accepts a pinned HTTPS installer URL and verifies SHA-256. It does not follow redirects. Official vendor links in this lab redirected to vendor release assets. Official bytes were downloaded privately, compared with existing target MSI hashes and staged into the adapter's hash-named cache without overwriting the originals. This acceptance verifies hash-pinned cached installation, not unattended redirecting downloads. For a fresh target, use a reviewed direct HTTPS source or separately stage verified bytes to `installDirectory/installer-<sha256>.msi`; retain the source chain and byte comparison privately. Never invent provenance from a filename.

Set policy `execution.maxWaitMinutes` and `execution.pollIntervalSeconds` before starting. The local runs used 45 minutes and 30 seconds. The supported ranges are 1–3600 minutes and 1–3600 seconds, respectively; customer workloads can take over an hour. Tests finish naturally within that budget. Timeout does not cancel a workload or prove sessions drained. Preserve recovery-required state and inspect before restoring. The bounded Continuous check used a separate 10-minute workload observation and 15-minute drain budget.

## Acceptance limits

PASS and deliberate FAIL are live observations. INCONCLUSIVE, malformed identity handling, late responses and interruption edges have offline regression coverage; no live infrastructure fault was induced. The sanitized genuine fixtures preserve observed success/failure shapes and relationships, while screenshots and original identifiers stay private.

GitHub Actions execution, environment protection, issue reporting/closure, authoritative approval acquisition and simulated promotion remain pending. Production promotion is not implemented. Snapshot existence is operator-confirmed and no snapshot restore was performed. Live PowerShell 5.1 mutation was not repeated; both supported shells run the offline tests and lint. The [approval evidence limitation](approval-evidence.md) stays fail-closed. Prepare the later Actions copy using [pinned development exports](private-execution-repository.md).
