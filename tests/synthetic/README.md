# Synthetic fixtures

These authored inputs are not captured from Login Enterprise. Their overview nesting, eventType and relationship fields follow the reviewed v8-preview schemas in docs/api. Short symbolic IDs keep tests readable; these are partial response fixtures, not complete vendor responses or full UUID-format conformance samples. They exercise normalization and deterministic policy without claiming live acceptance.

SpecAlignment.Tests.ps1 asserts relevant schema facts against the actual static snapshot and exercises affected functions. FullFlow.Tests supplies synthetic HTTP pages and a one-pixel PNG through mocked external boundaries. The committed evidence-explainer bundles are separate fixed examples and retain their original bytes/hashes.

The synthetic profile is forbidden in live gate evaluation. Never relabel it capture-confirmed. Use docs/api-assumptions.md and the private capture bootstrap to establish genuine mappings.
