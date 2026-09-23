function Stop-LEGateContinuousTest {
    <# .SYNOPSIS
    Disables an existing continuous test and separately verifies its sessions drain.
    .DESCRIPTION
    Sends the documented stop request once, confirms scheduling by readback, then
    polls session evidence within a bounded drain deadline. It never treats
    disabled scheduling alone as proof that the target can be changed.
    .PARAMETER Session
    Authenticated LE session.
    .PARAMETER Name
    Exact existing Continuous Test name.
    .PARAMETER MaxDrainMinutes
    Session-drain budget after the stop request, in minutes.
    .PARAMETER PollIntervalSeconds
    Interval between read-only drain observations.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)][object]$Session,
        [Parameter(Mandatory = $true)][string]$Name,
        [ValidateRange(1, 3600)][int]$MaxDrainMinutes = 15,
        [ValidateRange(1, 3600)][int]$PollIntervalSeconds = 15
    )
    $test = Resolve-LEGateContinuousTest -Session $Session -Name $Name
    Assert-LEGateIdentifier -Value $test.id
    if ($test.isEnabled -isnot [bool]) { throw 'Continuous scheduling status is unavailable.' }
    if (-not $PSCmdlet.ShouldProcess('existing continuous test', 'Disable scheduling and wait for sessions to drain')) { return }
    if ($test.isEnabled) { $null = Invoke-LEGateRequest -Session $Session -Method PUT -Path ('/tests/' + $test.id + '/stop') }
    $deadline = (Get-LEGateUtcNow).AddMinutes($MaxDrainMinutes)
    while ((Get-LEGateUtcNow) -lt $deadline) {
        $observed = Invoke-LEGateRequest -Session $Session -Method GET -Path ('/tests/' + $test.id) -Deadline $deadline
        if ($observed.id -cne $test.id -or $observed.isEnabled -isnot [bool] -or $observed.isEnabled) { throw 'Continuous scheduling disablement is not confirmed.' }
        $active = @(Get-LEGateAllPages -Session $Session -Path '/user-sessions/active' -Query @{ count = 100; direction = 'asc' } -Deadline $deadline)
        foreach ($item in $active) {
            if ($item.testId -isnot [string] -or [string]::IsNullOrWhiteSpace($item.testId)) { throw 'Active session test identity is unavailable.' }
        }
        if ((Get-LEGateUtcNow) -ge $deadline) { break }
        if (@($active | Where-Object { $_.testId -ceq $test.id }).Count -eq 0) {
            return [pscustomobject]@{ succeeded = $true; schedulingEnabled = $false; sessionsDrained = $true; testId = $test.id; observedAt = Get-LEGateTimestamp }
        }
        $remaining = [Math]::Max(0, ($deadline - (Get-LEGateUtcNow)).TotalMilliseconds)
        if ($remaining -gt 0) { Start-Sleep -Milliseconds ([int][Math]::Min($PollIntervalSeconds * 1000, $remaining)) }
    }
    throw 'Continuous sessions did not drain within the configured deadline; do not mutate the target.'
}
