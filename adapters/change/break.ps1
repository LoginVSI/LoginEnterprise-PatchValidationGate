<# .SYNOPSIS
Contract entrypoint for the break lab adapter.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('apply', 'verify', 'revert')][string]$Operation,
    [Parameter(Mandatory = $true)][string]$ChangeId,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Parameters,
    [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../src/LEGate/LEGate.psd1') -Force
try {
    $splat = @{ Adapter = 'break'; Operation = $Operation; ChangeId = $ChangeId; Target = $Target; Parameters = (ConvertFrom-Json -InputObject $Parameters); UseCurrentCredentials = $UseCurrentCredentials; Local = $Local }
    if ($Credential) { $splat.Credential = $Credential }
    $result = Invoke-LEGateChangeAdapter @splat
    ConvertTo-Json -InputObject $result -Depth 20 -Compress
    exit 0
}
catch { Write-Error 'Adapter could not produce a valid result.'; exit 2 }
