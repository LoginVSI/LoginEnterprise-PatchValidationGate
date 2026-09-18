function Invoke-LEGateContinuousHandoff {
    <# .SYNOPSIS
    Starts continuous testing while holding the same durable target lock as validation.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$Name, [string]$StateRoot, [string]$Target, [string]$IdentityHash)
    $lock = Enter-LEGateTarget -StateRoot $StateRoot -Target $Target
    try {
        $state = Read-LEGateReusableTargetState -LeasePath $lock.leasePath -IdentityHash $IdentityHash
        $result = Start-LEGateContinuousTest -Session $Session -Name $Name
        if (-not $result.succeeded) { throw 'Continuous start did not succeed.' }
        $state.stage = 'continuous-running'
        Write-LEGateJson -Path $lock.leasePath -Value $state
        return $result
    }
    finally { $lock.stream.Dispose() }
}
