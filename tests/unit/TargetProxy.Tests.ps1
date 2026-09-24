Describe 'Explicit target WSMan proxy selection' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $savedProxy = $env:LE_TARGET_PROXY_ACCESS_TYPE
    }
    AfterAll { $env:LE_TARGET_PROXY_ACCESS_TYPE = $savedProxy }
    It 'preserves the platform default when no override is configured' {
        $env:LE_TARGET_PROXY_ACCESS_TYPE = ''
        InModuleScope LEGate { Get-LEGateTargetSessionOption | Should -BeNullOrEmpty }
    }
    It 'selects a direct connection without disabling TLS checks' {
        $env:LE_TARGET_PROXY_ACCESS_TYPE = 'NoProxyServer'
        InModuleScope LEGate {
            $option = Get-LEGateTargetSessionOption
            [string]$option.ProxyAccessType | Should -Be 'NoProxyServer'
            $option.SkipCACheck | Should -BeFalse
            $option.SkipCNCheck | Should -BeFalse
            $option.SkipRevocationCheck | Should -BeFalse
            $option.MaximumConnectionRedirectionCount | Should -Be 0
        }
    }
    It 'rejects unknown settings before remoting' {
        $env:LE_TARGET_PROXY_ACCESS_TYPE = 'unreviewed'
        InModuleScope LEGate { { Get-LEGateTargetSessionOption } | Should -Throw '*proxy*' }
    }
}
