function Test-LEGatePolicyDefinition {
    <# .SYNOPSIS
    Validates the supported functional policy without JSON Schema dependencies.
    #>
    [CmdletBinding()]
    param([AllowNull()][object]$Policy)
    $errors = New-Object Collections.Generic.List[string]
    if ($null -eq $Policy) { return [pscustomobject]@{ valid = $false; errors = @('policy-missing') } }
    $shapes = @{
        '$' = @('policyVersion', 'name', 'test', 'execution', 'functional', 'performance', 'promotion', 'inconclusiveWhen')
        test = @('name')
        execution = @('maxWaitMinutes', 'pollIntervalSeconds')
        functional = @('requiredApplications', 'allowStepRetries', 'failOnAnyApplicationFailure')
        performance = @('enabled')
        promotion = @('defaultMode', 'autoRequires')
    }
    foreach ($section in $shapes.Keys) {
        $obj = $Policy
        if ($section -ne '$') { $obj = $Policy.$section }
        if ($null -eq $obj) { $errors.Add('missing-section'); continue }
        foreach ($prop in $obj.PSObject.Properties.Name) {
            if ($prop -notin $shapes[$section]) { $errors.Add('unsupported-setting') }
        }
        foreach ($prop in $shapes[$section]) {
            if ($null -eq $obj.PSObject.Properties[$prop]) { $errors.Add('missing-setting') }
        }
    }
    if ($Policy.policyVersion -ne '1' -or [string]::IsNullOrWhiteSpace($Policy.name)) { $errors.Add('invalid-version-or-name') }
    if ([string]::IsNullOrWhiteSpace($Policy.test.name) -or $Policy.test.name -match 'REPLACE|CONFIGURE|<') { $errors.Add('test-not-configured') }
    foreach ($name in @('maxWaitMinutes', 'pollIntervalSeconds')) {
        $value = $Policy.execution.$name
        $parsed = 0
        if ($null -eq $value -or [string]$value -notmatch '^\d+$' -or -not [int]::TryParse([string]$value, [ref]$parsed) -or $parsed -lt 1 -or $parsed -gt 3600) { $errors.Add('invalid-execution-limit') }
    }
    $apps = @($Policy.functional.requiredApplications)
    if ($Policy.functional.requiredApplications -isnot [array] -or $apps.Count -lt 1 -or @($apps | Select-Object -Unique).Count -ne $apps.Count) { $errors.Add('invalid-required-applications') }
    foreach ($app in $apps) {
        if ($app -isnot [string] -or [string]::IsNullOrWhiteSpace($app) -or $app -match 'REPLACE|CONFIGURE|<') { $errors.Add('application-not-configured') }
    }
    if ($Policy.functional.allowStepRetries -is [bool] -or [string]$Policy.functional.allowStepRetries -cne '0') { $errors.Add('retries-unsupported') }
    if ($Policy.functional.failOnAnyApplicationFailure -isnot [bool] -or -not $Policy.functional.failOnAnyApplicationFailure) { $errors.Add('failure-suppression-unsupported') }
    if ($Policy.performance.enabled -isnot [bool] -or $Policy.performance.enabled) { $errors.Add('performance-policy-unsupported') }
    if ($Policy.promotion.defaultMode -notin @('manual', 'auto')) { $errors.Add('invalid-promotion-mode') }
    $guards = @($Policy.promotion.autoRequires)
    if ($Policy.promotion.autoRequires -isnot [array] -or $guards.Count -ne 2 -or
        @($guards | Where-Object { $_ -notin @('verdict:PASS', 'results-complete') }).Count -or
        @($guards | Select-Object -Unique).Count -ne 2) { $errors.Add('unsupported-auto-guardrails') }
    $codes = @(Get-LEGateReasonCodes)
    if (($Policy.inconclusiveWhen -join ',') -ne ($codes -join ',')) { $errors.Add('invalid-inconclusive-codes') }
    return [pscustomobject]@{ valid = $errors.Count -eq 0; errors = @($errors.ToArray() | Select-Object -Unique) }
}
