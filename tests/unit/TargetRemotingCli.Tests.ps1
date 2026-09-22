Describe 'Target remoting CLI configuration' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $cliPath = Join-Path $script:LEGateRepoRoot 'scripts/Invoke-Gate.ps1'
        $saved = @{}
        foreach ($key in @('LE_TARGET_TRANSPORT', 'LE_TARGET_PORT', 'TARGET_USER', 'TARGET_PASSWORD', 'GITHUB_ACTIONS', 'GITHUB_OUTPUT', 'GITHUB_SHA')) {
            $saved[$key] = [Environment]::GetEnvironmentVariable($key)
        }
    }
    BeforeEach {
        $env:GITHUB_ACTIONS = 'false'; $env:GITHUB_OUTPUT = ''; $env:GITHUB_SHA = 'synthetic'
        $env:LE_TARGET_TRANSPORT = ''; $env:LE_TARGET_PORT = ''
        $env:TARGET_USER = 'synthetic-account'; $env:TARGET_PASSWORD = 'synthetic-only'
        Mock Import-Module {}
        Mock Invoke-LEGateValidation { return [pscustomobject]@{ verdict = 'INCONCLUSIVE'; exitCode = 2; restored = $true } }
        $cliArgs = @{ ChangeId = 'cli-test'; Target = 'synthetic-target'; StateRoot = $TestDrive; EvidenceRoot = $TestDrive }
    }
    AfterAll {
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
    }
    It 'propagates environment HTTPS and explicit credentials for validation and restoration' {
        $env:LE_TARGET_TRANSPORT = 'HTTPS'; $env:LE_TARGET_PORT = '5986'
        $null = & $cliPath @cliArgs
        $null = & $cliPath @cliArgs -Revert
        Should -Invoke Invoke-LEGateValidation -Times 2 -Exactly -ParameterFilter {
            $TargetTransport -eq 'HTTPS' -and $TargetPort -eq 5986 -and $Credential.UserName -eq 'synthetic-account'
        }
        Should -Invoke Invoke-LEGateValidation -Times 1 -Exactly -ParameterFilter { $Revert }
    }
    It 'uses protocol defaults and lets explicit CLI parameters override environment' {
        $null = & $cliPath @cliArgs
        Should -Invoke Invoke-LEGateValidation -Times 1 -Exactly -ParameterFilter { $TargetTransport -eq 'HTTP' -and $TargetPort -eq 5985 }
        $env:LE_TARGET_TRANSPORT = 'HTTPS'
        $null = & $cliPath @cliArgs
        Should -Invoke Invoke-LEGateValidation -Times 1 -Exactly -ParameterFilter { $TargetTransport -eq 'HTTPS' -and $TargetPort -eq 5986 }
        $env:LE_TARGET_PORT = '5996'
        $null = & $cliPath @cliArgs -TargetTransport HTTP -TargetPort 5985
        Should -Invoke Invoke-LEGateValidation -Times 2 -Exactly -ParameterFilter { $TargetTransport -eq 'HTTP' -and $TargetPort -eq 5985 }
    }
    It 'propagates standalone wrapper settings for every adapter and operation' {
        Mock Invoke-LEGateChangeAdapter { return [pscustomobject]@{ status = 'succeeded' } }
        foreach ($adapterName in @('app-update', 'break', 'noop')) {
            $wrapper = Join-Path $script:LEGateRepoRoot ('adapters/change/' + $adapterName + '.ps1')
            foreach ($operationName in @('apply', 'verify', 'revert')) {
                $null = & $wrapper -Operation $operationName -ChangeId wrapper -Target synthetic-target -Parameters '{}' -UseCurrentCredentials -TargetTransport HTTPS -TargetPort 5996
                Should -Invoke Invoke-LEGateChangeAdapter -Times 1 -Exactly -ParameterFilter {
                    $Adapter -eq $adapterName -and $Operation -eq $operationName -and $TargetTransport -eq 'HTTPS' -and $TargetPort -eq 5996 -and $UseCurrentCredentials
                }
            }
        }
        Should -Invoke Invoke-LEGateChangeAdapter -Times 9 -Exactly
    }
    It 'rejects invalid environment configuration before orchestration' {
        $env:LE_TARGET_TRANSPORT = 'invalid'
        $null = & $cliPath @cliArgs
        $LASTEXITCODE | Should -Be 2
        $env:LE_TARGET_TRANSPORT = 'HTTPS'; $env:LE_TARGET_PORT = 'not-a-port'
        { & $cliPath @cliArgs } | Should -Throw
        $env:LE_TARGET_PORT = '65536'
        $null = & $cliPath @cliArgs
        $LASTEXITCODE | Should -Be 2
        Should -Invoke Invoke-LEGateValidation -Times 0 -Exactly
    }
}
