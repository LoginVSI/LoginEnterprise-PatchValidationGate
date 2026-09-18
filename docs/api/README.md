# Login Enterprise OpenAPI reference snapshots

These reviewed copies come from the two original JSON exports supplied privately for this project. The originals remain unchanged under `.private/api-input/`. The files identify themselves as Login Enterprise OpenAPI 3.0.1 documents. Their API version metadata and endpoint prefixes support their filenames:

| Reference | `info.version` | Path prefix | Paths | Operations | Component schemas |
|---|---|---|---:|---:|---:|
| [login-enterprise-v7.openapi.json](login-enterprise-v7.openapi.json) | `7.0` | `/v7/` | 137 | 234 | 320 |
| [login-enterprise-v8-preview.openapi.json](login-enterprise-v8-preview.openapi.json) | `8.0-preview` | `/v8-preview/` | 219 | 344 | 486 |

Both use the relative server URL `/publicApi`. They describe endpoints, parameters, request/response schemas and security requirements for tests, runs, sessions, applications, events, measurements, screenshots and other appliance management resources. Neither contains explicit OpenAPI `example` or `examples` entries. Descriptions include generic illustrations such as time intervals and a bearer-token placeholder; defaults are numbers, booleans or empty strings.

The exports define a system access token in the Authorization header as an `apiKey` scheme named Bearer, an OAuth2 client-credentials flow with an `api` scope, and OpenID Connect discovery. Their operation-level security requirements are preserved exactly, without reinterpretation or correction. Credential-related schema properties describe fields, not supplied credentials.

## Provenance and limits

The established provenance is user-supplied static exports with the metadata above. Neither file establishes the exporting appliance's installed version, build or export date. API version numbers are not appliance version numbers. The shared description mentions product release history, and SystemVersionResult describes version response fields; neither provides an observed appliance version. No export date has been inferred from filesystem timestamps.

**v8-preview is this project's implementation target.** The v7 snapshot is a comparison reference, not a claim of v7 compatibility. Vendor version recommendations and preview warnings in the exported descriptions are retained as snapshot content, not independently verified current support guidance.

These files are static reference snapshots, not runtime dependencies. They are not used to generate a client or to configure a live connection. Specification review does not establish live acceptance, confirm response profiles, or prove actual behavior on a target appliance. Genuine responses and the separate live-acceptance procedure remain necessary.

## Public review and sanitization

Each original contained the same export-specific HTTPS origin in three locations. In each public copy, only that origin was replaced with the non-resolving placeholder `https://appliance.example.invalid`:

- `info.x-logo.url`
- `components.securitySchemes.oauth2.flows.clientCredentials.tokenUrl`
- `components.securitySchemes.OpenIdConnect.openIdConnectUrl`

URL paths and HTTPS were retained. The relative server, endpoint definitions, security requirements, scopes, schemas, descriptions, defaults and all other bytes were left unchanged. The placeholder is not a live service address.

Review found no embedded credential values, identifying examples or content marked confidential/internal-only beyond those origin values. Administrative API definitions and ordinary Internal Server Error response descriptions remain intact. No concrete sensitive values are reproduced here.

Both originals and public copies parse as strict JSON without duplicate keys. Every local `$ref` resolves within its document. Exact source-to-copy comparison confirms only the three URL values per file changed. These checks are JSON/reference checks, not a claim of complete OpenAPI conformance or live API compatibility.
