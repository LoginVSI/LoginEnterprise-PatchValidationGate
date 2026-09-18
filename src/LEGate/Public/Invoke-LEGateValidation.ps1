function Invoke-LEGateValidation {
    <# .SYNOPSIS
    Runs the private validation lifecycle with durable identity and target recovery state.
    #>
    [CmdletBinding()]
    param(
        [string]$ChangeId, [string]$RepositoryRoot, [string]$PolicyFile, [string]$ChangeManifest,
        [string]$ResponseProfile, [ValidateSet('app-update', 'break', 'noop')][string]$Adapter,
        [string]$Target, [string]$ContinuousTestName, [string]$StateRoot, [string]$EvidenceRoot,
        [ValidateSet('manual', 'auto')][string]$PromotionMode = 'manual',
        [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local,
        [switch]$Resume, [switch]$Revert, [switch]$RecoveryConfirmed,
        [switch]$ReportIssue, [string]$BaselineRunId, [switch]$Synthetic, [string]$SourceCommit = $env:GITHUB_SHA
    )
    Assert-LEGateIdentifier -Value $ChangeId
    $folder = Resolve-LEGatePath -Root $EvidenceRoot -RelativePath ($ChangeId + '/' + [guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($folder) | Out-Null
    $context = [pscustomobject]@{
        changeId = $ChangeId; testName = $null; testId = $null; testRunId = $null
        policyName = $null; policyHash = $null; policyPath = $PolicyFile; promotionMode = $PromotionMode
        evaluatedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
        provenance = 'unavailable'; apiVersion = 'v8-preview'; applianceVersion = $null
        sourceCommit = $SourceCommit; changeManifestHash = $null; identityHash = $null; publication = $null
    }
    $policy = $null; $results = $null; $lock = $null; $state = $null; $session = $null
    $adapterResults = [ordered]@{ apply = $null; verify = $null }
    $issue = $null; $reportingSucceeded = -not $ReportIssue; $restoration = $null
    $stage = 'preflight'
    Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'context.json') -Value $context
    try {
        $policyPath = Resolve-LEGatePath -Root $RepositoryRoot -RelativePath $PolicyFile
        $manifestPath = Resolve-LEGatePath -Root $RepositoryRoot -RelativePath $ChangeManifest
        $profilePath = Resolve-LEGatePath -Root $RepositoryRoot -RelativePath $ResponseProfile
        $policy = Get-Content -LiteralPath $policyPath -Raw | ConvertFrom-Json
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $ResponseMap = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
        $context.policyHash = 'sha256:' + (Get-LEGateHash -Path $policyPath)
        $context.changeManifestHash = 'sha256:' + (Get-LEGateHash -Path $manifestPath)
        $context.testName = $policy.test.name; $context.policyName = $policy.name
        if (-not (Test-LEGatePolicyDefinition -Policy $policy).valid) { throw 'Policy invalid.' }
        $null = Test-LEGateChangeManifest -Manifest $manifest -Adapter $Adapter
        if ((-not $Synthetic -and ($ResponseMap.provenance -ne 'capture-confirmed' -or [string]::IsNullOrWhiteSpace($ResponseMap.confirmedFrom))) -or ($Synthetic -and ($ResponseMap.provenance -ne 'synthetic' -or $env:LE_BASE_URL -ne 'https://synthetic.invalid'))) { throw 'Live response profile is not capture-confirmed. Capture and configure it first.' }
        $lock = Enter-LEGateTarget -StateRoot $StateRoot -Target $Target
        $session = Connect-LEGate
        $context.apiVersion = $session.ApiVersion
        $session | Add-Member -NotePropertyName Synthetic -NotePropertyValue ([bool]$Synthetic)
        $context.applianceVersion = (Get-LEGateVersion -Session $session).currentVersion
        $test = Resolve-LEGateTest -Session $session -Name $policy.test.name
        $context.testId = $test.id
        if ($Synthetic) { $context.provenance = 'synthetic' }
        $identity = @{ changeId = $ChangeId; testId = $test.id; target = $Target.ToLowerInvariant(); policyHash = $context.policyHash; changeManifestHash = $context.changeManifestHash; adapter = $Adapter; profileHash = Get-LEGateHash -Path $profilePath }
        $context.identityHash = Get-LEGateTextHash -Text (ConvertTo-Json -InputObject ([ordered]@{ changeId = $identity.changeId; testId = $identity.testId; target = $identity.target; policyHash = $identity.policyHash; changeManifestHash = $identity.changeManifestHash; adapter = $identity.adapter; profileHash = $identity.profileHash; promotionMode = $PromotionMode }) -Compress)
        if (Test-Path -LiteralPath $lock.leasePath) {
            $state = Get-Content -LiteralPath $lock.leasePath -Raw | ConvertFrom-Json
            if ($state.identityHash -cne $context.identityHash -and $state.stage -ne 'reverted') { throw 'Target has an unrestored change. Recover it before another change.' }
            if ($state.identityHash -ceq $context.identityHash) {
                if (-not $Resume -and -not $Revert) { throw 'Existing identity requires explicit Resume or Revert.' }
                if ($state.stage -eq 'reverted') { throw 'Restored changes cannot be replayed. Use a fresh change ID.' }
            }
            else { $state = $null }
        }
        elseif ($Resume -or $Revert) { throw 'No durable identity exists to resume or revert.' }
        $continuous = Resolve-LEGateContinuousTest -Session $session -Name $ContinuousTestName
        if ($continuous.state -ne 'enabled') { throw 'Stop shared-target continuous testing in LE and wait for enabled state.' }
        $adapterArgs = @{ Adapter = $Adapter; ChangeId = $ChangeId; Target = $Target; Parameters = $manifest; UseCurrentCredentials = $UseCurrentCredentials; Local = $Local }
        if ($Credential) { $adapterArgs.Credential = $Credential }
        if ($Revert) {
            if ($test.state -ne 'enabled') { throw 'Application test is still using the target.' }
            if ($state.stage -in @('applying', 'starting', 'reverting', 'recovery-required') -and -not $RecoveryConfirmed) { throw 'Uncertain target state requires explicit operator recovery confirmation.' }
            if ($state.runId) {
                $run = Invoke-LEGateRequest -Session $session -Method GET -Path ('/test-runs/' + $state.runId)
                if ($run.id -cne $state.runId -or $run.state -ne 'completed') { throw 'Run is not confirmed completed.' }
            }
            # Invalidate reusable validation before any target mutation, including a crash.
            $state.stage = 'reverting'
            Write-LEGateJson -Path $lock.leasePath -Value $state
            try {
                $restoration = Invoke-LEGateChangeAdapter @adapterArgs -Operation revert
                Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'restoration.json') -Value $restoration
                if ($restoration.status -notin @('succeeded', 'skipped')) { throw 'Restoration failed.' }
                $state.stage = 'reverted'
                Write-LEGateJson -Path $lock.leasePath -Value $state
            }
            catch {
                $state.stage = 'recovery-required'
                Write-LEGateJson -Path $lock.leasePath -Value $state
                throw
            }
            $restoreExitCode = 0
            if ($ReportIssue -and $state.issueNumber) {
                try { Add-LEGateChangeComment -IssueNumber $state.issueNumber -Stage restoration -Outcome succeeded }
                catch {
                    $restoreExitCode = 2
                    Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'reporting-error.json') -Value @{ code = 'restoration-reporting-failed'; restored = $true }
                }
            }
            return [pscustomobject]@{ restored = $true; privatePath = $folder; exitCode = $restoreExitCode }
        }
        if ($ReportIssue) {
            $issue = New-LEGateChangeIssue -IdentityHash $context.identityHash
            Add-LEGateChangeComment -IssueNumber $issue.number -Stage preflight -Outcome started
        }
        if (-not $state) {
            if ($test.state -ne 'enabled') { throw 'Application test must be enabled and idle.' }
            $existing = @(Get-LEGateAllPages -Session $session -Path ('/tests/' + $test.id + '/test-runs') -Query @{ count = 20; orderBy = 'created'; direction = 'desc' } | Where-Object { $_.testRunName -ceq $ChangeId })
            if ($existing.Count) { throw 'A named run exists without matching durable identity. Use a fresh change ID.' }
            $state = [pscustomobject]@{ identityHash = $context.identityHash; identity = $identity; stage = 'applying'; runId = $null; issueNumber = $issue.number }
            Write-LEGateJson -Path $lock.leasePath -Value $state
            $adapterResults.apply = Invoke-LEGateChangeAdapter @adapterArgs -Operation apply
            Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'adapter-apply.json') -Value $adapterResults.apply
            if ($adapterResults.apply.status -notin @('succeeded', 'skipped')) { throw 'Adapter apply failed.' }
            if ($ReportIssue) { Add-LEGateChangeComment -IssueNumber $issue.number -Stage adapter-apply -Outcome succeeded }
            $adapterResults.verify = Invoke-LEGateChangeAdapter @adapterArgs -Operation verify
            Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'adapter-verify.json') -Value $adapterResults.verify
            if ($adapterResults.verify.status -notin @('succeeded', 'skipped')) { throw 'Adapter verification failed.' }
            if ($ReportIssue) { Add-LEGateChangeComment -IssueNumber $issue.number -Stage adapter-verify -Outcome succeeded }
            $state | Add-Member -NotePropertyName apply -NotePropertyValue $adapterResults.apply -Force
            $state | Add-Member -NotePropertyName verify -NotePropertyValue $adapterResults.verify -Force
            $state.stage = 'starting'
            Write-LEGateJson -Path $lock.leasePath -Value $state
            $started = Invoke-LEGateRequest -Session $session -Method PUT -Path ('/tests/' + $test.id + '/start') -Body @{ testRunName = $ChangeId; comment = 'identityHash=' + $context.identityHash }
            Assert-LEGateIdentifier -Value ([string]$started.id)
            $state.runId = $started.id; $state.stage = 'running'
            Write-LEGateJson -Path $lock.leasePath -Value $state
        }
        elseif (-not $state.runId -or $state.stage -notin @('running', 'validated')) { throw 'Mutation or start was interrupted. Explicit recovery is required, not reapplication.' }
        else {
            $adapterResults.apply = $state.apply
            $adapterResults.verify = $state.verify
        }
        $context.testRunId = $state.runId
        $run = Invoke-LEGateRequest -Session $session -Method GET -Path ('/test-runs/' + $state.runId)
        if ($run.id -cne $state.runId -or $run.testRunName -cne $ChangeId) { throw 'Persisted run identity mismatch.' }
        $stage = 'poll'
        $waited = Wait-LEGateRun -Session $session -TestRunId $state.runId -ChangeId $ChangeId -EvidenceRoot (Join-Path -Path $folder -ChildPath 'poll') -PollIntervalSeconds $policy.execution.pollIntervalSeconds -MaxWaitMinutes $policy.execution.maxWaitMinutes
        $stage = 'retrieve'
        $capture = Export-LEGateRunResult -Session $session -TestRunId $state.runId -ResponseMap $ResponseMap -OutputPath (Join-Path -Path $folder -ChildPath 'raw') -BaselineRunId $BaselineRunId
        $context.provenance = 'appliance-capture'
        if ($Synthetic) { $context.provenance = 'synthetic' }
        $results = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId $state.runId -TimedOut:$waited.timedOut
        if (-not $waited.timedOut -and $capture.run.state -eq 'completed') { $state.stage = 'validated'; Write-LEGateJson -Path $lock.leasePath -Value $state }
    }
    catch {
        Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'orchestration-error.json') -Value @{ stage = $stage; code = 'operation-failed'; recoveryRequired = ($null -ne $state); message = Hide-LEGateSecret -Text $_.Exception.Message }
        if (-not $results) { $results = [pscustomobject]@{ complete = $false; integrityValid = $false; preflightFailed = ($stage -eq 'preflight'); runId = $context.testRunId; applications = @() } }
    }
    finally { if ($lock) { $lock.stream.Dispose() } }
    $context.evaluatedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
    $verdict = Test-LEGatePolicy -Results $results -Policy $policy -Context $context
    if ($ReportIssue -and $issue) {
        try { Add-LEGateChangeComment -IssueNumber $issue.number -Stage validation -Outcome $verdict.verdict; $reportingSucceeded = $true }
        catch { Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'reporting-error.json') -Value @{ code = 'issue-reporting-failed' } }
    }
    Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'context.json') -Value $context
    $bundle = Export-LEGateEvidence -Path $folder -Verdict $verdict -Context $context -Results $results -Adapter $adapterResults
    $exitCode = 2
    if ($verdict.verdict -eq 'PASS' -and $reportingSucceeded) { $exitCode = 0 }
    elseif ($verdict.verdict -eq 'FAIL') { $exitCode = 1 }
    return [pscustomobject]@{ verdict = $verdict.verdict; privatePath = $folder; manifestSha256 = $bundle.manifestSha256; issueNumber = $issue.number; exitCode = $exitCode; reportingSucceeded = $reportingSucceeded }
}
