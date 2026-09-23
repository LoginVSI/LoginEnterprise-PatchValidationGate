function Get-LEGatePullRequestApproval {
    <# .SYNOPSIS
    Verifies a GitHub PR review of an immutable, run-bound promotion request.
    .DESCRIPTION
    Reads data only. The review submission time is a separate approval decision,
    never the time of the protected environment button. No PR code is executed.
    #>
    [CmdletBinding()]
    param(
        [string]$WorkflowRunId, [int]$WorkflowRunAttempt, [string]$Environment,
        [object]$Pointer, [string]$Reviewer, [object[]]$EnvironmentReviews,
        [string]$ExpectedManifestHash, [string]$ExecutionCommit, [string]$CapturePath
    )
    if ([string]$Pointer.pullRequestNumber -notmatch '^[1-9][0-9]{0,9}$' -or
        $Pointer.requestCommit -cnotmatch '^[a-f0-9]{40}$' -or
        $ExpectedManifestHash -cnotmatch '^[a-f0-9]{64}$' -or $ExecutionCommit -cnotmatch '^[a-f0-9]{40}$' -or
        $Reviewer -notmatch '^[A-Za-z0-9_-]{1,100}$' -or -not $CapturePath) { throw 'Approval request context is incomplete.' }
    $path = '/pulls/' + $Pointer.pullRequestNumber
    $pr = Invoke-LEGateGitHubRequest -Method GET -Path $path
    if ([string]$pr.number -cne [string]$Pointer.pullRequestNumber -or $pr.state -cne 'open' -or
        $pr.draft -isnot [bool] -or $pr.draft -or $pr.head.sha -cne $Pointer.requestCommit -or
        $pr.head.repo.full_name -cne $env:GITHUB_REPOSITORY -or $pr.base.repo.full_name -cne $env:GITHUB_REPOSITORY -or
        $pr.base.ref -cne 'main' -or [string]::IsNullOrWhiteSpace($pr.user.login) -or $pr.user.login -ieq $Reviewer) {
        throw 'Approval request must be an open same-repository PR at the reviewed commit, with a distinct author.'
    }
    $content = Invoke-LEGateGitHubRequest -Method GET -Path ('/contents/.acceptance/approval-request.json?ref=' + $Pointer.requestCommit)
    if ($content.type -cne 'file' -or $content.path -cne '.acceptance/approval-request.json' -or
        $content.encoding -cne 'base64' -or $content.content.Length -gt 32768) { throw 'Approval request content is invalid.' }
    $request = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($content.content)) | ConvertFrom-Json
    if ($request.kind -cne 'legate-promotion-approval-request' -or $request.repository -cne $env:GITHUB_REPOSITORY -or
        [string]$request.workflowRunId -cne $WorkflowRunId -or [string]$request.workflowRunAttempt -cne [string]$WorkflowRunAttempt -or
        $request.environment -cne $Environment -or $request.executionCommit -cne $ExecutionCommit -or
        $request.validationManifestSha256 -cne $ExpectedManifestHash -or $request.decision -cne 'approve-simulated-promotion') {
        throw 'Committed approval request does not match this validation and workflow attempt.'
    }
    $run = Invoke-LEGateGitHubRequest -Method GET -Path ('/actions/runs/' + $WorkflowRunId + '/attempts/' + $WorkflowRunAttempt)
    if ([string]$run.id -cne $WorkflowRunId -or [string]$run.run_attempt -cne [string]$WorkflowRunAttempt -or
        $run.head_sha -cne $ExecutionCommit -or $run.head_branch -cne 'main' -or $run.event -cne 'workflow_dispatch' -or
        $run.path -cne '.github/workflows/validate-patch.yml' -or $run.repository.full_name -cne $env:GITHUB_REPOSITORY) {
        throw 'GitHub workflow attempt does not match the trusted execution context.'
    }
    $reviews = @()
    $complete = $false
    for ($page = 1; $page -le 10; $page++) {
        $batch = @(Invoke-LEGateGitHubRequest -Method GET -Path ($path + '/reviews?per_page=100&page=' + $page))
        if ($batch.Count -gt 100) { throw 'Approval review page is invalid.' }
        $reviews += $batch
        if ($batch.Count -lt 100) { $complete = $true; break }
    }
    if (-not $complete -or @($reviews | Where-Object { [string]$_.id -notmatch '^[1-9][0-9]*$' }).Count -gt 0 -or
        @($reviews | Group-Object id | Where-Object Count -GT 1).Count -gt 0) { throw 'Approval review history is incomplete.' }
    # GitHub documents chronological order. Any later review by this reviewer,
    # including a comment, requires an explicit fresh approval in this protocol.
    $decisions = @($reviews | Where-Object { $_.user.login -ceq $Reviewer })
    if ($decisions.Count -eq 0) { throw 'No decision by the environment reviewer.' }
    $decision = $decisions[-1]
    if ($decision.state -cne 'APPROVED' -or $decision.commit_id -cne $Pointer.requestCommit -or $decision.user.type -cne 'User' -or
        $decision.html_url -cne ('https://github.com/' + $env:GITHUB_REPOSITORY + $path + '#pullrequestreview-' + $decision.id).Replace('/pulls/', '/pull/')) {
        throw 'Latest reviewer decision is not an approval of the exact request commit.'
    }
    $permission = Invoke-LEGateGitHubRequest -Method GET -Path ('/collaborators/' + $Reviewer + '/permission')
    if ($permission.user.login -cne $Reviewer -or $permission.permission -notin @('write', 'maintain', 'admin')) { throw 'Approval reviewer lacks repository write permission.' }
    $at = $decision.submitted_at
    if ($at -is [datetime]) { $at = ConvertTo-LEGateTimestamp -Value $at }
    $start = $run.run_started_at
    if ($start -is [datetime]) { $start = ConvertTo-LEGateTimestamp -Value $start }
    $approved = [datetime]::MinValue; $started = [datetime]::MinValue
    if ($at -notmatch '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{3})?Z$' -or
        $start -notmatch '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{3})?Z$' -or
        -not [datetime]::TryParse($at, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$approved) -or
        -not [datetime]::TryParse($start, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$started) -or
        $approved -lt $started -or $approved -gt (Get-LEGateUtcNow)) { throw 'Approval submission timestamp is invalid for this attempt.' }
    $evidence = [pscustomobject]@{
        kind = 'github-pull-request-review-evidence'; repository = $env:GITHUB_REPOSITORY
        workflowRunId = $WorkflowRunId; workflowRunAttempt = $WorkflowRunAttempt; environment = $Environment
        reviewer = $Reviewer; approvedAt = $at; source = $decision.html_url; reviewId = $decision.id
        pullRequestNumber = $pr.number; requestCommit = $Pointer.requestCommit
        executionCommit = $ExecutionCommit; validationManifestSha256 = $ExpectedManifestHash
        timestampMeaning = 'pull-request-review-submitted'; environmentApprovalTime = $null
    }
    Write-LEGateJson -Path $CapturePath -Value @{
        environmentReviews = $EnvironmentReviews; pullRequest = $pr; content = $content; request = $request
        workflowAttempt = $run; reviews = $reviews; decisionReview = $decision; reviewerPermission = $permission
        evidence = $evidence; observedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
    }
    return [pscustomobject]@{ approvedBy = $Reviewer; approvedAt = $at; source = 'github-pull-request-review'; workflowRunId = $WorkflowRunId; workflowRunAttempt = $WorkflowRunAttempt; environment = $Environment; timeEvidence = $evidence }
}
