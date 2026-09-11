# CLAUDE.md

Reference implementation: Login Enterprise as an evidence gate for patch promotion. Read README.md, docs/architecture.md, docs/verdict.md, and docs/api-notes.md before touching code.

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

- `src/LEGate/LEGate.psm1` dot-sources `src/LEGate/Public/*.ps1`. One function per file, `Verb-LEGate*` naming.
- `policies/` holds policy files and the schema. `docs/` holds the human docs. `adapters/change/` is for later.
- Tests go in `tests/` as Pester. Fixtures in `tests/fixtures/`, sanitized.

## Scope today (2026-09-11)

Auth, one real call (`GET /system/version`), resolve an application test by exact name, start it, poll to `completed`, dump the raw run to `evidence/{changeId}/`. Nothing else. No evaluator, no evidence bundle, no adapters, no runner, no AI.
