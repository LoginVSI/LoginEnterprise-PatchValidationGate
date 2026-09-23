# Private Actions execution repository

Keep LoginVSI/LoginEnterprise-PatchValidationGate as the development source.
The private personal repository is a generated execution copy, not a second
implementation. No organization-owner access is needed to prepare this copy.

After selecting an exact private owner/repository and reviewing a development
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
