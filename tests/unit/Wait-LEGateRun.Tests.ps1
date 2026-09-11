Describe 'Wait-LEGateRun' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $clock = @{ now = [DateTime]::new(2026, 9, 11, 20, 0, 0, [DateTimeKind]::Utc); stepMinutes = 0 }
        $state = @{ sequence = @(); index = 0 }
        $sleeps = [System.Collections.ArrayList]::new()

        Mock -ModuleName LEGate Get-LEGateUtcNow {
            $value = $clock.now
            $clock.now = $clock.now.AddMinutes($clock.stepMinutes)
            $value
        }
        Mock -ModuleName LEGate Start-Sleep { [void]$sleeps.Add($Seconds) }
        Mock -ModuleName LEGate Invoke-RestMethod {
            if ($Uri -notlike '*/test-runs/run-1') { throw "Unexpected call: $Method $Uri" }
            $item = $state.sequence[[Math]::Min($state.index, $state.sequence.Count - 1)]
            $state.index++
            [pscustomobject]@{
                id                = 'run-1'
                testRunName       = 'CHG-100'
                state             = $item.state
                result            = $item.result
                appFailureResults = [pscustomobject]@{ successCount = 3; totalCount = 3 }
            }
        }
    }

    BeforeEach {
        $clock.now = [DateTime]::new(2026, 9, 11, 20, 0, 0, [DateTimeKind]::Utc)
        $clock.stepMinutes = 0
        $state.index = 0
        $sleeps.Clear()
    }

    It 'polls GET /test-runs/{id} through created and testRunEnded until completed' {
        $state.sequence = @(
            @{ state = 'created'; result = $null },
            @{ state = 'testRunEnded'; result = $null },
            @{ state = 'completed'; result = 'successful' }
        )
        $run = Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-100' -PollIntervalSeconds 5 -EvidenceRoot $TestDrive 6>$null
        $run.state | Should -Be 'completed'
        $run.result | Should -Be 'successful'
        $run.timedOut | Should -BeFalse
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 3 -Exactly
        $sleeps.Count | Should -Be 2
        $sleeps | Should -Be @(5, 5)
    }

    It 'returns straight away when the run is already completed' {
        $state.sequence = @(@{ state = 'completed'; result = 'successful' })
        $run = Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-100' -EvidenceRoot $TestDrive 6>$null
        $run.timedOut | Should -BeFalse
        $sleeps.Count | Should -Be 0
    }

    It 'returns timedOut = true instead of throwing when the wait budget passes' {
        $state.sequence = @(@{ state = 'created'; result = $null })
        $clock.stepMinutes = 10
        $run = Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-100' -MaxWaitMinutes 25 -PollIntervalSeconds 30 -EvidenceRoot $TestDrive 6>$null 3>$null
        $run.timedOut | Should -BeTrue
        $run.state | Should -Be 'created'
        $run.waitedSeconds | Should -BeGreaterThan 0
    }

    It 'passes through a completed run with a non-successful result without judging it' {
        $state.sequence = @(@{ state = 'completed'; result = 'internalError' })
        $run = Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-100' -EvidenceRoot $TestDrive 6>$null
        $run.result | Should -Be 'internalError'
        $run.timedOut | Should -BeFalse
    }

    It 'writes the raw run to evidence/{changeId}/run.json without the timedOut property' {
        $state.sequence = @(@{ state = 'completed'; result = 'successful' })
        $root = Join-Path -Path $TestDrive -ChildPath 'evidence'
        Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-100' -EvidenceRoot $root 6>$null | Out-Null
        $file = Join-Path -Path $root -ChildPath 'CHG-100\run.json'
        Test-Path -Path $file | Should -BeTrue
        $saved = Get-Content -Path $file -Raw | ConvertFrom-Json
        $saved.id | Should -Be 'run-1'
        $saved.state | Should -Be 'completed'
        $saved.appFailureResults.totalCount | Should -Be 3
        $saved.PSObject.Properties.Name | Should -Not -Contain 'timedOut'
    }

    It 'writes the last run seen even on timeout' {
        $state.sequence = @(@{ state = 'testRunEnded'; result = $null })
        $clock.stepMinutes = 60
        $root = Join-Path -Path $TestDrive -ChildPath 'evidence-timeout'
        Wait-LEGateRun -Session $session -TestRunId 'run-1' -ChangeId 'CHG-101' -MaxWaitMinutes 1 -EvidenceRoot $root 6>$null 3>$null | Out-Null
        $saved = Get-Content -Path (Join-Path -Path $root -ChildPath 'CHG-101\run.json') -Raw | ConvertFrom-Json
        $saved.state | Should -Be 'testRunEnded'
    }
}
