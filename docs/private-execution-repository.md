# Actions execution repository

Keep LoginVSI/LoginEnterprise-PatchValidationGate as the development source.
The personal repository is a generated execution copy, not a second
implementation. No organization-owner access is needed to prepare this copy.

After selecting an exact owner/repository and reviewing a development
commit, run scripts/Export-ExecutionRepository.ps1 with Repository, the full
SourceCommit and a new Destination outside the checkout. This exports tracked
files from that commit, changes only the exact execution-repository guard, and
writes execution-source.json. The main-branch restriction, pinned actions,
permissions, environment gate, concurrency and evidence guards remain intact.
The command makes no GitHub calls and refuses to overwrite existing exports.

Later, under separate authorization:
1. Create the private personal repository with Actions disabled initially.
2. Review and import the generated files to protected main. Retain the source
   commit record. Never copy local configuration, credential stores or captures.
3. Configure an isolated Windows runner, private durable state/evidence roots,
   secrets and variables from the setup runbook. Use HTTPS target transport.
4. Configure environment protection and establish authoritative approval-time
   evidence before enabling the manual promotion demonstration.
5. Enable Actions and dispatch only after the complete workflow is reviewed.

For each update, export a fresh reviewed development commit for the same exact
execution repository. Review the generated diff and import it through the
private repository's protected update process. Put implementation fixes back
in the development repository, then regenerate. Do not edit divergent copies.

Local acceptance does not validate GitHub environments, runner isolation,
approval provenance or workflow execution. Those remain separately testable
acceptance items; a generated export is preparation, not a deployment.

## Public execution copy

Public visibility is supported for the generated source and reviewed evidence.
Pass `-PublicRepository` to the exporter for a public execution repository.
The export records this choice in `execution-source.json` and removes the
`pull_request` CI trigger. Push CI on `main` remains on GitHub-hosted Windows
runners. Development PR validation stays in the LoginVSI source repository.

This difference is necessary before attaching a lab runner. A pull request can
change a workflow's runner selection; the current `windows-latest` value alone
does not keep attacker-controlled PR workflows away from a registered runner.
Do not approve execution-copy PR workflows or add `pull_request_target`,
`workflow_run`, reusable workflow entry points, or artifact/cache consumers
that execute untrusted content. Review every workflow before registration and
after each export. See GitHub's [self-hosted runner security guidance](https://docs.github.com/en/actions/reference/security/secure-use).

Keep Actions disabled during initial import. Protect `main`, require review of
workflow changes, restrict actions to the reviewed pinned set, use read-only
default workflow permissions, and require approval for all outside-contributor
workflows. Configure `promotion-approval` with trusted human reviewers, main-only
deployment branches and administrator bypass disabled. These repository controls
do not substitute for an isolated runner.

Use a dedicated Windows VM with a separate service identity, restricted network
access to the designated lab and private storage, and no work or personal account
credential stores. A label, folder, or ephemeral registration is not isolation.
Personal repositories do not supply organization runner-group workflow restrictions.
Do not assume those controls exist. Keep the runner disconnected until the entire
dispatch and recovery path is reviewed and its independent supervisor is ready.

Provision only runtime secrets into the chosen protected mechanism. Retain raw
captures and recovery journals outside checkout with explicit ACLs. Retain public
sanitized artifacts for seven days, as configured by the workflow. Remove runtime
secrets and unregister the runner when retiring the demo; retain recovery records
until baseline verification is complete. Never copy a personal DPAPI store to it.

The workflow currently has no automatic restoration supervisor. An `always()`
step or PowerShell `finally` alone cannot cover runner loss or forced cancellation.
Before live dispatch, provision an independent supervisor with the original pinned
configuration, shared state and exclusive ownership. It must observe workload
completion and all relevant sessions, disable and drain Continuous Testing,
restore only after idle state is established, verify the exact baseline executable
and fresh workloads, and preserve uncertain recovery state on any failure.
The existing operator recovery procedure remains required until that integration
is implemented and verified. Do not register a runner and use a live run to test
whether recovery happens.
