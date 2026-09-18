function Close-LEGateChangeIssue {
    <# .SYNOPSIS
    Closes the issue only when the caller supplies successful continuous handoff.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([ValidateRange(1, 2147483647)][int]$IssueNumber, [Parameter(Mandatory = $true)][object]$Handoff)
    if ($Handoff.succeeded -ne $true) { throw 'Cannot close issue before successful continuous handoff.' }
    if ($PSCmdlet.ShouldProcess('change issue', 'Close')) {
        Invoke-LEGateGitHubRequest -Method PATCH -Path ('/issues/' + $IssueNumber) -Body @{ state = 'closed' } | Out-Null
    }
}
