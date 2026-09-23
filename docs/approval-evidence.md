# Approval-time evidence prerequisite

The environment-button timestamp remains unavailable through the reviewed APIs.
An additional supported path now reads a separate pull-request approval decision
directly from GitHub. Its timestamp means review submission, not environment
approval. Live acceptance of that path is still pending. The legacy envelope path
still requires an independently verified authoritative producer.

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
The parser now implements this alternative. No actual correlated decision has
yet been acquired in live Actions acceptance.

### Prepare the decision

After validation publishes a real PASS, create a data-only PR in the execution
repository. Keep it open and do not merge it. The branch must belong to that same
repository, target `main`, and contain `.acceptance/approval-request.json`:

```json
{
  "kind": "legate-promotion-approval-request",
  "repository": "owner/execution-repository",
  "workflowRunId": "123",
  "workflowRunAttempt": 1,
  "environment": "promotion-approval",
  "executionCommit": "FULL_40_CHARACTER_EXECUTION_SHA",
  "validationManifestSha256": "EXACT_64_CHARACTER_VALIDATION_MANIFEST_HASH",
  "decision": "approve-simulated-promotion"
}
```

These are placeholders, not evidence. Copy the execution commit and attempt from
the actual workflow and the manifest hash from its independently recorded output.
The reviewer must inspect the sanitized bundle and request. They must have write,
maintain or admin permission and be distinct from the PR author. Do not create a
nominal second identity to approve your own request. An authorized collaborator
or separately authorized service can author the request; the human reviewer
performs the approval. Authoring permission is an external prerequisite when only
one account has write access.

Have the human approve the PR at its exact head commit, then approve the protected
`promotion-approval` environment with the same GitHub identity. Before releasing
the environment, atomically deliver this pointer at the private path configured
by `LE_APPROVAL_TIME_EVIDENCE`:

```json
{
  "kind": "github-pull-request-approval",
  "pullRequestNumber": 7,
  "requestCommit": "FULL_40_CHARACTER_REVIEWED_REQUEST_SHA"
}
```

The pointer supplies no trusted time or reviewer. The consumer reads the committed
request through the contents API at that SHA, verifies the workflow attempt through
the Actions API, pages PR reviews, and reads current reviewer permissions. It
requires the latest review by the environment reviewer to be APPROVED at the same
commit. Dismissed decisions, subsequent comments or change requests, changed PR
heads, foreign branches, closed/draft PRs and incomplete history fail closed.
It retains source responses privately and records `submitted_at` as the approval
decision time. The record labels its source `github-pull-request-review` and
timestamp meaning `pull-request-review-submitted`. The environment timestamp is
not inferred. Permissions need contents, actions and pull-requests read plus the
metadata access used by the collaborator-permission endpoint.

Use a fresh request and pointer for each run attempt. This protocol reads PR data;
it never checks out or executes the PR branch. Keep execution-copy PR workflows
disabled and retain the protected environment. Test the real permission and
review/dismissal behavior before calling the complete flow accepted.
