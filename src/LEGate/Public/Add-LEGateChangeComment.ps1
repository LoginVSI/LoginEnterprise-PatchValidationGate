function Add-LEGateChangeComment {
    <# .SYNOPSIS
    Posts only allowlisted stage/outcome text and a validated GitHub evidence link.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateRange(1, 2147483647)][int]$IssueNumber,
        [ValidateSet('preflight', 'adapter-apply', 'adapter-verify', 'validation', 'promotion', 'continuous', 'restoration', 'evidence')][string]$Stage,
        [ValidateSet('started', 'succeeded', 'failed', 'PASS', 'FAIL', 'INCONCLUSIVE', 'incomplete')][string]$Outcome,
        [string]$EvidenceUrl
    )
    $body = 'Stage: ' + $Stage + '. Outcome: ' + $Outcome + '. Production promotion is simulated.'
    if (-not $EvidenceUrl -and $env:GITHUB_ACTIONS -eq 'true' -and $env:GITHUB_RUN_ID -match '^\d+$') {
        $EvidenceUrl = 'https://github.com/' + $env:GITHUB_REPOSITORY + '/actions/runs/' + $env:GITHUB_RUN_ID
    }
    if ($EvidenceUrl) {
        if ($EvidenceUrl -notmatch '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/actions/runs/\d+(/artifacts/\d+)?$') { throw 'Invalid evidence URL.' }
        $body += ' Sanitized evidence: ' + $EvidenceUrl
    }
    if ($PSCmdlet.ShouldProcess('change issue', 'Add stage comment')) {
        Invoke-LEGateGitHubRequest -Method POST -Path ('/issues/' + $IssueNumber + '/comments') -Body @{ body = $body } | Out-Null
    }
}
