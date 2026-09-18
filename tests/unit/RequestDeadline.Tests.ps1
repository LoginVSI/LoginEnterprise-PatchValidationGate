Describe 'HTTP deadline budget' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $clock = @{}
        Mock -ModuleName LEGate Get-LEGateUtcNow { $clock.now }
        Mock -ModuleName LEGate Start-Sleep { $clock.now = $clock.now.AddSeconds($Seconds) }
    }
    BeforeEach { $clock.now = [datetime]::Parse('2026-09-18T00:00:00Z').ToUniversalTime() }
    It 'bounds each retry request by the shrinking budget' {
        Mock -ModuleName LEGate Invoke-RestMethod {
            $clock.now = $clock.now.AddSeconds(2)
            throw (New-LEGateTestHttpException -StatusCode 503)
        }
        $deadline = $clock.now.AddSeconds(7)
        { InModuleScope LEGate -Parameters @{ s = $session; d = $deadline } { Invoke-LEGateRequest -Session $s -Method GET -Path '/test-runs/run-1' -Deadline $d } } | Should -Throw '*deadline exhausted*'
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $TimeoutSec -eq 7 }
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $TimeoutSec -eq 3 }
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 2 -Exactly
        Should -Invoke -ModuleName LEGate Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 1 }
    }
    It 'does not issue an expired request or use zero as an unlimited timeout' {
        Mock -ModuleName LEGate Invoke-RestMethod { throw 'Should not run' }
        $deadline = $clock.now.AddMilliseconds(500)
        { InModuleScope LEGate -Parameters @{ s = $session; d = $deadline } { Invoke-LEGateRequest -Session $s -Method GET -Path '/test-runs/run-1' -TimeoutSeconds 0 -Deadline $d } } | Should -Throw '*deadline exhausted*'
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 0 -Exactly
    }
    It 'does not retry a request that fails after the deadline' {
        Mock -ModuleName LEGate Invoke-RestMethod {
            $clock.now = $clock.now.AddSeconds(10)
            throw (New-LEGateTestTransportException)
        }
        $deadline = $clock.now.AddSeconds(5)
        { InModuleScope LEGate -Parameters @{ s = $session; d = $deadline } { Invoke-LEGateRequest -Session $s -Method GET -Path '/test-runs/run-1' -Deadline $d } } | Should -Throw '*deadline exhausted*'
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly
        Should -Invoke -ModuleName LEGate Start-Sleep -Times 0 -Exactly
    }
}
