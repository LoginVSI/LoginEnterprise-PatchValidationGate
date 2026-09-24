# Approval-time evidence prerequisite

The 2026-09-23 Actions pass retained this contract. The configured environment
allows the operator to authorize their own workflow; the parser does not require
a second independent human. Protected-main PR review is a separate publication
requirement. Neither substitutes for authoritative approval-time provenance.
No new approval-request PR flow was introduced. Validation and recovery passed,
but the blocked downstream flow was canceled rather than supplied invented time
evidence. See the [acceptance record](one-off-actions-acceptance.md).

Rechecked for the local acceptance wrap-up on 2026-09-22: authoritative acquisition is blocked externally. The repository implements bounded file delivery and conservative correlation checks. It does not authenticate an operator-written envelope or turn matching fields into proof of approval.

The official [REST review-history documentation](https://docs.github.com/en/rest/actions/workflow-runs#get-the-review-history-for-a-workflow-run) supplies reviewer, state and environments, but no approval timestamp or attempt binding. Environment creation/update times describe the environment. The [GraphQL DeploymentReview fields](https://docs.github.com/en/graphql/reference/deployments#deploymentreview) likewise provide no approval timestamp; deployment-status creation time is not review time.

The documented [workflows.approve_workflow_job audit event](https://docs.github.com/en/organizations/keeping-your-organization-secure/managing-security-settings-for-your-organization/audit-log-events-for-your-organization#workflows) includes timestamp, actor, repository and workflow-run fields, but its listed fields do not establish environment/run-attempt correlation. No organization access or actual matching response has been verified. The [deployment_review webhook](https://docs.github.com/en/webhooks/webhook-events-and-payloads#deployment_review) is available to GitHub Apps with deployment read permission; its listed since field does not document approval-time semantics. We cannot assume those semantics or introduce a speculative collector.

A personal execution repository does not supply organization audit access. No authorized live webhook capture or trusted producer was available in this pass. Local PASS/FAIL acceptance therefore leaves this boundary unchanged and fail-closed.

## What must be established

An authorized operator must provide a genuine privately retained source response whose documented timestamp means approval, with a verified join to this repository, workflow run and attempt, promotion-approval environment, and actual reviewer. Establish source permissions/access, correlation for reruns and multiple environments, and delivery timing on the intended runner. Review the underlying evidence, not just an envelope. If those facts cannot be established, manual promotion stays blocked. Do not dispatch the live demonstration to discover this halfway through.

## Existing delivery boundary

After that prerequisite is met, a trusted producer can deliver the repository's envelope to the access-controlled path configured by LE_APPROVAL_TIME_EVIDENCE. Use a fresh destination for the intended run/attempt or retire the previous file before approval under exclusive operator ownership. Do not overwrite an earlier attempt's evidence. Retain the original source response alongside the derived envelope privately.

The envelope requires kind=github-approval-time-evidence, repository, workflowRunId, workflowRunAttempt, environment, reviewer, approvedAt (a valid UTC timestamp ending Z) and source (GitHub URL). The producer must copy approvedAt from the verified authoritative event, never from its local clock. These fields are the local delivery contract, not a claimed GitHub response schema.

Deliver a fully written file by renaming a temporary sibling on the same filesystem. For an already verified envelope at a private path, this is the delivery operation, not acquisition:

```powershell
$verifiedEnvelopePath = Read-Host 'Private verified envelope file'
$destination = $env:LE_APPROVAL_TIME_EVIDENCE
if ([string]::IsNullOrWhiteSpace($destination)) { throw 'Delivery destination not configured.' }
if (Test-Path -LiteralPath $destination) { throw 'Destination already exists; investigate stale evidence.' }
$temporary = $destination + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
Copy-Item -LiteralPath $verifiedEnvelopePath -Destination $temporary -ErrorAction Stop
Move-Item -LiteralPath $temporary -Destination $destination -ErrorAction Stop
```

Once GitHub releases the protected job, Invoke-Handoff waits up to 120 seconds for delivery, checking every two seconds and bounding the final sleep. It rejects delivery at/after the deadline. JSON errors fail immediately. The parser compares repository/run/attempt/environment/reviewer with the workflow context and the single matching approved review. Missing or ambiguous history fails closed, including reruns whose review history cannot be uniquely resolved. The GitHub lookup has its own bounded request timeout; the 120-second limit applies to file delivery.

The private approval capture retains the review response, supplied envelope, workflow identity and separately labeled observation time. Promotion records include the attempt and envelope hash. These checks detect mismatches; trusted source acquisition and custody remain prerequisites. Neither GITHUB_ACTOR nor a workflow start time is approval evidence. Auto mode is a separate policy path and does not satisfy manual-approval acceptance.

## Alternative approval decision

The [pull-request review API](https://docs.github.com/en/rest/pulls/reviews)
provides a review's `submitted_at`, reviewer, state and `commit_id`. This can support
a separate, explicit approval decision over a committed acceptance request. It
does not establish the timestamp of an environment-button approval.

Such an integration must bind the reviewed commit to the repository, workflow run
and attempt, environment, exact validation manifest hash and execution commit.
It must verify reviewer authorization, reject dismissed or superseded decisions,
and retain the source API response. Keep the environment protection as an
additional gate. Approval-request PRs must never execute on the lab runner.
The current parser does not implement this alternative, and no actual decision
or correlated approval record has been acquired in the public setup pass.
