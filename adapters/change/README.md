# Change adapters

An adapter puts the validation target into the changed state. Every adapter implements three operations and returns structured JSON from each:

- `apply`: make the change
- `verify`: confirm the target is in the changed state
- `revert`: put the target back

The reference adapter (Part 2) installs a pinned third-party application update. A second adapter breaks the workflow on purpose so a FAIL run can be shown without faking anything.
Implemented scripts: app-update.ps1, break.ps1 and noop.ps1. Each accepts Operation, ChangeId, Target, Parameters JSON, plus explicit Credential or UseCurrentCredentials and optional Local. Each emits one contract JSON result; valid failed results still exit 0.

Pinned MSI manifests require both versions, verified HTTPS sources, SHA-256, product codes, file version, demo-only path and MSI directory property. The worker uses unattended msiexec, bounded waits, checksum and version verification. Reboot-required/nonzero exits require recovery.

Break renames only the selected executable to .legate-disabled. Verify confirms that intended broken state. Revert restores the executable and previous pinned version, reporting restoration separately. These adapters are disposable-lab tools, not production deployment or rollback integrations.
