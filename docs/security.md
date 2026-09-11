# Security

## This repo is public

Nothing that identifies a real environment goes in. That means no hostnames, no IP addresses, no internal URLs, no tokens, no customer or project names, and no account names. The rule applies to code, comments, docs, fixtures, test names, workflow files, and commit messages. If in doubt, replace it with `appliance.example.test`, `user01`, or a placeholder id.

Evidence folders are excluded by `.gitignore` because they contain raw appliance output and, later, screenshots. Do not force-add them.

## Secrets

Credentials come from two environment variables, `LE_BASE_URL` and `LE_API_TOKEN`, and nowhere else. The module does not read a config file for them and does not write them anywhere.

Inside the module the token is stored as a SecureString on the session object, so dumping the session with `ConvertTo-Json` or `Format-List` does not print it. It is turned back into text only for the duration of a single request. `Connect-LEGate` registers the token with the redaction helper, and every log line and every error message the module produces passes through that helper before it is written. Anything that looks like `Bearer <token>` is masked even if it was never registered.

If a token does leak into a log, a screenshot, or a chat, rotate it in the appliance. Redaction is a safety net, not a substitute for care.

In GitHub Actions, keep the token in a repository or environment secret and expose it to the job only as `LE_API_TOKEN`. Never echo secrets in a step. The hosted CI workflow, `ci.yml`, needs no secrets at all and runs no appliance calls.

## Least-privilege token

Create the appliance system access token with a role that can read tests, read test runs and results, and start a test. Nothing in this repo needs more. Do not use an administrator token for the gate, even in a lab, because habits carry over. The scope is described in more detail in `docs/setup.md`.

## Self-hosted runner

The gate workflow, `validate-patch.yml`, runs on a self-hosted Windows runner because it has to reach the appliance and, later, the validation target. Things to get right before that runner exists:

- Run the runner service under a dedicated, non-administrative account. It needs network access to the appliance and enough rights to write the evidence folder. It does not need rights on the validation target; the change adapter handles that boundary and should be reviewed separately.
- Do not let pull requests from forks run on the self-hosted runner. Restrict the workflow to `workflow_dispatch` and protected branches. A hosted runner is fine for anything that does not need the appliance, which is why `ci.yml` uses one.
- Keep the runner's working directory clean between jobs. Evidence from a previous change should not be sitting there when the next one starts.
- Treat the evidence artifact as sensitive. Run output can include application names, user names from the test accounts, and screenshots of a desktop. Scope artifact retention and who can download it accordingly.
- Pin action versions and review runner updates like any other software on that host.

## What the gate does not do

It never deploys, never rolls back, and never modifies the appliance beyond starting a test that already exists. A compromised token from this repo's role could start test runs and read results. It could not change tests, accounts, or settings. Keep it that way when you extend the module.

## Reporting a problem

Open a private security advisory on the repository. Do not open a public issue for anything that might involve a real environment.
