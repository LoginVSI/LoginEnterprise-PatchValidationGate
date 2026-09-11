Describe 'Get-LEGateVersion' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $calls = [System.Collections.ArrayList]::new()
        Mock -ModuleName LEGate Invoke-RestMethod {
            [void]$calls.Add(@{ Method = $Method; Uri = $Uri; Headers = $Headers })
            [pscustomobject]@{ currentVersion = '6.8.6'; latestVersion = '6.8.6' }
        }
    }

    It 'calls GET /system/version under the configured base path and returns the version' {
        $version = Get-LEGateVersion -Session $session 6>$null
        $version.currentVersion | Should -Be '6.8.6'
        $calls.Count | Should -Be 1
        $calls[0].Method | Should -Be 'GET'
        $calls[0].Uri | Should -Be 'https://appliance.example.test/publicApi/v8-preview/system/version'
        $calls[0].Headers['Authorization'] | Should -Be ('Bearer ' + $script:LEGateTestToken)
    }

    It 'uses the API version from the session' {
        $calls.Clear()
        $v7 = New-LEGateTestSession -ApiVersion 'v7'
        Get-LEGateVersion -Session $v7 6>$null | Out-Null
        $calls[0].Uri | Should -Be 'https://appliance.example.test/publicApi/v7/system/version'
    }

    It 'rejects anything that is not a session' {
        { Get-LEGateVersion -Session ([pscustomobject]@{ BaseUrl = 'x' }) } | Should -Throw
    }
}
