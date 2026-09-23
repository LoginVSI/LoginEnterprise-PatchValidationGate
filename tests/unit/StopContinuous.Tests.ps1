Describe 'Continuous stop and independently observed drain' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
    }
    BeforeEach {
        $clock = @{ now = [datetime]'2026-01-01T00:00:00Z'; pages = 0 }
        Mock -ModuleName LEGate Get-LEGateUtcNow { $clock.now }
        Mock -ModuleName LEGate Start-Sleep { $clock.now = $clock.now.AddMilliseconds($Milliseconds) }
        Mock -ModuleName LEGate Resolve-LEGateContinuousTest { [pscustomobject]@{ id = 'continuous-1'; isEnabled = $true } }
        Mock -ModuleName LEGate Invoke-RestMethod {
            if ($Method -eq 'PUT' -and $Uri -like '*/tests/continuous-1/stop') { return }
            if ($Method -eq 'GET' -and $Uri -like '*/tests/continuous-1') { return [pscustomobject]@{ id = 'continuous-1'; isEnabled = $false } }
            if ($Method -eq 'GET' -and $Uri -like '*/user-sessions/active?*') {
                $clock.pages++
                if ($clock.pages -eq 1) { return [pscustomobject]@{ items = @([pscustomobject]@{ id = 'session-1'; testId = 'continuous-1' }); totalCount = 1; offset = 0 } }
                return [pscustomobject]@{ items = @(); totalCount = 0; offset = 0 }
            }
            throw 'Unexpected request; network blocked.'
        }
    }
    It 'writes stop once and waits for a separate empty session observation' {
        $result = Stop-LEGateContinuousTest -Session $session -Name synthetic -PollIntervalSeconds 5
        $result.sessionsDrained | Should -BeTrue
        $result.schedulingEnabled | Should -BeFalse
        $clock.pages | Should -Be 2
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }
    It 'does not report drain after the deadline even if scheduling is disabled' {
        Mock -ModuleName LEGate Invoke-RestMethod {
            if ($Method -eq 'PUT') { return }
            if ($Uri -like '*/tests/continuous-1') { return [pscustomobject]@{ id = 'continuous-1'; isEnabled = $false } }
            return [pscustomobject]@{ items = @([pscustomobject]@{ id = 'session-1'; testId = 'continuous-1' }); totalCount = 1; offset = 0 }
        }
        { Stop-LEGateContinuousTest -Session $session -Name synthetic -MaxDrainMinutes 1 -PollIntervalSeconds 30 } | Should -Throw '*did not drain*'
    }
    It 'WhatIf performs no stop or drain requests' {
        Stop-LEGateContinuousTest -Session $session -Name synthetic -WhatIf
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 0 -Exactly
    }
}
