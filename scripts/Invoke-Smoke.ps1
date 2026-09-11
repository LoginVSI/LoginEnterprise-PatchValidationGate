<#
.SYNOPSIS
    Proves the module works against a real appliance.
.DESCRIPTION
    Imports the module, connects with LE_BASE_URL and LE_API_TOKEN, and prints the
    appliance version. That alone is a useful check of URL, token, and API version.

    With -TestName and -ChangeId it goes further: resolves the application test by
    exact name, starts a run tagged with the change id (or picks up the existing run
    for that change id), waits for it to complete, and prints state, result, and
    appFailureResults. The raw run is written to evidence/{changeId}/run.json.

    Exit codes:
      0  everything worked and, if a run was waited on, it completed with result successful
      1  an error was thrown (connection, resolution, start, or API failure)
      2  the run did not complete inside -MaxWaitMinutes
      3  the run completed with a result other than successful
.PARAMETER TestName
    Exact application test name. Requires -ChangeId.
.PARAMETER ChangeId
    Change identifier used as testRunName and as the evidence folder name.
.PARAMETER Comment
    Run comment. Defaults to the policy hash when -PolicyPath is given.
.PARAMETER PolicyPath
    Policy file whose hash becomes the run comment. Default policies/default.policy.json.
.PARAMETER ApiVersion
    Public API version. Default v8-preview.
.PARAMETER PollIntervalSeconds
    Seconds between run polls. Default 30.
.PARAMETER MaxWaitMinutes
    Wait budget for the run. Default 45.
.PARAMETER SkipCertificateCheck
    Trust the appliance certificate without validation. Lab use only.
.EXAMPLE
    .\scripts\Invoke-Smoke.ps1
.EXAMPLE
    .\scripts\Invoke-Smoke.ps1 -TestName 'Patch Gate - Office' -ChangeId 'CHG-2026-0911-01'
#>
[CmdletBinding()]
param(
    [string]$TestName,
    [string]$ChangeId,
    [string]$Comment,
    [string]$PolicyPath,
    [string]$ApiVersion = 'v8-preview',
    [ValidateRange(1, 3600)]
    [int]$PollIntervalSeconds = 30,
    [ValidateRange(1, 1440)]
    [int]$MaxWaitMinutes = 45,
    [switch]$SkipCertificateCheck
)

$ErrorActionPreference = 'Stop'

if (($TestName -and -not $ChangeId) -or ($ChangeId -and -not $TestName)) {
    Write-Error 'Pass -TestName and -ChangeId together, or neither.'
    exit 1
}

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
if (-not $PolicyPath) { $PolicyPath = Join-Path -Path $repoRoot -ChildPath 'policies\default.policy.json' }
$evidenceRoot = Join-Path -Path $repoRoot -ChildPath 'evidence'

try {
    Import-Module -Name (Join-Path -Path $repoRoot -ChildPath 'src\LEGate\LEGate.psd1') -Force

    Write-Output ('LEGate smoke check  {0}' -f [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))
    Write-Output ('PowerShell {0}' -f $PSVersionTable.PSVersion)

    $session = Connect-LEGate -ApiVersion $ApiVersion -SkipCertificateCheck:$SkipCertificateCheck
    Write-Output ('Base URL     : {0}' -f $session.BaseUrl)
    Write-Output ('API version  : {0}' -f $session.ApiVersion)

    $version = Get-LEGateVersion -Session $session
    Write-Output ('Appliance    : current {0}, latest {1}' -f $version.currentVersion, $version.latestVersion)

    if (-not $TestName) {
        Write-Output 'Version call succeeded. Pass -TestName and -ChangeId to start and wait for a run.'
        exit 0
    }

    $test = Resolve-LEGateTest -Session $session -Name $TestName
    Write-Output ('Test         : {0} (id {1}, state {2})' -f $test.name, $test.id, $test.state)

    $startParams = @{ Session = $session; TestId = $test.id; ChangeId = $ChangeId }
    if ($Comment) { $startParams['Comment'] = $Comment }
    elseif (Test-Path -Path $PolicyPath) { $startParams['PolicyPath'] = $PolicyPath }

    $runId = Start-LEGateRun @startParams
    Write-Output ('Run id       : {0}' -f $runId)

    $run = Wait-LEGateRun -Session $session -TestRunId $runId -ChangeId $ChangeId -PollIntervalSeconds $PollIntervalSeconds -MaxWaitMinutes $MaxWaitMinutes -EvidenceRoot $evidenceRoot

    Write-Output ''
    Write-Output ('State        : {0}' -f $run.state)
    Write-Output ('Result       : {0}' -f $run.result)
    if ($run.appFailureResults) {
        Write-Output ('App failures : {0} of {1} executions succeeded' -f $run.appFailureResults.successCount, $run.appFailureResults.totalCount)
    }
    else {
        Write-Output 'App failures : not reported on this run'
    }
    Write-Output ('Waited       : {0} seconds' -f $run.waitedSeconds)
    Write-Output ('Evidence     : {0}' -f (Join-Path -Path $evidenceRoot -ChildPath ($ChangeId + '\run.json')))

    if ($run.timedOut) {
        Write-Output ('Run did not complete inside {0} minutes. This is INCONCLUSIVE territory, not a failure of the patch.' -f $MaxWaitMinutes)
        exit 2
    }
    if ($run.result -ne 'successful') {
        Write-Output ('Run completed with result {0}.' -f $run.result)
        exit 3
    }

    Write-Output 'Run completed successfully.'
    exit 0
}
catch {
    Write-Output ('Smoke check failed: {0}' -f $_.Exception.Message)
    exit 1
}
