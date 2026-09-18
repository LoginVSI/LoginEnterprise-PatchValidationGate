Describe 'Connect-LEGate' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $savedBaseUrl = $env:LE_BASE_URL
        $savedToken = $env:LE_API_TOKEN
    }

    AfterAll {
        $env:LE_BASE_URL = $savedBaseUrl
        $env:LE_API_TOKEN = $savedToken
    }

    BeforeEach {
        $env:LE_BASE_URL = $null
        $env:LE_API_TOKEN = $null
    }

    It 'builds a session from parameters' {
        $session = Connect-LEGate -BaseUrl 'https://appliance.example.test/' -ApiToken 'param-token' 6>$null
        $session.PSObject.TypeNames | Should -Contain 'LEGate.Session'
        $session.BaseUrl | Should -Be 'https://appliance.example.test'
        $session.ApiVersion | Should -Be 'v8-preview'
        $session.SkipCertificateCheck | Should -BeFalse
        $session.Token | Should -BeOfType [System.Security.SecureString]
        $session.ConnectedAt | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$'
    }

    It 'reads the environment variables when no parameters are given' {
        $env:LE_BASE_URL = 'https://env.example.test'
        $env:LE_API_TOKEN = 'env-token'
        $session = Connect-LEGate 6>$null
        $session.BaseUrl | Should -Be 'https://env.example.test'
        InModuleScope LEGate -Parameters @{ s = $session } { ConvertFrom-LEGateSecureString -SecureString $s.Token } | Should -Be 'env-token'
    }

    It 'lets parameters override the environment' {
        $env:LE_BASE_URL = 'https://env.example.test'
        $env:LE_API_TOKEN = 'env-token'
        $session = Connect-LEGate -BaseUrl 'https://override.example.test' -ApiToken 'override-token' -ApiVersion 'v7' 6>$null
        $session.BaseUrl | Should -Be 'https://override.example.test'
        $session.ApiVersion | Should -Be 'v7'
        InModuleScope LEGate -Parameters @{ s = $session } { ConvertFrom-LEGateSecureString -SecureString $s.Token } | Should -Be 'override-token'
    }

    It 'throws when the base URL is missing' {
        { Connect-LEGate -ApiToken 'x' } | Should -Throw '*LE_BASE_URL*'
    }

    It 'throws when the token is missing' {
        { Connect-LEGate -BaseUrl 'https://appliance.example.test' } | Should -Throw '*LE_API_TOKEN*'
    }

    It 'rejects a base URL that is not absolute http or https' {
        { Connect-LEGate -BaseUrl 'appliance.example.test' -ApiToken 'x' } | Should -Throw '*absolute*'
        { Connect-LEGate -BaseUrl 'ftp://appliance.example.test' -ApiToken 'x' } | Should -Throw '*absolute*'
    }

    It 'records the skip certificate flag on the session' {
        if ($PSVersionTable.PSEdition -eq 'Desktop') {
            $callback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
            { Connect-LEGate -BaseUrl 'https://appliance.example.test' -ApiToken 'x' -SkipCertificateCheck 6>$null } | Should -Throw '*requires PowerShell 7*'
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback | Should -Be $callback
            return
        }
        $session = Connect-LEGate -BaseUrl 'https://appliance.example.test' -ApiToken 'x' -SkipCertificateCheck 6>$null 3>$null
        $session.SkipCertificateCheck | Should -BeTrue
    }

    It 'does not put the token in its own log output' {
        $lines = @(Connect-LEGate -BaseUrl 'https://appliance.example.test' -ApiToken 'very-secret-token' 6>&1 | ForEach-Object { [string]$_ })
        $lines | Should -Not -BeNullOrEmpty
        ($lines -join "`n") | Should -Not -Match 'very-secret-token'
    }

    It 'does not expose the token when the session is serialized' {
        $session = Connect-LEGate -BaseUrl 'https://appliance.example.test' -ApiToken 'serialize-secret' 6>$null
        ($session | ConvertTo-Json -Depth 3) | Should -Not -Match 'serialize-secret'
        ($session | Out-String) | Should -Not -Match 'serialize-secret'
    }
}
