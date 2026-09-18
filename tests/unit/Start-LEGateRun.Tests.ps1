Describe 'Start-LEGateRun' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $calls = [System.Collections.ArrayList]::new()
        $state = @{ existingRuns = @(); startStatus = 201 }

        Mock -ModuleName LEGate Invoke-RestMethod {
            [void]$calls.Add(@{ Method = $Method; Uri = $Uri; Body = $Body })
            if ($Uri -like '*/tests/test-1/test-runs?*') {
                return New-LEGatePage -Items $state.existingRuns -TotalCount $state.existingRuns.Count
            }
            if ($Uri -like '*/tests/test-1/start') {
                if ($state.startStatus -eq 409) {
                    throw (New-LEGateTestProblemRecord -StatusCode 409 -Title 'Test is already running')
                }
                return [pscustomobject]@{ id = 'run-new' }
            }
            throw "Unexpected call: $Method $Uri"
        }
    }

    BeforeEach {
        $calls.Clear()
        $state.existingRuns = @()
        $state.startStatus = 201
    }

    It 'lists existing runs newest first before starting anything' {
        Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' 6>$null | Out-Null
        $calls[0].Method | Should -Be 'GET'
        $calls[0].Uri | Should -Match '/tests/test-1/test-runs\?'
        $calls[0].Uri | Should -Match 'count=20'
        $calls[0].Uri | Should -Match 'orderBy=created'
        $calls[0].Uri | Should -Match 'direction=desc'
    }

    It 'starts a run with testRunName set to the change id and returns the new id' {
        $runId = Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' -Comment 'hello' 6>$null
        $runId | Should -Be 'run-new'
        $start = $calls | Where-Object { $_.Method -eq 'PUT' }
        $start | Should -Not -BeNullOrEmpty
        $start.Uri | Should -Be 'https://appliance.example.test/publicApi/v8-preview/tests/test-1/start'
        $body = ConvertFrom-Json -InputObject $start.Body
        $body.testRunName | Should -Be 'CHG-100'
        $body.comment | Should -Be 'hello'
    }

    It 'refuses name-only reuse and does not start a second run' {
        $state.existingRuns = @(
            [pscustomobject]@{ id = 'run-other'; testRunName = 'CHG-099'; state = 'completed' },
            [pscustomobject]@{ id = 'run-existing'; testRunName = 'CHG-100'; state = 'created' }
        )
        { Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' 6>$null } | Should -Throw '*durable identity*'
        @($calls | Where-Object { $_.Method -eq 'PUT' }).Count | Should -Be 0
    }

    It 'matches testRunName exactly, not partially' {
        $state.existingRuns = @([pscustomobject]@{ id = 'run-partial'; testRunName = 'CHG-1000'; state = 'completed' })
        $runId = Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' 6>$null
        $runId | Should -Be 'run-new'
    }

    It 'uses the policy file hash as the comment when no comment is given' {
        $policy = Join-Path -Path $TestDrive -ChildPath 'p.policy.json'
        Set-Content -Path $policy -Value '{"name":"x"}' -Encoding ascii
        $expected = (Get-FileHash -Path $policy -Algorithm SHA256).Hash.ToLowerInvariant()
        Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' -PolicyPath $policy 6>$null | Out-Null
        $start = $calls | Where-Object { $_.Method -eq 'PUT' }
        (ConvertFrom-Json -InputObject $start.Body).comment | Should -Be ('policyHash=sha256:' + $expected)
    }

    It 'turns a 409 into a clear error that carries the ProblemDetails title' {
        $state.startStatus = 409
        { Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' 6>$null } |
            Should -Throw '*could not be started*Test is already running*409*'
    }

    It 'does not retry the PUT' {
        $state.startStatus = 409
        try { Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' 6>$null } catch { $null = $_ }
        @($calls | Where-Object { $_.Method -eq 'PUT' }).Count | Should -Be 1
    }

    It 'supports -WhatIf without calling start' {
        $result = Start-LEGateRun -Session $session -TestId 'test-1' -ChangeId 'CHG-100' -WhatIf 6>$null
        $result | Should -BeNullOrEmpty
        @($calls | Where-Object { $_.Method -eq 'PUT' }).Count | Should -Be 0
    }
}
