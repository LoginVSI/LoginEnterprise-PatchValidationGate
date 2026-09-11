Describe 'Write-LEGateLog' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $null = New-LEGateTestSession
        $savedFormat = $env:LEGATE_LOG_FORMAT
        Mock -ModuleName LEGate Get-LEGateUtcNow { [DateTime]::new(2026, 9, 11, 20, 30, 15, 250, [DateTimeKind]::Utc) }
    }

    AfterAll { $env:LEGATE_LOG_FORMAT = $savedFormat }
    BeforeEach { $env:LEGATE_LOG_FORMAT = $null }

    It 'writes Info lines to the information stream with a UTC ISO 8601 timestamp' {
        $lines = @(InModuleScope LEGate { Write-LEGateLog -Level Info -Message 'hello' -Fields @{ b = 2; a = 'x' } } 6>&1 | ForEach-Object { [string]$_ })
        $lines.Count | Should -Be 1
        $lines[0] | Should -Be '2026-09-11T20:30:15.250Z [INFO] hello a=x b=2'
    }

    It 'writes Warn to the warning stream and Debug to the verbose stream' {
        $warn = @(InModuleScope LEGate { Write-LEGateLog -Level Warn -Message 'careful' } 3>&1 | ForEach-Object { [string]$_ })
        $warn[0] | Should -Match '\[WARN\] careful$'
        $verbose = @(InModuleScope LEGate { Write-LEGateLog -Level Debug -Message 'detail' -Verbose } 4>&1 | ForEach-Object { [string]$_ })
        $verbose[0] | Should -Match '\[DEBUG\] detail$'
    }

    It 'emits one JSON object per line with -AsJson' {
        $lines = @(InModuleScope LEGate { Write-LEGateLog -Level Warn -Message 'json please' -Fields @{ testRunId = 'r1'; attempt = 2 } -AsJson } 6>&1 | ForEach-Object { [string]$_ })
        $lines.Count | Should -Be 1
        # Check the timestamp on the raw text: PowerShell 7's ConvertFrom-Json turns ISO strings into DateTime.
        $lines[0] | Should -Match '"timestamp":"2026-09-11T20:30:15\.250Z"'
        $record = ConvertFrom-Json -InputObject $lines[0]
        $record.level | Should -Be 'warn'
        $record.message | Should -Be 'json please'
        $record.testRunId | Should -Be 'r1'
        $record.attempt | Should -Be 2
        $lines[0] | Should -Not -Match "`n"
    }

    It 'switches to JSON when LEGATE_LOG_FORMAT is json' {
        $env:LEGATE_LOG_FORMAT = 'json'
        $lines = @(InModuleScope LEGate { Write-LEGateLog -Level Info -Message 'env json' } 6>&1 | ForEach-Object { [string]$_ })
        (ConvertFrom-Json -InputObject $lines[0]).message | Should -Be 'env json'
    }

    It 'redacts registered secrets and bearer tokens in text and JSON modes' {
        $token = $script:LEGateTestToken
        $text = @(InModuleScope LEGate -Parameters @{ t = $token } { Write-LEGateLog -Level Info -Message "token $t sent as Bearer $t" -Fields @{ header = "Bearer $t" } } 6>&1 | ForEach-Object { [string]$_ })
        ($text -join '') | Should -Not -Match ([regex]::Escape($token))
        ($text -join '') | Should -Match '\[REDACTED\]'

        $json = @(InModuleScope LEGate -Parameters @{ t = $token } { Write-LEGateLog -Level Error -Message "bad $t" -Fields @{ header = "Bearer $t" } -AsJson } 6>&1 | ForEach-Object { [string]$_ })
        ($json -join '') | Should -Not -Match ([regex]::Escape($token))
        (ConvertFrom-Json -InputObject $json[0]).header | Should -Be 'Bearer [REDACTED]'
    }

    It 'masks a bearer token it was never told about' {
        $line = @(InModuleScope LEGate { Write-LEGateLog -Level Info -Message 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.unknown' } 6>&1 | ForEach-Object { [string]$_ })
        $line[0] | Should -Match 'Bearer \[REDACTED\]$'
        $line[0] | Should -Not -Match 'eyJhbGci'
    }

    It 'rejects unknown levels' {
        { InModuleScope LEGate { Write-LEGateLog -Level Loud -Message 'x' } } | Should -Throw
    }
}

Describe 'ConvertTo-LEGateTimestamp' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
    }

    It 'formats UTC with millisecond precision and a Z suffix' {
        InModuleScope LEGate { ConvertTo-LEGateTimestamp -Value ([DateTime]::new(2026, 1, 2, 3, 4, 5, 6, [DateTimeKind]::Utc)) } | Should -Be '2026-01-02T03:04:05.006Z'
    }

    It 'converts local times to UTC' {
        $local = [DateTime]::new(2026, 6, 1, 12, 0, 0, [DateTimeKind]::Local)
        $expected = $local.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        InModuleScope LEGate -Parameters @{ v = $local } { ConvertTo-LEGateTimestamp -Value $v } | Should -Be $expected
    }
}
