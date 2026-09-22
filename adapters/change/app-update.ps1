<# .SYNOPSIS
Contract entrypoint for the app-update lab adapter.
.DESCRIPTION
Calls the adapter with explicit target remoting settings for all operations.
.PARAMETER TargetTransport
HTTP (compatibility default) or HTTPS with normal certificate validation.
.PARAMETER TargetPort
Target WSMan port; defaults to 5985 for HTTP or 5986 for HTTPS.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet('apply', 'verify', 'revert')][string]$Operation,
    [Parameter(Mandatory = $true)][string]$ChangeId,
    [Parameter(Mandatory = $true)][string]$Target,
    [Parameter(Mandatory = $true)][string]$Parameters,
    [ValidateSet('HTTP', 'HTTPS')][string]$TargetTransport = 'HTTP',
    [ValidateRange(1, 65535)][int]$TargetPort = $(if ($TargetTransport -eq 'HTTPS') { 5986 } else { 5985 }),
    [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../../src/LEGate/LEGate.psd1') -Force
try {
    $splat = @{ Adapter = 'app-update'; Operation = $Operation; ChangeId = $ChangeId; Target = $Target; Parameters = (ConvertFrom-Json -InputObject $Parameters); UseCurrentCredentials = $UseCurrentCredentials; Local = $Local; TargetTransport = $TargetTransport; TargetPort = $TargetPort }
    if ($Credential) { $splat.Credential = $Credential }
    $result = Invoke-LEGateChangeAdapter @splat
    ConvertTo-Json -InputObject $result -Depth 20 -Compress
    exit 0
}
catch { Write-Error 'Adapter could not produce a valid result.'; exit 2 }
