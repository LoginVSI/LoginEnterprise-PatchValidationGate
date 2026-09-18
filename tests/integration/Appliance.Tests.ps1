# Integration tests. These talk to a real appliance and are skipped when
# LE_BASE_URL or LE_API_TOKEN is not set. They read only, except for the optional
# start test which needs LE_TEST_NAME and LE_CHANGE_ID and is off by default.

$script:hasAppliance = -not ([string]::IsNullOrWhiteSpace($env:LE_BASE_URL) -or [string]::IsNullOrWhiteSpace($env:LE_API_TOKEN))

Describe 'Appliance' -Skip:(-not $script:hasAppliance) {
    BeforeAll {
        Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\LEGate\LEGate.psd1') -Force
        $skipCert = ConvertTo-LEGateBoolean -Value $env:LE_SKIP_CERT_CHECK
        $session = Connect-LEGate -SkipCertificateCheck:$skipCert 6>$null 3>$null
    }

    It 'answers GET /system/version' {
        $version = Get-LEGateVersion -Session $session 6>$null
        $version.currentVersion | Should -Not -BeNullOrEmpty
    }

    It 'resolves the application test named in LE_TEST_NAME' -Skip:([string]::IsNullOrWhiteSpace($env:LE_TEST_NAME)) {
        $test = Resolve-LEGateTest -Session $session -Name $env:LE_TEST_NAME 6>$null
        $test.name | Should -BeExactly $env:LE_TEST_NAME
        $test.id | Should -Not -BeNullOrEmpty
    }

    It 'refuses a name that does not exist' {
        { Resolve-LEGateTest -Session $session -Name ('legate-no-such-test-' + [guid]::NewGuid()) 6>$null } | Should -Throw '*No application test named exactly*'
    }
}
