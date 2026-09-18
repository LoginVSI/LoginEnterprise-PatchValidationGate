function Get-LEGateRunSession {
    <# .SYNOPSIS
    Retrieves all documented user-sessions pages with strict completeness checks.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$TestRunId, [object]$ListProfile, [string]$CaptureRoot)
    Assert-LEGateIdentifier -Value $TestRunId
    return Get-LEGateResultList -Session $Session -Path ('/test-runs/{0}/user-sessions' -f $TestRunId) -Query @{ count = 100; direction = 'asc' } -ListProfile $ListProfile -CaptureRoot $CaptureRoot
}
