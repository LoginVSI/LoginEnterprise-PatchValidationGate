# Login Enterprise Patch Validation Gate

A PowerShell reference project that applies a lab change, runs an existing Login Enterprise application test, preserves evidence, and evaluates functional policy. PASS can proceed through approval to **simulated production promotion** and an existing continuous test. FAIL and INCONCLUSIVE block promotion.

The offline implementation includes adapters, collection, evaluation, integrity checks, publication sanitization, GitHub reporting, Actions orchestration, recovery tools, and a read-only evidence explainer. **Live acceptance is pending. No genuine appliance fixtures are committed.** PASS describes configured workflows on the tested target, not patch safety.

## Offline quickstart

From the repository root:

```powershell
pwsh -NoProfile -File scripts/Invoke-OfflineScenario.ps1
pwsh -NoProfile -File tests/Invoke-Tests.ps1 -Output Normal
pwsh -NoProfile -File scripts/Invoke-Lint.ps1
```

Windows PowerShell 5.1 supports these scripts too. Where policy permits:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/Invoke-OfflineScenario.ps1
```

The scenarios generate labeled synthetic PASS, FAIL, and INCONCLUSIVE bundles in .private/offline without credentials. Pester 5 and PSScriptAnalyzer are needed for tests/lint. See [setup](docs/setup.md).

## Next steps

Use the [runbook](docs/runbook.md), [live acceptance checklist](docs/live-acceptance.md), and [API assumptions](docs/api-assumptions.md). Configure both existing tests, both required application IDs, verified pinned installers, credentials, private storage, and a capture-confirmed response profile. Placeholders intentionally fail live preflight.

Read the [contracts](docs/contracts.md), [verdict](docs/verdict.md), [security](docs/security.md), [portability notes](docs/portability.md), and [evidence-explainer skill](.agents/skills/evidence-explainer/SKILL.md). Current context is in [HANDOFF.md](HANDOFF.md).

Production integrations, Windows cumulative updates, scanners, and statistical performance qualification remain extension points. Part 1 is published. The Part 2 article needs genuine demonstrations; synthetic examples are not blog results.
