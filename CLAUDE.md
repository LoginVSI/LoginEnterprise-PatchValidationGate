# Repository guidance

Shared contributor instructions for Codex and Claude. Read [README](README.md), [architecture](docs/architecture.md), [verdict](docs/verdict.md), [API notes](docs/api-notes.md) and [contracts](docs/contracts.md). See [contributing](docs/contributing.md) for checks and [agent guidance](docs/ai-agents.md) for working boundaries.

- Support Windows PowerShell 5.1. Use one function per file; public functions use Verb-LEGate names and appear in FunctionsToExport. Private helpers are not exported.
- Use thin Invoke-RestMethod wrappers, no generated SDK or PSLoginEnterprise. Appliance calls go through Invoke-LEGateRequest; GitHub uses its separate fixed-origin helper. Only GET is retried.
- Update API notes from the reviewed OpenAPI snapshot before adding endpoints. Keep unresolved behavior explicit. API version is configurable, default v8-preview, under /publicApi/{apiVersion}; never select a newer version automatically.
- Read credentials from private environment variables. Never persist or echo tokens. Keep genuine captures private; review public values, screenshots and metadata for identifying data.
- Keep the evaluator pure and deterministic. Incomplete evidence, timeouts and infrastructure errors produce INCONCLUSIVE. Preserve evidence integrity, target locks, durable recovery and resume identity.
- Use centralized logging, timestamps and reason codes. Add meaningful offline regression coverage and run tests/lint in both supported shells.
- Maintain the read-only boundary of [.agents/skills/evidence-explainer/SKILL.md](.agents/skills/evidence-explainer/SKILL.md). Customer prompts are in [Explain evidence](docs/explain-evidence.md).

Production promotion is simulated. Local lab validation, restoration and bounded Continuous Test execution are verified; GitHub workflow acceptance and authoritative approval-time acquisition remain pending. [Live acceptance](docs/live-acceptance.md) and [implementation progress](docs/implementation-progress.md) contain the public prerequisites and current verification status.
