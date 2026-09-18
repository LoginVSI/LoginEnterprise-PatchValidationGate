function Get-LEGateRunOverview {
    <# .SYNOPSIS
    Reads the documented overview and optional appliance comparison.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$Session, [Parameter(Mandatory = $true)][string]$TestRunId, [string]$BaselineRunId)
    Assert-LEGateIdentifier -Value $TestRunId
    $query = @{}
    $baseRun = $TestRunId
    if ($BaselineRunId) { Assert-LEGateIdentifier -Value $BaselineRunId; $baseRun = $BaselineRunId; $query.testRunIds = $TestRunId }
    return Invoke-LEGateRequest -Session $Session -Method GET -Path ('/application-test-run-overview/' + $baseRun) -Query $query
}
