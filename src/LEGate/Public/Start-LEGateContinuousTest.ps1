function Start-LEGateContinuousTest {
    <# .SYNOPSIS
    Starts an existing continuous schedule and verifies enabled status by readback.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Session, [string]$Name)
    $test = Resolve-LEGateContinuousTest -Session $Session -Name $Name
    Assert-LEGateIdentifier -Value $test.id
    if ($test.isEnabled -isnot [bool]) { throw 'Continuous scheduling status is unavailable.' }
    if ($test.isEnabled) { return [pscustomobject]@{ succeeded = $true; alreadyRunning = $true; schedulingEnabled = $true; testId = $test.id } }
    if (-not $PSCmdlet.ShouldProcess('existing continuous test', 'Start')) { return }
    $started = Invoke-LEGateRequest -Session $Session -Method PUT -Path ('/tests/' + $test.id + '/start') -Body @{}
    Assert-LEGateIdentifier -Value ([string]$started.id)
    $observed = Invoke-LEGateRequest -Session $Session -Method GET -Path ('/tests/' + $test.id)
    if ($observed.id -cne $test.id -or $observed.isEnabled -isnot [bool] -or -not $observed.isEnabled) { throw 'Continuous scheduling enablement was not confirmed. Investigate before retrying.' }
    return [pscustomobject]@{ succeeded = $true; alreadyRunning = $false; schedulingEnabled = $true; testId = $test.id; testRunId = $started.id }
}
