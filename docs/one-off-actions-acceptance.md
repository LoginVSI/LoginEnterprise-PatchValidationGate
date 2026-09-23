# One-off Actions acceptance checkpoint

This exercise supports a tested preview, walkthrough and product requirements.
It is not an ongoing deployment service. Production promotion remains simulated.

## Verified in the continuation

The original private configuration, account-bound credentials, installer
provenance, capture bundles and recovery journals were recovered. The execution
checkout was restored without losing its previous exported files. Its public
visibility, protected main branch, pinned actions and protected human approval
environment remain intact. Existing hosted CI and count-only artifact digest
checks are recorded in the execution repository's acceptance issue.

The operator selected a temporary supervised laptop runner under a separate
non-admin account. A real process under that account could not enumerate the
everyday profile, SSH/configuration directories or either control checkout tree,
and could not open the original lab credential files or Git configuration. The
checkout roots needed explicit account-specific deny rules because their prior
ACLs allowed Authenticated Users to modify files. Those temporary rules are
journaled for removal. This is restricted use of a shared Windows host, not VM
isolation. The runner has not been registered or given runtime credentials.

Current repository inventory has one branch, no tags, no additional collaborators
and no queued workflows. The execution export contains only hosted CI and the
manual live workflow. There are no PR, pull_request_target, workflow_run or
reusable-workflow entry points, and no caches. Handoff artifacts are selected by
the same workflow run and attempt and checked against separately passed hashes.
Review new refs and workflow changes before bringing the runner online.

The approval implementation now supports a separately identified PR review over
an immutable acceptance request. It reads the reviewer, reviewed commit and
submission timestamp from GitHub, validates the run/attempt/environment and exact
validation manifest, and retains source responses. It still requires the protected
environment. The environment button's timestamp is not inferred. Offline tests
cover success, identity mismatches, changed requests, dismissed/superseded reviews,
permissions, incomplete history and restricted API paths. Real approval acquisition
remains unaccepted until an actual correlated review is obtained.

## Live boundary still open

Target DNS matches the historical address. TCP/5986, normal TLS validation and the
WSMan endpoint respond, including an unauthenticated Negotiate challenge.
Authenticated WSMan requests stall in both ordinary and elevated client contexts.
Bounded diagnostics were stopped without changing firewall, certificate checks,
authentication policy or rebooting the target. Target-side logs are needed before
choosing a remedy; connectivity alone does not establish authentication success.

The operator confirms exclusive target use and a responsive RDP session. The LE
logon bootstrapper was stopped in that manual session to allow inspection, and
the operator signed out afterward. Verify session drain and next-login bootstrapper
readiness before any workload. Do not infer either from successful RDP access.

The most recent appliance read confirmed the designated test identities, no
unfinished Application Test runs and disabled Continuous Testing. An active
session belonged to another test and was left alone. Current target executable,
installer state, session drain and bootstrapper readiness have not yet been
verified. Historical journals retain baseline restoration, a reverted lease and
recoveryRequired=false; those records are not a fresh guest observation.

No live Actions run, new mutation, simulated promotion, issue lifecycle or
Continuous Test handoff is claimed by this checkpoint. Preserve the original
[local walkthrough](tested-lab-walkthrough.md) and distinguish its results from
the pending Actions acceptance.

## Bounded execution and closeout

Before registration, prove the temporary account's access limits and trusted
runtime prerequisites. Use the existing canonical durable state, never a parallel
empty lease store. Give the runner only the specific state/evidence access it
needs; do not copy the operator's DPAPI store or grant general profile access.
Supply only reviewed runtime credentials and keep the runner online during the
supervised window. Labels and temporary registration do not enforce trust.

Keep recovery supervision outside the workflow with the original pinned inputs
and credential store. Workflow cancellation or timeout is not proof that an
installer, test or session stopped. Observe natural completion within the agreed
bound, disable and drain designated Continuous Testing, and restore only after
idle state is established. Verify baseline file/version/hash and fresh workloads
after each scenario. Preserve recovery-required state on uncertainty.

When finished, or blocked without imminent continuation, stop and unregister the
runner. Remove task-created runtime secrets, the temporary account credential,
account and its specific ACL entries. Preserve private evidence, original recovery
credentials, leases and journals through the independent audit. Do not remove
recovery access while recovery is outstanding.

## Product requirements supported by these findings

The reference supplies deterministic application verdicts, evidence integrity,
sanitized publication, durable leases and separate handoff records. It does not
provide a resident recovery supervisor, secure runner lifecycle, an approval UI,
or automatic workload observation after enabling continuous scheduling.

A native product would need durable orchestration outside a disposable execution
worker, an approval decision bound to immutable evidence with native audit time,
credential delivery and revocation, session-aware recovery, bootstrapper readiness
checks, and explicit observation of continuous workload outcomes. These are product
requirements, not capabilities proven by the current reference.
