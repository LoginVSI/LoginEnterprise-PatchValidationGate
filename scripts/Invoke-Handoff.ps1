<# .SYNOPSIS
Consumes an immutable publication bundle for simulated promotion or continuous handoff.
#>
[CmdletBinding()]
param(
    [ValidateSet('promote', 'continuous')][string]$Stage,
    [string]$BundlePath, [string]$ExpectedManifestHash, [string]$BundleName,
    [ValidateSet('manual', 'auto')][string]$Mode,
    [string]$PolicyFile, [string]$OutputPath,
    [string]$WorkflowRunId = $env:GITHUB_RUN_ID,
    [string]$WorkflowRunAttempt = $env:GITHUB_RUN_ATTEMPT,
    [string]$ApprovalTimeEvidencePath = $env:LE_APPROVAL_TIME_EVIDENCE,
    [string]$PromotionRecordPath, [string]$ExpectedPromotionHash, [int]$IssueNumber,
    [string]$ContinuousTestName = 'patch-gate-continuous',
    [string]$StateRoot = $env:LE_STATE_ROOT, [string]$Target = $env:LE_TARGET
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '../src/LEGate/LEGate.psd1') -Force
[IO.Directory]::CreateDirectory($OutputPath) | Out-Null
try {
    $checked = Test-LEGateEvidence -Path $BundlePath -ExpectedManifestHash $ExpectedManifestHash
    if ($IssueNumber -lt 1) { throw 'Issue record missing.' }
    if ($Stage -eq 'promote') {
        $configuration = Read-LEGatePolicy -RepositoryRoot (Split-Path -Path $PSScriptRoot -Parent) -RelativePath $PolicyFile
        $policy = $configuration.policy
        $hash = $configuration.hash
        if ($hash -cne $checked.verdict.policyHash) { throw 'Policy bytes differ from validation.' }
        $approval = $null
        if ($Mode -eq 'manual') {
            if (-not $env:LE_PRIVATE_ROOT) { throw 'Private approval capture root is required.' }
            if ($WorkflowRunAttempt -notmatch '^[1-9][0-9]*$') { throw 'Workflow run attempt is required.' }
            $time = Wait-LEGateApprovalEvidence -Path $ApprovalTimeEvidencePath
            $approval = Get-LEGateApproval -WorkflowRunId $WorkflowRunId -WorkflowRunAttempt ([int]$WorkflowRunAttempt) -TimeEvidence $time -CapturePath (Join-Path $env:LE_PRIVATE_ROOT ('approval-' + [guid]::NewGuid().ToString('N') + '.json'))
        }
        $record = Write-LEGatePromotionRecord -BundlePath $BundlePath -ExpectedManifestHash $ExpectedManifestHash -BundleName $BundleName -Policy $policy -Mode $Mode -Approval $approval -Timestamp (Get-LEGateTimestamp) -OutputPath (Join-Path -Path $OutputPath -ChildPath 'promotion-record.json') -StateRoot $StateRoot -Target $Target
        Add-LEGateChangeComment -IssueNumber $IssueNumber -Stage promotion -Outcome succeeded
        if ($env:GITHUB_OUTPUT) { ('promotion_hash=' + (Get-FileHash -LiteralPath (Join-Path -Path $OutputPath -ChildPath 'promotion-record.json') -Algorithm SHA256).Hash.ToLowerInvariant()) | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
        $record | Out-Null
    }
    else {
        if ($ExpectedPromotionHash -notmatch '^[a-f0-9]{64}$' -or (Get-FileHash -LiteralPath $PromotionRecordPath -Algorithm SHA256).Hash.ToLowerInvariant() -cne $ExpectedPromotionHash) { throw 'Promotion record hash mismatch.' }
        $promotion = Get-Content -LiteralPath $PromotionRecordPath -Raw | ConvertFrom-Json
        if ($checked.verdict.verdict -ne 'PASS' -or $promotion.verdict -ne 'PASS' -or $promotion.simulated -ne $true -or
            $promotion.evidence.manifestSha256 -cne $checked.manifestSha256 -or $promotion.changeId -cne $checked.verdict.changeId) { throw 'Promotion does not match approved validation.' }
        $session = Connect-LEGate
        $handoff = Invoke-LEGateContinuousHandoff -Session $session -Name $ContinuousTestName -StateRoot $StateRoot -Target $Target -IdentityHash $checked.manifest.identityHash
        $public = @{ succeeded = $handoff.succeeded; alreadyRunning = $handoff.alreadyRunning; simulatedProduction = $true; validationManifestSha256 = $checked.manifestSha256; recordedAt = Get-LEGateTimestamp }
        [IO.File]::WriteAllText((Join-Path -Path $OutputPath -ChildPath 'continuous-record.json'), (ConvertTo-Json -InputObject $public -Depth 10), (New-Object Text.UTF8Encoding($false)))
        Add-LEGateChangeComment -IssueNumber $IssueNumber -Stage continuous -Outcome succeeded
        Close-LEGateChangeIssue -IssueNumber $IssueNumber -Handoff $handoff
    }
    Write-Output 'Reference handoff completed. Production promotion is simulated.'
}
catch {
    $diagnostic = @{ stage = $Stage; outcome = 'incomplete'; validationManifestSha256 = $ExpectedManifestHash; recordedAt = Get-LEGateTimestamp }
    [IO.File]::WriteAllText((Join-Path -Path $OutputPath -ChildPath 'handoff-error.json'), (ConvertTo-Json -InputObject $diagnostic), (New-Object Text.UTF8Encoding($false)))
    try { Add-LEGateChangeComment -IssueNumber $IssueNumber -Stage $Stage.Replace('promote', 'promotion') -Outcome incomplete } catch { Write-Output 'Issue reporting also failed.' }
    Write-Output 'Handoff incomplete. Validation verdict remains unchanged.'
    exit 2
}
