function Get-LEGateRunMeasurement {
    <# .SYNOPSIS
    Retrieves all documented measurements pages with strict completeness checks.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$TestRunId, [object]$ListProfile, [string]$CaptureRoot)
    Assert-LEGateIdentifier -Value $TestRunId
    return Get-LEGateResultList -Session $Session -Path ('/test-runs/{0}/measurements' -f $TestRunId) -Query @{ count = 1000; direction = 'asc'; include = 'all' } -ListProfile $ListProfile -CaptureRoot $CaptureRoot
}
