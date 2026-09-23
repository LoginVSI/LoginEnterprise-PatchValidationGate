function Get-LEGateApproval {
    <# .SYNOPSIS
    Reads actual reviewer identity; requires independent authoritative time evidence.
    #>
    [CmdletBinding()]
    param(
        [ValidatePattern('^\d+$')][string]$WorkflowRunId,
        [ValidateRange(1, 2147483647)][int]$WorkflowRunAttempt,
        [string]$Environment = 'promotion-approval',
        [object]$TimeEvidence, [string]$CapturePath,
        [string]$ExpectedManifestHash, [string]$ExecutionCommit
    )
    $reviews = @(Invoke-LEGateGitHubRequest -Method GET -Path ('/actions/runs/' + $WorkflowRunId + '/approvals'))
    if ($CapturePath) { Write-LEGateJson -Path $CapturePath -Value @{ reviews = $reviews; timeEvidence = $TimeEvidence; workflowRunId = $WorkflowRunId; workflowRunAttempt = $WorkflowRunAttempt; observedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow) } }
    if ($TimeEvidence -and $TimeEvidence.approvedAt -is [DateTime]) { $TimeEvidence.approvedAt = ConvertTo-LEGateTimestamp -Value $TimeEvidence.approvedAt }
    $matching = @($reviews | Where-Object { $_.state -eq 'approved' -and @($_.environments | Where-Object { $_.name -ceq $Environment }).Count -eq 1 })
    if ($matching.Count -ne 1) { throw 'Approval history is absent or ambiguous.' }
    $reviewer = $matching[0].user.login
    if ([string]::IsNullOrWhiteSpace($reviewer)) { throw 'Reviewer identity is unavailable.' }
    if ($TimeEvidence -and $TimeEvidence.kind -ceq 'github-pull-request-approval') {
        return Get-LEGatePullRequestApproval -WorkflowRunId $WorkflowRunId -WorkflowRunAttempt $WorkflowRunAttempt -Environment $Environment -Pointer $TimeEvidence -Reviewer $reviewer -EnvironmentReviews $reviews -ExpectedManifestHash $ExpectedManifestHash -ExecutionCommit $ExecutionCommit -CapturePath $CapturePath
    }
    # GitHub REST approval history documents no approval timestamp. Environment
    # created_at/updated_at are NOT approval times. Never substitute the initiator.
    if ($WorkflowRunAttempt -lt 1 -or $null -eq $TimeEvidence -or $TimeEvidence.kind -ne 'github-approval-time-evidence' -or
        $TimeEvidence.repository -cne $env:GITHUB_REPOSITORY -or $TimeEvidence.workflowRunId -cne $WorkflowRunId -or
        [string]$TimeEvidence.workflowRunAttempt -cne [string]$WorkflowRunAttempt -or
        $TimeEvidence.environment -cne $Environment -or $TimeEvidence.reviewer -cne $reviewer -or
        $TimeEvidence.approvedAt -notmatch '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{3})?Z$' -or
        $TimeEvidence.source -notmatch '^https://github\.com/') {
        throw 'Approval time provenance unavailable. Handoff is incomplete; do not substitute observation time.'
    }
    $parsedTime = [datetime]::MinValue
    if (-not [datetime]::TryParse($TimeEvidence.approvedAt, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind, [ref]$parsedTime)) { throw 'Invalid approval timestamp.' }
    return [pscustomobject]@{ approvedBy = $reviewer; approvedAt = $TimeEvidence.approvedAt; source = 'github-review-history'; workflowRunId = $WorkflowRunId; workflowRunAttempt = $WorkflowRunAttempt; environment = $Environment; timeEvidence = $TimeEvidence }
}
