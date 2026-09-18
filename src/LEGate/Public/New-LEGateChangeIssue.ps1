function New-LEGateChangeIssue {
    <# .SYNOPSIS
    Opens or reuses a change issue identified by an opaque full identity digest.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([ValidatePattern('^[a-f0-9]{64}$')][string]$IdentityHash)
    $title = '[LEGate] ' + $IdentityHash
    for ($page = 1; $page -le 100; $page++) {
        $issues = @(Invoke-LEGateGitHubRequest -Method GET -Path ('/issues?state=all&per_page=100&page=' + $page))
        $exactMatches = @($issues | Where-Object { $_.title -ceq $title -and -not $_.pull_request })
        if ($exactMatches.Count -gt 1) { throw 'Ambiguous change issue.' }
        if ($exactMatches.Count -eq 1) {
            if ($exactMatches[0].state -ne 'open') { throw 'Change issue is closed. Use a fresh change identity.' }
            return $exactMatches[0]
        }
        if ($issues.Count -lt 100) {
            if ($PSCmdlet.ShouldProcess('reference change issue', 'Create')) {
                return Invoke-LEGateGitHubRequest -Method POST -Path '/issues' -Body @{ title = $title; body = 'Lab functional validation. Production promotion is simulated. Raw evidence remains private.' }
            }
            return
        }
    }
    throw 'Issue pagination limit reached.'
}
