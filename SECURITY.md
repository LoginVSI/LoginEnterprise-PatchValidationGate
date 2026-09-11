# Security

This is a public repository. The rules for secrets, tokens, the self-hosted runner, and reporting a problem are in [docs/security.md](docs/security.md).

The short version: never commit a hostname, IP address, token, or customer name. Credentials only ever come from `LE_BASE_URL` and `LE_API_TOKEN` in the environment. The appliance token should have the smallest role that can read tests and test runs and start a test.

To report a vulnerability in this reference implementation, open a private security advisory on the repository rather than a public issue.
