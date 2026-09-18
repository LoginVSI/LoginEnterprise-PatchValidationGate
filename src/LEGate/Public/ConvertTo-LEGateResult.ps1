function ConvertTo-LEGateResult {
    <# .SYNOPSIS
    Normalizes captured responses through explicit selectors into gate-owned fields.
    #>
    [CmdletBinding()]
    param([object]$Capture, [object]$ResponseMap, [string]$TestRunId, [switch]$TimedOut)
    $normalized = [ordered]@{
        schemaVersion = '1'; runId = $TestRunId; state = $null; result = $null
        complete = $false; integrityValid = $false; timedOut = [bool]$TimedOut
        infrastructureFailure = $false; loginSuccessful = $null; totalExecutions = 0
        applications = @(); errors = @(); provenance = $Capture.provenance
    }
    try {
        if (-not $Capture.complete -or $null -eq $ResponseMap) { throw 'Incomplete capture.' }
        $run = $Capture.run
        if ($run.id -cne $TestRunId) { throw 'Wrong run ID.' }
        $normalized.state = $run.state
        $normalized.result = $run.result
        $login = Get-LEGateField -Value $Capture.overview -Selector $ResponseMap.selectors.overviewLogin
        if ($login -isnot [bool]) { throw 'Invalid login result.' }
        $normalized.loginSuccessful = $login
        $rows = Get-LEGateField -Value $Capture.overview -Selector $ResponseMap.selectors.overviewApplications
        if ($rows -isnot [array] -or $rows.Count -eq 0) { throw 'Empty overview.' }
        $sessions = @{}
        foreach ($s in @($Capture.sessions)) {
            $id = [string](Get-LEGateField -Value $s -Selector $ResponseMap.selectors.sessionId)
            if ([string]::IsNullOrWhiteSpace($id) -or $sessions.ContainsKey($id) -or
                (Get-LEGateField -Value $s -Selector $ResponseMap.selectors.sessionRunId) -cne $TestRunId) { throw 'Session relationship mismatch.' }
            $sessions[$id] = $s
            if ($s.loginState -ne 'succeeded') { $normalized.infrastructureFailure = $true }
        }
        if ($sessions.Count -eq 0) { throw 'No sessions.' }
        $byApp = @{}
        $executions = @{}
        foreach ($e in @($Capture.executions)) {
            $id = [string](Get-LEGateField -Value $e -Selector $ResponseMap.selectors.executionId)
            $app = [string](Get-LEGateField -Value $e -Selector $ResponseMap.selectors.executionAppId)
            $sid = [string](Get-LEGateField -Value $e -Selector $ResponseMap.selectors.executionSessionId)
            if (-not $id -or -not $app -or $executions.ContainsKey($id) -or -not $sessions.ContainsKey($sid) -or
                (Get-LEGateField -Value $e -Selector $ResponseMap.selectors.executionRunId) -cne $TestRunId -or
                $e.state -notin @('ended', 'endedWithErrors')) { throw 'Invalid execution evidence.' }
            $executions[$id] = $true
            if (-not $byApp.ContainsKey($app)) { $byApp[$app] = @{ count = 0; failures = 0 } }
            $byApp[$app].count++
            if ($e.state -eq 'endedWithErrors') { $byApp[$app].failures++ }
        }
        if ($executions.Count -eq 0) { throw 'No executions.' }
        $normalized.totalExecutions = $executions.Count
        if ($null -eq $run.appFailureResults -or [string]$run.appFailureResults.totalCount -notmatch '^\d+$' -or
            [string]$run.appFailureResults.successCount -notmatch '^\d+$' -or
            $run.appFailureResults.totalCount -ne $executions.Count) { throw 'Run counts do not match executions.' }
        $failures = 0
        foreach ($value in $byApp.Values) { $failures += $value.failures }
        if ($run.appFailureResults.successCount -ne ($executions.Count - $failures)) { throw 'Run success count mismatch.' }
        $apps = New-Object Collections.ArrayList
        $seen = @{}
        foreach ($row in $rows) {
            $id = [string](Get-LEGateField -Value $row -Selector $ResponseMap.selectors.overviewAppId)
            if (-not $id -or $seen.ContainsKey($id) -or $row.appExecutionSuccessful -isnot [bool]) { throw 'Malformed application overview.' }
            $seen[$id] = $true
            $count = 0; $failed = 0
            if ($byApp.ContainsKey($id)) { $count = $byApp[$id].count; $failed = $byApp[$id].failures }
            if ($row.appExecutionSuccessful -and ($count -eq 0 -or $failed -gt 0)) { throw 'Overview contradicts executions.' }
            [void]$apps.Add([pscustomobject]@{ id = $id; successful = $row.appExecutionSuccessful; executions = $count; failures = $failed })
        }
        foreach ($id in $byApp.Keys) { if (-not $seen.ContainsKey($id)) { throw 'Execution missing from overview.' } }
        foreach ($evidenceEvent in @($Capture.events)) {
            $type = Get-LEGateField -Value $evidenceEvent -Selector $ResponseMap.selectors.eventType
            if ($type -isnot [string] -or [string]::IsNullOrWhiteSpace($type)) { throw 'Malformed event type.' }
            if ($type -in @('launcherOffline', 'connectionInitializationTimeout', 'loginFailure', 'sessionFailure')) { $normalized.infrastructureFailure = $true }
        }
        $normalized.applications = @($apps.ToArray())
        $normalized.complete = $true
        $normalized.integrityValid = $true
    }
    catch { $normalized.errors = @('response-normalization-failed') }
    return [pscustomobject]$normalized
}
