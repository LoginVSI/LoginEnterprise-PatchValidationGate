# CLAUDE.md

Reference implementation: Login Enterprise as an evidence gate for patch promotion. Read README.md, docs/architecture.md, docs/verdict.md, and docs/api-notes.md before touching code. The long version of this file, written for AI coding agents, is docs/ai-agents.md. The integration shapes are in docs/contracts.md.

## Hard rules

- PowerShell 5.1 compatible everywhere. No PowerShell 7-only syntax (no ternary, no null-coalescing, no `ForEach-Object -Parallel`).
- Thin wrapper over `Invoke-RestMethod`. Do not generate a client from the OpenAPI spec. Do not add the PSLoginEnterprise module.
- `docs/api-notes.md` is the only source for endpoint paths, parameters, and response shapes. If it doesn't list an endpoint, don't call it. If something in the notes looks wrong, stop and say so instead of guessing.
- API version is a config value (default `v8-preview`). Base path is `{baseUrl}/publicApi/{apiVersion}`.
- Credentials come from environment variables `LE_BASE_URL` and `LE_API_TOKEN`. Never write them to disk, never echo the token, redact it in any log or error output.
- This repo is public. No hostnames, IPs, tokens, customer names, or internal URLs in code, docs, comments, fixtures, or commit messages.
- The verdict evaluator must be a pure function: results and policy in, verdict out, no network.
- Timeouts and infrastructure errors produce INCONCLUSIVE, never FAIL.
- Prose in docs and comments should read like a person wrote it. No em dashes.

## Layout

- `src/LEGate/LEGate.psm1` dot-sources `Private/*.ps1` then `Public/*.ps1` and exports only Public. One function per file, `Verb-LEGate*` naming for public functions.
- All HTTP through `Private/Invoke-LEGateRequest.ps1`. All logging through `Private/Write-LEGateLog.ps1`. All timestamps UTC ISO 8601 via `Private/ConvertTo-LEGateTimestamp.ps1`. Reason codes live only in `Private/Get-LEGateReasonCodes.ps1`.
- `policies/` holds policy files and the schema. `docs/` holds the human docs. `adapters/change/` is for later.
- Tests go in `tests/unit` (mocked HTTP) and `tests/integration` (real appliance, skipped without env vars) as Pester 5. Fixtures in `tests/fixtures/`, sanitized.

## Approved Part 2 scope (2026-09-17)

The implemented foundation is auth, the version call, exact application-test resolution, start/resume, polling, and raw run output. Approved Part 2 work extends it with fixture-backed results retrieval, a pure evaluator, contract-compliant evidence, scoped lab change adapters, GitHub issue/approval handoff, simulated promotion, and starting a pre-existing continuous test. Read HANDOFF.md for current gaps, prerequisites, and the next checkpoint; Joshua supplies execution prompts separately, and each task prompt determines the work authorized for that turn. Production deployment integrations, Windows cumulative updates, baseline/performance policy, and AI remain deferred. The technical rules above still apply; adapters/change is now within the approved Part 2 scope.
