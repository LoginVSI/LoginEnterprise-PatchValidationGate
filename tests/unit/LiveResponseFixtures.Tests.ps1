Describe 'Sanitized genuine appliance response mappings' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $responseProfile = Get-Content (Join-Path $root 'config/response-profile.example.json') -Raw | ConvertFrom-Json
    }
    It 'evaluates the genuine restored-baseline response as PASS' {
        $capture = Get-Content (Join-Path $root 'tests/fixtures/sanitized-live/restored-success.json') -Raw | ConvertFrom-Json
        $policy = Get-Content (Join-Path $root 'policies/default.policy.json') -Raw | ConvertFrom-Json
        $policy.functional.requiredApplications = @($capture.overview.applicationTestResult[0].applicationSummaries.applicationId)
        $policy.test.name = 'application-acceptance'
        $result = ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId $capture.run.id
        $result.complete | Should -BeTrue
        $context = [pscustomobject]@{ changeId = 'captured-restoration-success'; testName = $policy.test.name; testRunId = $capture.run.id; policyName = $policy.name; policyHash = 'fixture-review'; promotionMode = 'manual'; evaluatedAt = '2026-01-01T00:00:00.000Z' }
        (Test-LEGatePolicy -Results $result -Policy $policy -Context $context).verdict | Should -Be 'PASS'
        $capture.executions.Count | Should -Be 2
    }
    It 'rejects a deliberately mismatched copy without modifying the genuine fixture' {
        $capture = Get-Content (Join-Path $root 'tests/fixtures/sanitized-live/restored-success.json') -Raw | ConvertFrom-Json
        $capture.executions[0].userSessionId = 'not-a-collected-session'
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId $capture.run.id).complete | Should -BeFalse
    }

    It 'evaluates the genuine deliberate failure with matching execution and screenshot relationships' {
        $capture = Get-Content (Join-Path $root 'tests/fixtures/sanitized-live/deliberate-failure.json') -Raw | ConvertFrom-Json
        $policy = Get-Content (Join-Path $root 'policies/default.policy.json') -Raw | ConvertFrom-Json
        $policy.functional.requiredApplications = @($capture.overview.applicationTestResult[0].applicationSummaries.applicationId)
        $policy.test.name = 'application-acceptance'
        $result = ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId $capture.run.id
        $result.complete | Should -BeTrue
        $context = [pscustomobject]@{ changeId = 'captured-deliberate-failure'; testName = $policy.test.name; testRunId = $capture.run.id; policyName = $policy.name; policyHash = 'fixture-review'; promotionMode = 'manual'; evaluatedAt = '2026-01-01T00:00:00.000Z' }
        $verdict = Test-LEGatePolicy -Results $result -Policy $policy -Context $context
        $verdict.verdict | Should -Be 'FAIL'
        $verdict.reasonCodes | Should -Contain 'application-failed'
        $failed = @($capture.executions | Where-Object state -EQ 'endedWithErrors')
        $failed.Count | Should -Be 1
        $capture.screenshots.Count | Should -Be 1
        $capture.screenshots[0].executionId | Should -Be $failed[0].id
        $capture.screenshots[0].runId | Should -Be $capture.run.id
    }
}
