function Test-LEGatePolicy {
    <# .SYNOPSIS
    Pure functional evaluator. Normalized evidence, policy, and explicit context in.
    #>
    [CmdletBinding()]
    param(
        [AllowNull()][object]$Results,
        [AllowNull()][object]$Policy,
        [Parameter(Mandatory = $true)][object]$Context
    )
    $codes = New-Object Collections.Generic.List[string]
    $apps = New-Object Collections.ArrayList
    $status = 'INCONCLUSIVE'
    $definition = Test-LEGatePolicyDefinition -Policy $Policy
    if (-not $definition.valid) { $codes.Add('policy-invalid') }
    elseif ($null -eq $Results) { $codes.Add('results-incomplete') }
    else {
        if ($Results.timedOut -eq $true) { $codes.Add('run-timeout') }
        if ($Results.infrastructureFailure -eq $true -or $Results.loginSuccessful -eq $false) { $codes.Add('launcher-or-connection-error') }
        if ($Results.complete -isnot [bool] -or -not $Results.complete -or $Results.integrityValid -isnot [bool] -or -not $Results.integrityValid -or
            $Results.loginSuccessful -isnot [bool] -or $Results.runId -cne $Context.testRunId -or
            [string]::IsNullOrWhiteSpace($Results.runId) -or $Results.state -ne 'completed' -or
            $Results.result -ne 'successful' -or @($Results.applications).Count -eq 0 -or
            $Results.applications -isnot [array] -or [string]$Results.totalExecutions -notmatch '^[1-9][0-9]*$' -or
            $Results.timedOut -isnot [bool] -or $Results.infrastructureFailure -isnot [bool]) { $codes.Add('results-incomplete') }
        if ($Results.preflightFailed -eq $true) { $codes.Add('preflight-failed') }
        $seen = @{}
        $executionCount = 0
        foreach ($app in @($Results.applications)) {
            if ($null -eq $app -or [string]::IsNullOrWhiteSpace($app.id) -or $seen.ContainsKey([string]$app.id)) { $codes.Add('results-incomplete'); continue }
            $seen[[string]$app.id] = $app
            $countValue = 0L; $failureValue = 0L
            if ($app.successful -isnot [bool] -or [string]$app.executions -notmatch '^\d+$' -or
                [string]$app.failures -notmatch '^\d+$' -or
                -not [long]::TryParse([string]$app.executions, [ref]$countValue) -or
                -not [long]::TryParse([string]$app.failures, [ref]$failureValue) -or
                $failureValue -gt $countValue) { $codes.Add('results-incomplete') }
            else { $executionCount += $countValue }
        }
        if ($executionCount -ne $Results.totalExecutions) { $codes.Add('results-incomplete') }
        if ($codes.Count -eq 0) {
            foreach ($required in $Policy.functional.requiredApplications) {
                if (-not $seen.ContainsKey($required)) {
                    # No row is not proof of nonexecution. A complete row with zero is.
                    $codes.Add('results-incomplete')
                    continue
                }
                $app = $seen[$required]
                $appStatus = 'PASS'
                if ($app.executions -eq 0) { $appStatus = 'FAIL'; $codes.Add('application-not-executed') }
                elseif (-not $app.successful -or $app.failures -gt 0) { $appStatus = 'FAIL'; $codes.Add('application-failed') }
                [void]$apps.Add([pscustomobject]@{ id = $required; verdict = $appStatus; executions = $app.executions; failures = $app.failures })
            }
            if ($codes.Contains('results-incomplete')) { $status = 'INCONCLUSIVE' }
            elseif ($codes.Count) { $status = 'FAIL' }
            else { $status = 'PASS' }
        }
    }
    $summary = 'Functional validation is inconclusive; inspect private diagnostics.'
    if ($status -eq 'PASS') { $summary = 'All explicitly required applications passed with complete functional evidence.' }
    if ($status -eq 'FAIL') { $summary = 'Complete evidence establishes an application failure or nonexecution.' }
    return [pscustomobject][ordered]@{
        verdict = $status; reasonCodes = @($codes.ToArray() | Select-Object -Unique)
        changeId = $Context.changeId; testName = $Context.testName; testRunId = $Context.testRunId
        policyName = $Context.policyName; policyHash = $Context.policyHash
        promotionMode = $Context.promotionMode; evaluatedAt = $Context.evaluatedAt
        summary = $summary; applications = @($apps.ToArray())
    }
}
