# Change adapters

An adapter puts the validation target into the changed state. Every adapter implements three operations and returns structured JSON from each:

- `apply`: make the change
- `verify`: confirm the target is in the changed state
- `revert`: put the target back

The reference adapter (Part 2) installs a pinned third-party application update. A second adapter breaks the workflow on purpose so a FAIL run can be shown without faking anything.