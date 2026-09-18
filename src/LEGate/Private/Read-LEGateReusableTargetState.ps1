function Read-LEGateReusableTargetState {
    <# .SYNOPSIS
    Checks reusable validation while the caller holds the target lock.
    #>
    [CmdletBinding()]
    param([string]$LeasePath, [string]$IdentityHash)
    if ($IdentityHash -notmatch '^[a-f0-9]{64}$') { throw 'Validation identity missing or invalid.' }
    if (-not (Test-Path -LiteralPath $LeasePath)) { throw 'Target identity record missing.' }
    $state = Get-Content -LiteralPath $LeasePath -Raw | ConvertFrom-Json
    if ($state.identityHash -cne $IdentityHash -or $state.stage -notin @('validated', 'continuous-running')) { throw 'Target was restored, changed or requires recovery after validation.' }
    return $state
}
