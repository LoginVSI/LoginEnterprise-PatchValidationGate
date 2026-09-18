function Publish-LEGateEvidence {
    <# .SYNOPSIS
    Creates an allowlisted publication projection. Never copies raw text or pixels.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$PrivatePath, [string]$OutputPath)
    $checked = Test-LEGateEvidence -Path $PrivatePath
    if (Test-Path -LiteralPath $OutputPath) { throw 'Publication destination must be new.' }
    if (-not $PSCmdlet.ShouldProcess('sanitized evidence directory', 'Create publication projection')) { return }
    $v = $checked.verdict
    $m = $checked.manifest
    if ($v.evaluatedAt -is [DateTime]) { $v.evaluatedAt = ConvertTo-LEGateTimestamp -Value $v.evaluatedAt }
    $allowed = @(Get-LEGateReasonCodes) + @(Get-LEGateReasonCodes -IncludeFailures)
    foreach ($code in $v.reasonCodes) { if ($code -notin $allowed) { throw 'Unknown reason code cannot be published.' } }
    if ($m.provenance -notin @('synthetic', 'appliance-capture', 'unavailable')) { throw 'Unknown provenance.' }
    foreach ($hash in @($m.policy.hash, $m.changeManifestHash, $m.identityHash)) {
        if ($hash -and $hash -notmatch '^(sha256:)?[a-f0-9]{64}$') { throw 'Invalid provenance hash.' }
    }
    $published = [pscustomobject][ordered]@{
        verdict = $v.verdict; reasonCodes = @($v.reasonCodes)
        changeId = 'change-' + (Get-LEGateTextHash -Text $v.changeId).Substring(0, 16)
        testName = 'application-test'; testRunId = $null; policyName = 'functional-policy'
        policyHash = $v.policyHash; promotionMode = $v.promotionMode
        evaluatedAt = $v.evaluatedAt; summary = 'See the recorded verdict and reason codes. Raw responses and unreviewed screenshots remain private.'
        applications = @()
    }
    if ($v.testRunId) { $published.testRunId = 'run-' + (Get-LEGateTextHash -Text $v.testRunId).Substring(0, 16) }
    if ($v.promotionMode -notin @('manual', 'auto') -or $v.evaluatedAt -notmatch '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$') { throw 'Invalid publication metadata.' }
    foreach ($app in @($v.applications)) {
        if ($app.verdict -notin @('PASS', 'FAIL') -or [string]$app.executions -notmatch '^\d+$' -or [string]$app.failures -notmatch '^\d+$') { throw 'Invalid app projection.' }
        $published.applications += [pscustomobject]@{ id = 'app-' + (Get-LEGateTextHash -Text $app.id).Substring(0, 12); verdict = $app.verdict; executions = $app.executions; failures = $app.failures }
    }
    $context = [pscustomobject]@{
        evaluatedAt = $published.evaluatedAt; apiVersion = $null; applianceVersion = $null; testId = $null
        policyPath = $null; provenance = $m.provenance; sourceCommit = $null
        changeManifestHash = $m.changeManifestHash; identityHash = $m.identityHash
        publication = @{ mode = 'allowlist'; privateManifestSha256 = $checked.manifestSha256; screenshots = 'omitted-unreviewed'; rawResponses = 'private' }
    }
    $result = [pscustomobject]@{ state = $null; result = $null; complete = [bool]$m.completeness; integrityValid = $true }
    return Export-LEGateEvidence -Path $OutputPath -Verdict $published -Context $context -Results $result
}
