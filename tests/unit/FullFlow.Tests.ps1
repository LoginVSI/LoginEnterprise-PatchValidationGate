Describe 'Offline full flow with external boundaries replaced' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        if (-not ('LEGateSyntheticJob' -as [type])) {
            Add-Type -TypeDefinition @'
public class LEGateSyntheticJob : System.Management.Automation.Job {
    public LEGateSyntheticJob() : base("synthetic remoting") { SetJobState(System.Management.Automation.JobState.Completed); }
    public override string Location { get { return "synthetic"; } }
    public override string StatusMessage { get { return "completed"; } }
    public override bool HasMoreData { get { return false; } }
    public override void StopJob() { SetJobState(System.Management.Automation.JobState.Stopped); }
}
'@
        }
        $savedEnvironment = @{}
        foreach ($key in @('LE_BASE_URL', 'LE_API_TOKEN', 'LE_SKIP_CERT_CHECK', 'GITHUB_TOKEN', 'GITHUB_REPOSITORY', 'GITHUB_ACTIONS')) { $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key) }
        $env:LE_BASE_URL = 'https://synthetic.invalid'
        $env:LE_API_TOKEN = 'synthetic-le-token'
        $env:GITHUB_TOKEN = 'synthetic-gh-token'
        $env:GITHUB_REPOSITORY = 'example/reference'
        $env:LE_SKIP_CERT_CHECK = 'false'
        $env:GITHUB_ACTIONS = 'true'
        $calls = New-Object Collections.ArrayList
        $state = @{}
        $png = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a1ioAAAAASUVORK5CYII=')
        Mock -ModuleName LEGate Invoke-RestMethod {
            $uriObject = [uri]$Uri
            $path = $uriObject.AbsolutePath
            $query = @{}
            foreach ($pair in $uriObject.Query.TrimStart('?').Split('&')) {
                if ($pair) { $kv = $pair.Split('=', 2); $query[$kv[0]] = [Uri]::UnescapeDataString($kv[1]) }
            }
            $bodyObject = $null
            if ($Body) { $bodyObject = ConvertFrom-Json -InputObject $Body }
            [void]$calls.Add([pscustomobject]@{ method = [string]$Method; path = $path; query = $query; body = $bodyObject; headers = $Headers })
            if ($uriObject.Host -eq 'synthetic.invalid') {
                if ($Headers.Authorization -ne 'Bearer synthetic-le-token') { throw 'Wrong appliance credential.' }
                if ($path -notmatch '/start$' -and $Method -ne 'GET') { throw 'Unexpected appliance HTTP method.' }
                switch ($path) {
                    '/publicApi/v8-preview/system/version' { return [pscustomobject]@{ currentVersion = 'synthetic' } }
                    '/publicApi/v8-preview/tests' {
                        if ($query.testType -eq 'continuousTest') { return New-LEGatePage -Items @([pscustomobject]@{ id = 'continuous-1'; name = 'patch-gate-continuous'; state = $state.continuousState }) -TotalCount 1 }
                        if ($query.testType -ne 'applicationTest') { throw 'Unexpected test type.' }
                        return New-LEGatePage -Items @([pscustomobject]@{ id = 'test-1'; name = 'patch-gate-app'; state = 'enabled' }) -TotalCount 1
                    }
                    '/publicApi/v8-preview/tests/test-1/test-runs' { return New-LEGatePage }
                    '/publicApi/v8-preview/tests/test-1/start' {
                        if ($Method -ne 'PUT' -or $bodyObject.testRunName -ne 'full-flow' -or $bodyObject.comment -notmatch '^identityHash=[a-f0-9]{64}$') { throw 'Invalid application start request.' }
                        return [pscustomobject]@{ id = 'synthetic-run' }
                    }
                    '/publicApi/v8-preview/test-runs/synthetic-run' {
                        $state.polls++
                        if ($state.mode -eq 'request-error' -and $state.polls -gt 2) { throw 'Synthetic transport error.' }
                        $run = $state.capture.run.PSObject.Copy()
                        $run | Add-Member -NotePropertyName testRunName -NotePropertyValue 'full-flow'
                        if ($state.mode -eq 'timeout') { $run.state = 'created' }
                        return $run
                    }
                    '/publicApi/v8-preview/application-test-run-overview/synthetic-run' { return $state.capture.overview }
                    '/publicApi/v8-preview/test-runs/synthetic-run/user-sessions' {
                        if ($state.mode -eq 'partial') { return New-LEGatePage -TotalCount 2 }
                        return New-LEGatePage -Items $state.capture.sessions -TotalCount $state.capture.sessions.Count
                    }
                    '/publicApi/v8-preview/test-runs/synthetic-run/user-sessions/session-1/app-executions' { return New-LEGatePage -Items $state.capture.executions -TotalCount $state.capture.executions.Count }
                    '/publicApi/v8-preview/test-runs/synthetic-run/events' { return New-LEGatePage -Items $state.capture.events -TotalCount $state.capture.events.Count }
                    '/publicApi/v8-preview/test-runs/synthetic-run/measurements' { return New-LEGatePage }
                    '/publicApi/v8-preview/test-runs/synthetic-run/app-executions/execution-2/screenshots' { return New-LEGatePage -Items @([pscustomobject]@{ id = 'shot-1' }) -TotalCount 1 }
                    '/publicApi/v8-preview/test-runs/synthetic-run/app-executions/execution-2/screenshots/shot-1' {
                        if (-not $OutFile -or $Method -ne 'GET') { throw 'Screenshot must be binary GET.' }
                        [IO.File]::WriteAllBytes($OutFile, $png)
                        return
                    }
                    '/publicApi/v8-preview/tests/continuous-1/start' {
                        if ($Method -ne 'PUT') { throw 'Wrong continuous method.' }
                        if ($state.mode -eq 'continuous-error') { throw 'Synthetic continuous error.' }
                        $state.continuousState = 'running'
                        return [pscustomobject]@{ id = 'continuous-run' }
                    }
                    default { throw ('Unmatched synthetic LE request: ' + $Method + ' ' + $path) }
                }
            }
            elseif ($uriObject.Host -eq 'api.github.com') {
                if ($Headers.Authorization -ne 'Bearer synthetic-gh-token') { throw 'Wrong GitHub credential.' }
                switch ($path) {
                    '/repos/example/reference/issues' {
                        if ($state.mode -eq 'issue-error') { throw 'Synthetic issue error.' }
                        if ($Method -eq 'GET') { return @() }
                        if ($Method -ne 'POST' -or $bodyObject.title -notmatch '^\[LEGate\] [a-f0-9]{64}$') { throw 'Invalid issue request.' }
                        return [pscustomobject]@{ number = 17 }
                    }
                    '/repos/example/reference/issues/17/comments' {
                        if ($Method -ne 'POST' -or $bodyObject.body -notmatch '^Stage:') { throw 'Invalid issue comment.' }
                        return [pscustomobject]@{ id = 1 }
                    }
                    '/repos/example/reference/issues/17' {
                        if ($Method -ne 'PATCH' -or $bodyObject.state -ne 'closed') { throw 'Invalid issue closure.' }
                        return [pscustomobject]@{ number = 17; state = 'closed' }
                    }
                    '/repos/example/reference/actions/runs/123/approvals' {
                        return @([pscustomobject]@{ state = 'approved'; environments = @([pscustomobject]@{ name = 'promotion-approval' }); user = [pscustomobject]@{ login = 'actual-reviewer' } })
                    }
                    default { throw ('Unmatched synthetic GitHub request: ' + $Method + ' ' + $path) }
                }
            }
            else { throw 'Network escape blocked by synthetic test.' }
        }
        Mock -ModuleName LEGate Invoke-Command {
            if ($ComputerName -ne 'synthetic-target' -or $null -eq $Credential) { throw 'Target credential not propagated.' }
            [void]$calls.Add([pscustomobject]@{ method = 'REMOTE'; path = $ArgumentList[0]; body = $ArgumentList[2] })
            $state.operation = $ArgumentList[0]
            return New-Object LEGateSyntheticJob
        }
        Mock -ModuleName LEGate Wait-Job { return $Job }
        Mock -ModuleName LEGate Receive-Job {
            $status = 'succeeded'
            if (($state.mode -eq 'adapter-error' -and $state.operation -eq 'verify') -or ($state.mode -eq 'restore-error' -and $state.operation -eq 'revert')) { $status = 'failed' }
            return [pscustomobject]@{ status = $status; details = @{ synthetic = $true; restored = ($state.operation -eq 'revert'); brokenStateVerified = ($state.operation -eq 'verify') } }
        }
        Mock -ModuleName LEGate Remove-Job { }
        Mock -ModuleName LEGate Stop-Job { }
        Mock -ModuleName LEGate Start-Sleep { $state.now = $state.now.AddMinutes(2) }
        Mock -ModuleName LEGate Get-LEGateUtcNow { return $state.now }
    }
    BeforeEach {
        $calls.Clear(); $state.Clear()
        $state.mode = 'pass'; $state.continuousState = 'enabled'; $state.polls = 0
        $state.now = [DateTime]::Parse('2026-09-17T00:00:00Z').ToUniversalTime()
        $state.capture = Get-Content (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'tests/synthetic/pass.json') -Raw | ConvertFrom-Json
        $caseRoot = Join-Path -Path $TestDrive -ChildPath ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($caseRoot) | Out-Null
        $policy = Get-Content (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'tests/synthetic/policy.json') -Raw | ConvertFrom-Json
        $policy.execution.maxWaitMinutes = 1
        $policy | ConvertTo-Json -Depth 20 | Set-Content (Join-Path -Path $caseRoot -ChildPath 'policy.json')
        Copy-Item (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'tests/synthetic/response-profile.json') (Join-Path -Path $caseRoot -ChildPath 'profile.json')
        $manifest = @{
            manifestVersion = '1'; kind = 'pinned-msi'; application = '7zip'; installDirectory = 'C:\LEGateDemo\7zip'
            executable = '7zFM.exe'; directoryProperty = 'INSTALLDIR'
            before = @{ version = '1.0'; url = 'https://synthetic.invalid/before.msi'; sha256 = ('a' * 64); productCode = '{11111111-1111-1111-1111-111111111111}' }
            after = @{ version = '2.0'; url = 'https://synthetic.invalid/after.msi'; sha256 = ('b' * 64); productCode = '{22222222-2222-2222-2222-222222222222}' }
        }
        $manifest | ConvertTo-Json -Depth 20 | Set-Content (Join-Path -Path $caseRoot -ChildPath 'change.json')
        $secure = New-Object Security.SecureString
        $secure.AppendChar('x')
        $credential = New-Object Management.Automation.PSCredential('synthetic-account', $secure)
        $gateArgs = @{
            ChangeId = 'full-flow'; RepositoryRoot = $caseRoot; PolicyFile = 'policy.json'; ChangeManifest = 'change.json'; ResponseProfile = 'profile.json'
            Adapter = 'app-update'; Target = 'synthetic-target'; ContinuousTestName = 'patch-gate-continuous'
            StateRoot = (Join-Path -Path $caseRoot -ChildPath 'state'); EvidenceRoot = (Join-Path -Path $caseRoot -ChildPath 'evidence')
            Credential = $credential; ReportIssue = $true; Synthetic = $true; PromotionMode = 'manual'
        }
    }
    AfterAll {
        foreach ($key in $savedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key]) }
    }
    It 'runs apply/verify, collection, PASS, publication, real approval parser, simulated promotion, continuous handoff and issue close' {
        $result = Invoke-LEGateValidation @gateArgs
        $result.verdict | Should -Be 'PASS'
        $result.exitCode | Should -Be 0
        $bundle = Test-LEGateEvidence -Path $result.privatePath -ExpectedManifestHash $result.manifestSha256
        $bundle.manifest.provenance | Should -Be 'synthetic'
        $publicPath = Join-Path -Path $caseRoot -ChildPath 'public'
        $published = Publish-LEGateEvidence -PrivatePath $result.privatePath -OutputPath $publicPath
        $time = [pscustomobject]@{ kind = 'github-approval-time-evidence'; repository = 'example/reference'; workflowRunId = '123'; environment = 'promotion-approval'; reviewer = 'actual-reviewer'; approvedAt = '2026-09-17T00:01:00Z'; source = 'https://github.com/example/reference/actions/runs/123' }
        $approval = Get-LEGateApproval -WorkflowRunId '123' -TimeEvidence $time
        $approval.approvedBy | Should -Be 'actual-reviewer'
        $record = Write-LEGatePromotionRecord -BundlePath $publicPath -ExpectedManifestHash $published.manifestSha256 -BundleName 'synthetic-validation' -Policy $policy -Mode manual -Approval $approval -Synthetic -OutputPath (Join-Path -Path $caseRoot -ChildPath 'promotion.json')
        $record.provenance | Should -Be 'synthetic'
        $handoff = Invoke-LEGateContinuousHandoff -Session (Connect-LEGate) -Name 'patch-gate-continuous' -StateRoot $gateArgs.StateRoot -Target $gateArgs.Target -IdentityHash $bundle.manifest.identityHash
        Close-LEGateChangeIssue -IssueNumber 17 -Handoff $handoff
        @($calls | Where-Object { $_.method -eq 'PATCH' }).Count | Should -Be 1
        $paths = @($calls | ForEach-Object { $_.path })
        [array]::IndexOf($paths, 'verify') | Should -BeLessThan ([array]::IndexOf($paths, '/publicApi/v8-preview/tests/test-1/start'))
        [array]::IndexOf($paths, '/publicApi/v8-preview/tests/continuous-1/start') | Should -BeLessThan ([array]::IndexOf($paths, '/repos/example/reference/issues/17'))
    }
    It 'enforces auto guardrails through real validation and promotion' {
        $gateArgs.PromotionMode = 'auto'
        $result = Invoke-LEGateValidation @gateArgs
        $result.verdict | Should -Be 'PASS'
        $record = Write-LEGatePromotionRecord -BundlePath $result.privatePath -ExpectedManifestHash $result.manifestSha256 -BundleName 'synthetic-auto' -Policy $policy -Mode auto -Timestamp '2026-09-17T00:00:00.000Z' -Synthetic -OutputPath (Join-Path $caseRoot 'auto.json')
        $record.approvedBy | Should -Be 'policy'
        $policy.promotion.autoRequires += 'unknown-guard'
        { Write-LEGatePromotionRecord -BundlePath $result.privatePath -ExpectedManifestHash $result.manifestSha256 -BundleName 'synthetic-auto' -Policy $policy -Mode auto -Synthetic } | Should -Throw '*policy*'
    }
    It 'preserves failed-execution screenshot bytes and blocks FAIL promotion' {
        $state.capture = Get-Content (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'tests/synthetic/fail.json') -Raw | ConvertFrom-Json
        $gateArgs.Adapter = 'break'
        $result = Invoke-LEGateValidation @gateArgs
        $result.verdict | Should -Be 'FAIL'
        $result.exitCode | Should -Be 1
        $bundle = Test-LEGateEvidence -Path $result.privatePath
        @($bundle.manifest.files | Where-Object { $_.kind -eq 'screenshot' }).Count | Should -Be 1
        $shot = Join-Path -Path $result.privatePath -ChildPath 'raw/screenshots/execution-2/shot-1.bin'
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($shot)) | Should -Be ([Convert]::ToBase64String($png))
        { Write-LEGatePromotionRecord -BundlePath $result.privatePath -ExpectedManifestHash $result.manifestSha256 -BundleName 'synthetic-validation' -Policy $policy -Mode manual -Synthetic } | Should -Throw '*PASS*'
        @($calls | Where-Object { $_.path -eq '/publicApi/v8-preview/tests/continuous-1/start' }).Count | Should -Be 0
    }
    It 'preserves INCONCLUSIVE for timeout, partial paging, API failure and adapter verification failure' {
        foreach ($mode in @('timeout', 'partial', 'request-error', 'adapter-error')) {
            $state.mode = $mode; $state.polls = 0
            $gateArgs.StateRoot = Join-Path -Path $caseRoot -ChildPath ('state-' + $mode)
            $result = Invoke-LEGateValidation @gateArgs
            $result.verdict | Should -Be 'INCONCLUSIVE' -Because $mode
            $result.exitCode | Should -Be 2
            (Test-LEGateEvidence -Path $result.privatePath).valid | Should -BeTrue
        }
        @($calls | Where-Object { $_.path -eq '/publicApi/v8-preview/tests/continuous-1/start' }).Count | Should -Be 0
    }
    It 'treats infrastructure and malformed results as inconclusive' {
        $state.capture.events = @([pscustomobject]@{ type = 'launcherOffline' })
        (Invoke-LEGateValidation @gateArgs).verdict | Should -Be 'INCONCLUSIVE'
        $gateArgs.StateRoot = Join-Path -Path $caseRoot -ChildPath 'another-state'
        $state.capture.events = @(); $state.capture.overview.applications[0].appExecutionSuccessful = $null
        (Invoke-LEGateValidation @gateArgs).verdict | Should -Be 'INCONCLUSIVE'
    }
    It 'blocks cancelled, internal-error and wrong-run evidence' {
        foreach ($runResult in @('cancelled', 'internalError', 'incomplete')) {
            $gateArgs.StateRoot = Join-Path $caseRoot ('state-' + $runResult)
            $state.capture.run.result = $runResult
            (Invoke-LEGateValidation @gateArgs).verdict | Should -Be 'INCONCLUSIVE'
        }
        $gateArgs.StateRoot = Join-Path $caseRoot 'state-wrong-id'
        $state.capture.run.id = 'wrong-run'
        (Invoke-LEGateValidation @gateArgs).verdict | Should -Be 'INCONCLUSIVE'
        @($calls | Where-Object { $_.path -eq '/publicApi/v8-preview/tests/continuous-1/start' }).Count | Should -Be 0
    }
    It 'resumes matching identity without applying again and rejects changed policy before mutation' {
        $first = Invoke-LEGateValidation @gateArgs
        $calls.Clear()
        $resumed = Invoke-LEGateValidation @gateArgs -Resume
        $resumed.verdict | Should -Be 'PASS'
        @($calls | Where-Object { $_.method -eq 'REMOTE' -or $_.method -eq 'PUT' }).Count | Should -Be 0
        Add-Content (Join-Path -Path $caseRoot -ChildPath 'policy.json') ' '
        $calls.Clear()
        $rejected = Invoke-LEGateValidation @gateArgs -Resume
        $rejected.verdict | Should -Be 'INCONCLUSIVE'
        @($calls | Where-Object { $_.method -eq 'REMOTE' -or $_.method -eq 'PUT' }).Count | Should -Be 0
        $first.verdict | Should -Be 'PASS'
    }
    It 'retains original PASS when later continuous handoff fails and refuses tampering' {
        $result = Invoke-LEGateValidation @gateArgs
        $bundle = Test-LEGateEvidence -Path $result.privatePath
        $state.mode = 'continuous-error'
        { Invoke-LEGateContinuousHandoff -Session (Connect-LEGate) -Name 'patch-gate-continuous' -StateRoot $gateArgs.StateRoot -Target $gateArgs.Target -IdentityHash $bundle.manifest.identityHash } | Should -Throw
        (Test-LEGateEvidence -Path $result.privatePath).verdict.verdict | Should -Be 'PASS'
        Add-Content (Join-Path -Path $result.privatePath -ChildPath 'summary.md') 'changed'
        { Test-LEGateEvidence -Path $result.privatePath -ExpectedManifestHash $result.manifestSha256 } | Should -Throw
        @($calls | Where-Object { $_.method -eq 'PATCH' }).Count | Should -Be 0
    }
    It 'records verified restore separately through mocked remoting and retains failed restore recovery state' {
        $result = Invoke-LEGateValidation @gateArgs
        $state.mode = 'restore-error'
        $failed = Invoke-LEGateValidation @gateArgs -Revert
        $failed.exitCode | Should -Be 2
        $state.mode = 'pass'
        $restored = Invoke-LEGateValidation @gateArgs -Revert
        $restored.restored | Should -BeTrue
        (Test-LEGateEvidence -Path $result.privatePath).verdict.verdict | Should -Be 'PASS'
        @($calls | Where-Object { $_.method -eq 'REMOTE' -and $_.path -eq 'revert' }).Count | Should -Be 2
    }
    It 'does not mutate when ticket creation fails and never infers approval time' {
        $state.mode = 'issue-error'
        (Invoke-LEGateValidation @gateArgs).verdict | Should -Be 'INCONCLUSIVE'
        @($calls | Where-Object { $_.method -eq 'REMOTE' }).Count | Should -Be 0
        { Get-LEGateApproval -WorkflowRunId '123' } | Should -Throw '*time provenance unavailable*'
    }
}
