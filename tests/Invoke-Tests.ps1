<#
.SYNOPSIS
    Runs the Pester tests.
.DESCRIPTION
    Runs tests/unit by default. Those need no appliance and no network. With
    -Integration the tests/integration suite runs as well; it skips itself when
    LE_BASE_URL and LE_API_TOKEN are not set.

    Results are written as NUnit XML to tests/results so CI can publish them.
    The script exits non-zero when any test fails.
.PARAMETER Integration
    Also run tests/integration.
.PARAMETER IntegrationOnly
    Run only tests/integration.
.PARAMETER Output
    Pester output verbosity. Default Detailed.
.EXAMPLE
    .\tests\Invoke-Tests.ps1
.EXAMPLE
    .\tests\Invoke-Tests.ps1 -Integration
#>
[CmdletBinding()]
param(
    [switch]$Integration,
    [switch]$IntegrationOnly,
    [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
    [string]$Output = 'Detailed'
)

$ErrorActionPreference = 'Stop'

Import-Module -Name Pester -MinimumVersion 5.0.0 -ErrorAction Stop

$root = $PSScriptRoot
$paths = @()
if (-not $IntegrationOnly) { $paths += Join-Path -Path $root -ChildPath 'unit' }
if ($Integration -or $IntegrationOnly) { $paths += Join-Path -Path $root -ChildPath 'integration' }

$resultsFolder = Join-Path -Path $root -ChildPath 'results'
if (-not (Test-Path -Path $resultsFolder)) { New-Item -ItemType Directory -Path $resultsFolder | Out-Null }

$config = New-PesterConfiguration
$config.Run.Path = $paths
$config.Run.Exit = $false
$config.Run.PassThru = $true
$config.Output.Verbosity = $Output
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path -Path $resultsFolder -ChildPath 'pester.xml'

$result = Invoke-Pester -Configuration $config

if ($null -eq $result) {
    Write-Error 'Pester returned no result.'
    exit 1
}

if ($result.FailedCount -gt 0) {
    Write-Error ('{0} test(s) failed.' -f $result.FailedCount)
    exit 1
}

exit 0
