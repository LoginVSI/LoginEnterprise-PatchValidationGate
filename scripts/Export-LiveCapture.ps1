<# .SYNOPSIS
Captures a supplied real run privately without starting a test or publishing data.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TestRunId,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [string]$ResponseProfile, [string]$BaselineRunId
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../src/LEGate/LEGate.psd1') -Force
try {
    if (Test-Path -LiteralPath $OutputPath) { throw 'Capture output must be new.' }
    $ResponseMap = $null
    if ($ResponseProfile) { $ResponseMap = Get-Content -LiteralPath $ResponseProfile -Raw | ConvertFrom-Json }
    $session = Connect-LEGate
    $capture = Export-LEGateRunResult -Session $session -TestRunId $TestRunId -ResponseMap $ResponseMap -OutputPath $OutputPath -BaselineRunId $BaselineRunId
    if (-not $capture.complete) { Write-Output 'Partial private capture retained. Review response-profile assumptions before retrying.'; exit 2 }
    Write-Output 'Private appliance capture complete. It has not been sanitized or published.'
    exit 0
}
catch { Write-Output 'Capture failed. Inspect private partial files, if any. No test was started.'; exit 2 }
