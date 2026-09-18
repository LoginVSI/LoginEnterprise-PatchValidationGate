<# .SYNOPSIS
Runs clearly synthetic scenarios through normalization, evaluation and evidence export.
#>
[CmdletBinding()]
param([string]$OutputRoot)
$ErrorActionPreference = 'Stop'
if (-not $OutputRoot) { $OutputRoot = Join-Path -Path $PSScriptRoot -ChildPath '../.private/offline' }
$root = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path -Path $root -ChildPath 'src/LEGate/LEGate.psd1') -Force
$policyPath = Join-Path -Path $root -ChildPath 'tests/synthetic/policy.json'
$policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
$ResponseMap = Get-Content -LiteralPath (Join-Path -Path $root -ChildPath 'tests/synthetic/response-profile.json') -Raw | ConvertFrom-Json
foreach ($scenario in @('pass', 'fail', 'inconclusive')) {
    $capture = Get-Content -LiteralPath (Join-Path -Path $root -ChildPath ('tests/synthetic/' + $scenario + '.json')) -Raw | ConvertFrom-Json
    $results = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
    $context = [pscustomobject]@{
        changeId = 'synthetic-' + $scenario; testName = 'patch-gate-app'; testId = 'synthetic-test'; testRunId = 'synthetic-run'
        policyName = $policy.name; policyHash = 'sha256:' + (Get-FileHash -LiteralPath $policyPath -Algorithm SHA256).Hash.ToLowerInvariant()
        policyPath = 'tests/synthetic/policy.json'; promotionMode = 'manual'; evaluatedAt = '2026-09-17T00:00:00.000Z'
        provenance = 'synthetic'; apiVersion = 'v8-preview'; applianceVersion = $null; sourceCommit = $null
        changeManifestHash = $null; identityHash = $null; publication = $null
    }
    $verdict = Test-LEGatePolicy -Results $results -Policy $policy -Context $context
    if ($verdict.verdict -cne $scenario.ToUpperInvariant()) { throw 'Synthetic scenario produced an unexpected verdict.' }
    $folder = Join-Path -Path $OutputRoot -ChildPath $scenario
    $exported = Export-LEGateEvidence -Path $folder -Verdict $verdict -Context $context -Results $results
    $null = Test-LEGateEvidence -Path $folder -ExpectedManifestHash $exported.manifestSha256
    Write-Output ('SYNTHETIC, not live: {0}; bundle verified.' -f $verdict.verdict)
}
