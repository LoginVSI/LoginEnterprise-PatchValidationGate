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

A bounded read-only probe under the temporary account authenticated to the target
with normal TLS and the default WSMan proxy selection. Its PowerShell child needed
machine module paths instead of the control account's inherited module paths.
Target credentials were supplied in process memory for that probe and were not
copied from the private credential store onto the runner filesystem.

The initial repository inventory had one branch, no tags, no additional collaborators
and no queued workflows. A generated update branch is now pending review. The execution export contains only hosted CI and the
manual live workflow. There are no PR, pull_request_target, workflow_run or
reusable-workflow entry points, and no caches. Handoff artifacts are selected by
the same workflow run and attempt and checked against separately passed hashes.
Review new refs and workflow changes before bringing the runner online.

The existing approval contract is unchanged. Protected-main PR review authorizes
publishing a generated execution copy. The protected environment authorizes
simulated promotion, and the handoff additionally requires authoritative approval
time evidence bound to repository, run, attempt, environment and reviewer.
The environment currently permits the operator to review their own workflow.
Neither that setting nor the parser requires a second independent human. The
independent requirement in the time-evidence contract concerns authoritative
provenance, not a second person's identity. Missing timestamp evidence remains
a separate blocker even when the operator authorizes promotion. No alternate
approval-request PR mechanism is included.

## Live boundary still open

Target DNS matches the historical address. TCP/5986, normal TLS validation and the
WSMan endpoint respond, including an unauthenticated Negotiate challenge.
Default authenticated WSMan requests stalled in ordinary and elevated client contexts.
An explicit per-session `NoProxyServer` selection established an authenticated
session and read the expected target identity. No firewall, certificate validation,
authentication policy or reboot change was needed. This identifies the working
connection setting; it does not establish the underlying proxy-discovery failure.

The operator confirms exclusive target use and a responsive RDP session. The LE
logon bootstrapper was stopped in that manual session to allow inspection, and
the operator signed out afterward. The operator subsequently observed the bootstrapper
start on another login and signed out. A fresh native session query confirmed no
logged-on users. A passing workload is still needed to establish end-to-end readiness.

The most recent appliance read confirmed the designated test identities, no
unfinished Application Test runs and disabled Continuous Testing. An active
session belonged to another test and was left alone. The fresh authenticated
preflight verified version 23.01 and the recorded baseline executable hash, no
disabled executable copy, idle Windows Installer, and the expected cached installers.
Designated tests were idle, Continuous Testing was disabled, and all recorded locks
were available. Existing journals retain baseline restoration, a reverted lease and
recoveryRequired=false. Refresh these observations before a later mutation.

A subsequent baseline Application Test finished with zero sessions and zero
application executions. Its Events reported `launcherCapacityExceeded`; the
designated launcher group's only member was offline. The gate returned
INCONCLUSIVE (`results-incomplete`). This is not an application PASS or FAIL, and
does not verify bootstrapper readiness. Post-run preflight confirmed the baseline,
idle designated tests, drained target, disabled Continuous Testing and released
locks. The unrelated appliance session was left unchanged.

After the operator brought that launcher online, a new designated Application
Test passed. Post-workload checks again verified the baseline and drained state.
This establishes fresh end-to-end workload readiness, beyond the manual RDP
observation. Both supported shells passed 150 source tests, lint, and synthetic
bundle checks; static workflow/action-pin checks also passed.

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
