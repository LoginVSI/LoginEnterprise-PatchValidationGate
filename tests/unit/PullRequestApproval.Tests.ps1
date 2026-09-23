Describe 'API-backed approval over a committed acceptance request' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $savedRepo = $env:GITHUB_REPOSITORY
        $env:GITHUB_REPOSITORY = 'example/reference'
        $state = @{}
        Mock -ModuleName LEGate Get-LEGateUtcNow { ([datetime]'2026-09-23T11:00:00Z').ToUniversalTime() }
        Mock -ModuleName LEGate Invoke-LEGateGitHubRequest {
            if ($Path -eq '/actions/runs/123/approvals') { return @([pscustomobject]@{ state = 'approved'; environments = @(@{ name = 'promotion-approval' }); user = @{ login = 'reviewer' } }) }
            if ($Path -eq '/pulls/7') { return $state.pr }
            if ($Path -like '/contents/*') { return @{ type = 'file'; encoding = 'base64'; content = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes((ConvertTo-Json $state.request -Compress))); path = '.acceptance/approval-request.json' } }
            if ($Path -eq '/actions/runs/123/attempts/2') { return $state.run }
            if ($Path -eq '/pulls/7/reviews?per_page=100&page=1') { return $state.reviews }
            if ($Path -eq '/pulls/7/reviews?per_page=100&page=2') { return @() }
            if ($Path -eq '/collaborators/reviewer/permission') { return @{ permission = $state.permission; user = @{ login = 'reviewer' } } }
            throw ('Unexpected request: ' + $Path)
        }
    }
    BeforeEach {
        $state.pr = @{ number = 7; state = 'open'; draft = $false; user = @{ login = 'request-author' }; base = @{ ref = 'main'; repo = @{ full_name = 'example/reference' } }; head = @{ sha = ('a' * 40); repo = @{ full_name = 'example/reference' } } }
        $state.request = @{ kind = 'legate-promotion-approval-request'; repository = 'example/reference'; workflowRunId = '123'; workflowRunAttempt = 2; environment = 'promotion-approval'; executionCommit = ('b' * 40); validationManifestSha256 = ('c' * 64); decision = 'approve-simulated-promotion' }
        $state.run = @{ id = 123; run_attempt = 2; head_sha = ('b' * 40); head_branch = 'main'; event = 'workflow_dispatch'; path = '.github/workflows/validate-patch.yml'; run_started_at = '2026-09-23T10:00:00Z'; repository = @{ full_name = 'example/reference' } }
        $state.reviews = @(@{ id = 9; state = 'APPROVED'; commit_id = ('a' * 40); submitted_at = '2026-09-23T10:05:00Z'; user = @{ login = 'reviewer'; type = 'User' }; html_url = 'https://github.com/example/reference/pull/7#pullrequestreview-9' })
        $state.permission = 'write'
        $pointer = @{ kind = 'github-pull-request-approval'; pullRequestNumber = 7; requestCommit = ('a' * 40) }
        $arguments = @{ WorkflowRunId = '123'; WorkflowRunAttempt = 2; TimeEvidence = $pointer; ExpectedManifestHash = ('c' * 64); ExecutionCommit = ('b' * 40); CapturePath = (Join-Path $TestDrive 'approval.json') }
    }
    AfterAll { $env:GITHUB_REPOSITORY = $savedRepo }
    It 'uses submitted_at from GitHub and retains the source response' {
        $approval = Get-LEGateApproval @arguments
        $approval.source | Should -Be 'github-pull-request-review'
        $approval.approvedAt | Should -Be '2026-09-23T10:05:00Z'
        $approval.timeEvidence.reviewId | Should -Be 9
        (Get-Content $arguments.CapturePath -Raw | ConvertFrom-Json).decisionReview.id | Should -Be 9
    }
    It 'rejects each mismatched acceptance identity' {
        foreach ($field in @('repository', 'workflowRunId', 'workflowRunAttempt', 'environment', 'executionCommit', 'validationManifestSha256', 'decision')) {
            $original = $state.request[$field]
            $state.request[$field] = 'wrong'
            { Get-LEGateApproval @arguments } | Should -Throw
            $state.request[$field] = $original
        }
    }
    It 'rejects changed, foreign, closed or draft approval requests' {
        $state.pr.head.sha = 'd' * 40
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.pr.head.sha = 'a' * 40
        $state.pr.head.repo.full_name = 'other/reference'
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.pr.head.repo.full_name = 'example/reference'
        $state.pr.state = 'closed'
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.pr.state = 'open'; $state.pr.draft = $true
        { Get-LEGateApproval @arguments } | Should -Throw
    }
    It 'rejects untrusted run identity and rerun mismatches' {
        foreach ($field in @('id', 'run_attempt', 'head_sha', 'head_branch', 'event', 'path')) {
            $original = $state.run[$field]; $state.run[$field] = 'wrong'
            { Get-LEGateApproval @arguments } | Should -Throw
            $state.run[$field] = $original
        }
    }
    It 'rejects dismissed, superseded, wrong-commit and invalid-time decisions' {
        foreach ($value in @('DISMISSED', 'CHANGES_REQUESTED', 'COMMENTED', 'PENDING')) {
            $state.reviews[0].state = $value
            { Get-LEGateApproval @arguments } | Should -Throw
        }
        $state.reviews[0].state = 'APPROVED'; $state.reviews[0].commit_id = 'd' * 40
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.reviews[0].commit_id = 'a' * 40
        foreach ($value in @('2026-99-99T00:00:00Z', '2026-09-23T09:00:00Z', '')) {
            $state.reviews[0].submitted_at = $value
            { Get-LEGateApproval @arguments } | Should -Throw
        }
        $state.reviews[0].submitted_at = '2026-09-23T10:05:00Z'
        $state.reviews += @{ id = 10; state = 'CHANGES_REQUESTED'; user = @{ login = 'reviewer' } }
        { Get-LEGateApproval @arguments } | Should -Throw
    }
    It 'rejects unauthorized reviewers, self-approval and a different environment reviewer' {
        $state.permission = 'read'
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.permission = 'write'; $state.pr.user.login = 'reviewer'
        { Get-LEGateApproval @arguments } | Should -Throw
        $state.pr.user.login = 'request-author'; $state.reviews[0].user.login = 'someone-else'
        { Get-LEGateApproval @arguments } | Should -Throw
    }
    It 'rejects incomplete review pagination and duplicate review identities' {
        $state.reviews = @($state.reviews[0], $state.reviews[0])
        { Get-LEGateApproval @arguments } | Should -Throw '*incomplete*'
        Mock -ModuleName LEGate Invoke-LEGateGitHubRequest { @(1..100 | ForEach-Object { @{ id = $_; user = @{ login = 'reviewer' } } }) } -ParameterFilter { $Path -like '/pulls/7/reviews*' }
        { Get-LEGateApproval @arguments } | Should -Throw '*incomplete*'
    }
    It 'limits new API paths to read-only approval resources' {
        & {
            $savedToken = $env:GITHUB_TOKEN
            try {
                $env:GITHUB_TOKEN = 'synthetic-token'
                # Load into this local scope, outside the module-scoped API mock.
                . (Join-Path (Get-Module LEGate).ModuleBase 'Private/Invoke-LEGateGitHubRequest.ps1')
                { Invoke-LEGateGitHubRequest -Method POST -Path '/pulls/7' } | Should -Throw '*Unsupported*'
                { Invoke-LEGateGitHubRequest -Method GET -Path '/contents/other.json?ref=main' } | Should -Throw '*Unsupported*'
                { Invoke-LEGateGitHubRequest -Method GET -Path '/pulls/7/reviews?per_page=100&page=1&other=x' } | Should -Throw '*Unsupported*'
            }
            finally { $env:GITHUB_TOKEN = $savedToken }
        }
    }
}
