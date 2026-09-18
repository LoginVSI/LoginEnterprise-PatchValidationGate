function Start-LEGateContinuousTest {
    <# .SYNOPSIS
    Starts an enabled existing continuous test, or records it already running.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([object]$Session, [string]$Name)
    $test = Resolve-LEGateContinuousTest -Session $Session -Name $Name
    Assert-LEGateIdentifier -Value $test.id
    if ($test.state -eq 'running') { return [pscustomobject]@{ succeeded = $true; alreadyRunning = $true; testId = $test.id } }
    if ($test.state -ne 'enabled') { throw 'Continuous test must be enabled and stopped.' }
    if (-not $PSCmdlet.ShouldProcess('existing continuous test', 'Start')) { return }
    Invoke-LEGateRequest -Session $Session -Method PUT -Path ('/tests/' + $test.id + '/start') -Body @{} | Out-Null
    return [pscustomobject]@{ succeeded = $true; alreadyRunning = $false; testId = $test.id }
}
