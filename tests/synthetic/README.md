# Synthetic fixtures

These inputs were authored for offline tests. They are not captured from Login Enterprise and do not confirm API response shapes. pass.json, fail.json and inconclusive.json exercise normalization and policy. FullFlow.Tests supplies synthetic HTTP pages and a one-pixel PNG through mocked external boundaries.

The synthetic response profile is forbidden in live gate evaluation. Never relabel it as capture-confirmed. Use docs/api-assumptions.md to establish a live profile from private captures.
