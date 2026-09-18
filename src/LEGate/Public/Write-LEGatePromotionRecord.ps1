function Write-LEGatePromotionRecord {
    <# .SYNOPSIS
    Emits a simulated handoff only after verified PASS and approval.
    #>
    [CmdletBinding()]
    param(
        [string]$BundlePath, [string]$ExpectedManifestHash, [string]$BundleName,
        [object]$Policy, [ValidateSet('manual', 'auto')][string]$Mode,
        [object]$Approval, [string]$Timestamp, [string]$OutputPath, [switch]$Synthetic
    )
    if ($ExpectedManifestHash -notmatch '^[a-f0-9]{64}$') { throw 'An independently supplied manifest hash is required.' }
    if ($BundleName -notmatch '^[A-Za-z0-9_-]{1,100}$') { throw 'Invalid artifact name.' }
    $checked = Test-LEGateEvidence -Path $BundlePath -ExpectedManifestHash $ExpectedManifestHash
    $provenance = 'appliance-capture'
    if ($Synthetic) { $provenance = 'synthetic' }
    if ($checked.verdict.verdict -ne 'PASS' -or -not $checked.manifest.completeness -or
        $checked.manifest.provenance -ne $provenance) { throw 'Promotion requires complete real-capture PASS evidence, or an explicit synthetic simulation.' }
    if (-not (Test-LEGatePolicyDefinition -Policy $Policy).valid) { throw 'Unsupported promotion policy.' }
    if ($checked.verdict.promotionMode -ne $Mode) { throw 'Promotion mode differs from approved evidence.' }
    $approvalProjection = $null
    if ($Mode -eq 'manual') {
        if ($null -eq $Approval -or $Approval.source -ne 'github-review-history' -or
            $Approval.approvedBy -notmatch '^[A-Za-z0-9_-]{1,100}$' -or -not $Approval.approvedAt -or -not $Approval.timeEvidence) { throw 'Authoritative manual approval is required.' }
        $by = $Approval.approvedBy; $at = $Approval.approvedAt
        $approvalProjection = @{ source = 'github-review-history'; workflowRunId = $Approval.workflowRunId; environment = 'promotion-approval'; timeEvidenceSha256 = Get-LEGateTextHash -Text (ConvertTo-Json -InputObject $Approval.timeEvidence -Depth 20 -Compress) }
    }
    else { $by = 'policy'; $at = $Timestamp }
    if ($at -notmatch '^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d{3})?Z$') { throw 'Approval timestamp unavailable.' }
    $v = $checked.verdict
    $record = [pscustomobject][ordered]@{
        handoffVersion = '1'; changeId = $v.changeId; verdict = 'PASS'; promotionMode = $Mode
        approvedBy = $by; approvedAt = $at; testName = $v.testName; testRunId = $v.testRunId
        policyName = $v.policyName; policyHash = $v.policyHash
        evidence = @{ bundleName = $BundleName; manifestSha256 = $checked.manifestSha256 }
        summary = 'Simulated production promotion. No production deployment was performed.'
        simulated = $true; provenance = $provenance; approval = $approvalProjection
    }
    if (Test-Path -LiteralPath $OutputPath) { throw 'Promotion record destination already exists.' }
    Write-LEGateJson -Path $OutputPath -Value $record
    return $record
}
