Describe 'Functional gate and evidence boundaries' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $synthetic = Join-Path -Path $script:LEGateRepoRoot -ChildPath 'tests/synthetic'
        $ResponseMap = Get-Content (Join-Path -Path $synthetic -ChildPath 'response-profile.json') -Raw | ConvertFrom-Json
    }
    BeforeEach {
        $policy = Get-Content (Join-Path -Path $synthetic -ChildPath 'policy.json') -Raw | ConvertFrom-Json
        $capture = Get-Content (Join-Path -Path $synthetic -ChildPath 'pass.json') -Raw | ConvertFrom-Json
        $context = [pscustomobject]@{
            changeId = 'unit-change'; testRunId = 'synthetic-run'; testName = 'unit-test'; testId = 'test-1'
            policyName = 'unit-policy'; policyHash = 'sha256:' + ('a' * 64); promotionMode = 'manual'
            evaluatedAt = '2026-09-17T00:00:00.000Z'; provenance = 'synthetic'; apiVersion = 'v8-preview'
            applianceVersion = $null; policyPath = 'tests/synthetic/policy.json'; sourceCommit = $null
            changeManifestHash = $null; identityHash = $null; publication = $null
        }
    }
    It 'produces all synthetic outcomes through normalization and evaluation' {
        foreach ($scenario in @('pass', 'fail', 'inconclusive')) {
            $inputCapture = Get-Content (Join-Path -Path $synthetic -ChildPath ($scenario + '.json')) -Raw | ConvertFrom-Json
            $normalized = ConvertTo-LEGateResult -Capture $inputCapture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
            (Test-LEGatePolicy -Results $normalized -Policy $policy -Context $context).verdict | Should -Be $scenario.ToUpperInvariant()
        }
    }
    It 'is deterministic with fixed inputs' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        (Test-LEGatePolicy -Results $n -Policy $policy -Context $context | ConvertTo-Json -Depth 20) |
            Should -BeExactly (Test-LEGatePolicy -Results $n -Policy $policy -Context $context | ConvertTo-Json -Depth 20)
    }
    It 'makes every malformed event type inconclusive while retaining valid event handling' {
        $cases = @(@{ value = $null }, @{ value = '' }, @{ value = ' ' }, @{ value = @('launcherOffline') }, @{ value = @() }, @{ value = @{ name = 'launcherOffline' } }, @{ value = 1 }, @{ value = $true })
        foreach ($case in $cases) {
            $capture.events = @([pscustomobject]@{ type = $case.value })
            $normalized = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
            $normalized.complete | Should -BeFalse
            (Test-LEGatePolicy -Results $normalized -Policy $policy -Context $context).verdict | Should -Be 'INCONCLUSIVE'
        }
        $capture.events = @([pscustomobject]@{ type = 'testRunFinished' })
        $normalized = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        (Test-LEGatePolicy -Results $normalized -Policy $policy -Context $context).verdict | Should -Be 'PASS'
        $capture.events = @([pscustomobject]@{ type = 'launcherOffline' })
        $normalized = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        (Test-LEGatePolicy -Results $normalized -Policy $policy -Context $context).verdict | Should -Be 'INCONCLUSIVE'
    }
    It 'rejects wrong run IDs and execution relationships' {
        $capture.run.id = 'other'
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run').integrityValid | Should -BeFalse
        $capture.run.id = 'synthetic-run'
        $capture.executions[0].testRunId = 'other'
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run').integrityValid | Should -BeFalse
    }
    It 'does not pass zero equals zero or an empty overview' {
        $capture.executions = @()
        $capture.run.appFailureResults.successCount = 0
        $capture.run.appFailureResults.totalCount = 0
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        (Test-LEGatePolicy -Results $n -Policy $policy -Context $context).verdict | Should -Be 'INCONCLUSIVE'
        $capture.overview.applications = @()
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run').integrityValid | Should -BeFalse
    }
    It 'does not infer missing required coverage' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $policy.functional.requiredApplications += 'missing'
        (Test-LEGatePolicy -Results $n -Policy $policy -Context $context).verdict | Should -Be 'INCONCLUSIVE'
    }
    It 'fails positive evidence of nonexecution' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $n.applications[1].executions = 0
        $n.totalExecutions = 1
        $n.applications[1].successful = $false
        (Test-LEGatePolicy -Results $n -Policy $policy -Context $context).reasonCodes | Should -Contain 'application-not-executed'
    }
    It 'prioritizes infrastructure errors and timeouts' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $n.infrastructureFailure = $true; $n.timedOut = $true
        $v = Test-LEGatePolicy -Results $n -Policy $policy -Context $context
        $v.verdict | Should -Be 'INCONCLUSIVE'
        $v.reasonCodes | Should -Contain 'run-timeout'
    }
    It 'rejects unsupported retries, performance settings, and guardrails' {
        $policy.functional.allowStepRetries = 1
        (Test-LEGatePolicyDefinition -Policy $policy).valid | Should -BeFalse
        $policy.functional.allowStepRetries = 0; $policy.performance.enabled = $true
        (Test-LEGatePolicyDefinition -Policy $policy).valid | Should -BeFalse
        $policy.performance.enabled = $false; $policy.promotion.autoRequires += 'unknown'
        (Test-LEGatePolicyDefinition -Policy $policy).valid | Should -BeFalse
    }
    It 'rejects unconfigured apps and unknown policy settings' {
        $policy.functional.requiredApplications = @('CONFIGURE_APP')
        (Test-LEGatePolicyDefinition -Policy $policy).valid | Should -BeFalse
        $policy.functional.requiredApplications = @('notepad')
        $policy | Add-Member -NotePropertyName unknown -NotePropertyValue $true
        (Test-LEGatePolicyDefinition -Policy $policy).valid | Should -BeFalse
    }
    It 'rejects unsafe paths and identifiers' {
        InModuleScope LEGate {
            { Resolve-LEGatePath -Root 'C:\workspace' -RelativePath '../escape' } | Should -Throw
            { Resolve-LEGatePath -Root 'C:\workspace' -RelativePath 'C:\escape' } | Should -Throw
            { Assert-LEGateIdentifier -Value '../bad' } | Should -Throw
            { Assert-LEGateIdentifier -Value 'CON' } | Should -Throw
        }
    }
    It 'detects bundle tampering' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $v = Test-LEGatePolicy -Results $n -Policy $policy -Context $context
        $path = Join-Path -Path $TestDrive -ChildPath 'bundle'
        $bundle = Export-LEGateEvidence -Path $path -Verdict $v -Context $context -Results $n
        (Test-LEGateEvidence -Path $path -ExpectedManifestHash $bundle.manifestSha256).valid | Should -BeTrue
        Add-Content -LiteralPath (Join-Path -Path $path -ChildPath 'summary.md') -Value 'tampered'
        { Test-LEGateEvidence -Path $path } | Should -Throw '*integrity*'
    }
    It 'publishes no private free text and preserves the verdict' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $v = Test-LEGatePolicy -Results $n -Policy $policy -Context $context
        $v.testName = 'private-host.example.test'; $v.summary = 'secret-user Bearer private-token'
        $v.applications[0].id = 'private-app'
        $path = Join-Path -Path $TestDrive -ChildPath 'private'
        [IO.Directory]::CreateDirectory($path) | Out-Null
        Set-Content -LiteralPath (Join-Path -Path $path -ChildPath 'raw-secret.json') -Value 'private-token'
        $null = Export-LEGateEvidence -Path $path -Verdict $v -Context $context -Results $n
        $published = Join-Path -Path $TestDrive -ChildPath 'public'
        $null = Publish-LEGateEvidence -PrivatePath $path -OutputPath $published
        $text = (Get-ChildItem -LiteralPath $published -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join ''
        $text | Should -Not -Match 'private-host|private-token|secret-user|private-app'
        (Test-LEGateEvidence -Path $published).verdict.verdict | Should -Be 'PASS'
    }
    It 'parses explicit certificate flags' {
        ConvertTo-LEGateBoolean -Value 'true' | Should -BeTrue
        ConvertTo-LEGateBoolean -Value '1' | Should -BeTrue
        ConvertTo-LEGateBoolean -Value '' | Should -BeFalse
        { ConvertTo-LEGateBoolean -Value 'yes' } | Should -Throw
    }
    It 'never promotes synthetic evidence' {
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $ResponseMap -TestRunId 'synthetic-run'
        $v = Test-LEGatePolicy -Results $n -Policy $policy -Context $context
        $path = Join-Path -Path $TestDrive -ChildPath 'promotion'
        $bundle = Export-LEGateEvidence -Path $path -Verdict $v -Context $context -Results $n
        { Write-LEGatePromotionRecord -BundlePath $path -ExpectedManifestHash $bundle.manifestSha256 -BundleName 'synthetic-validation' -Policy $policy -Mode auto } | Should -Throw '*real-capture*'
    }
}
