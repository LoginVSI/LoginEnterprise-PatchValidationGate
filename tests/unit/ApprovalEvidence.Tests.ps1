Describe 'Bounded approval evidence delivery and correlation' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $clock = @{}
        $delivery = @{}
        $savedRepo = $env:GITHUB_REPOSITORY
        $env:GITHUB_REPOSITORY = 'example/reference'
        Mock -ModuleName LEGate Get-LEGateUtcNow { $clock.now }
        Mock -ModuleName LEGate Start-Sleep {
            $clock.now = $clock.now.AddMilliseconds($Milliseconds)
            if ($delivery.enabled) { [IO.File]::WriteAllText($delivery.path, '{"delivered":true}') }
        }
        Mock -ModuleName LEGate Invoke-LEGateGitHubRequest {
            @([pscustomobject]@{ state = 'approved'; environments = @([pscustomobject]@{ name = 'promotion-approval' }); user = [pscustomobject]@{ login = 'reviewer' } })
        }
    }
    BeforeEach {
        $clock.now = [datetime]::Parse('2026-09-18T00:00:00Z').ToUniversalTime()
        $delivery.enabled = $false
        $delivery.path = Join-Path $TestDrive ([guid]::NewGuid().ToString('N') + '.json')
        $time = [pscustomobject]@{ kind = 'github-approval-time-evidence'; repository = 'example/reference'; workflowRunId = '123'; workflowRunAttempt = 2; environment = 'promotion-approval'; reviewer = 'reviewer'; approvedAt = '2026-09-18T00:00:00Z'; source = 'https://github.com/example/reference/actions/runs/123/attempts/2' }
    }
    AfterAll { $env:GITHUB_REPOSITORY = $savedRepo }
    It 'accepts delayed delivery before the deadline' {
        $delivery.enabled = $true
        (Wait-LEGateApprovalEvidence -Path $delivery.path -MaxWaitSeconds 5).delivered | Should -BeTrue
        Should -Invoke -ModuleName LEGate Start-Sleep -Times 1 -Exactly
    }
    It 'rejects absent evidence and evidence delivered exactly at the deadline' {
        { Wait-LEGateApprovalEvidence -Path $delivery.path -MaxWaitSeconds 3 -PollIntervalSeconds 2 } | Should -Throw '*bounded wait*'
        Should -Invoke -ModuleName LEGate Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 1000 }
        $delivery.enabled = $true
        { Wait-LEGateApprovalEvidence -Path $delivery.path -MaxWaitSeconds 2 } | Should -Throw '*bounded wait*'
    }
    It 'rejects malformed delivery instead of waiting for it to become valid' {
        Set-Content $delivery.path '{broken'
        { Wait-LEGateApprovalEvidence -Path $delivery.path } | Should -Throw
        Should -Invoke -ModuleName LEGate Start-Sleep -Times 0 -Exactly
    }
    It 'requires the same repository, run, attempt, environment and reviewer' {
        (Get-LEGateApproval -WorkflowRunId '123' -WorkflowRunAttempt 2 -TimeEvidence $time).workflowRunAttempt | Should -Be 2
        foreach ($field in @('repository', 'workflowRunId', 'workflowRunAttempt', 'environment', 'reviewer')) {
            $bad = $time.PSObject.Copy()
            $bad.$field = 'different'
            { Get-LEGateApproval -WorkflowRunId '123' -WorkflowRunAttempt 2 -TimeEvidence $bad } | Should -Throw '*provenance unavailable*'
        }
        $time.PSObject.Properties.Remove('workflowRunAttempt')
        { Get-LEGateApproval -WorkflowRunId '123' -WorkflowRunAttempt 2 -TimeEvidence $time } | Should -Throw '*provenance unavailable*'
    }
    It 'rejects a timestamp with impossible calendar fields' {
        $time.approvedAt = '2026-99-99T00:00:00Z'
        { Get-LEGateApproval -WorkflowRunId '123' -WorkflowRunAttempt 2 -TimeEvidence $time } | Should -Throw '*Invalid approval timestamp*'
    }
}
