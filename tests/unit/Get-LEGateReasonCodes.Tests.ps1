Describe 'Get-LEGateReasonCodes' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $codes = @(InModuleScope LEGate { Get-LEGateReasonCodes })
        $verdictDoc = Get-Content -Path (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'docs\verdict.md') -Raw
        $policy = Get-Content -Path (Join-Path -Path $script:LEGateRepoRoot -ChildPath 'policies\default.policy.json') -Raw | ConvertFrom-Json
    }

    It 'returns kebab-case codes with no duplicates' {
        $codes.Count | Should -BeGreaterThan 0
        foreach ($code in $codes) { $code | Should -Match '^[a-z]+(-[a-z]+)*$' }
        @($codes | Select-Object -Unique).Count | Should -Be $codes.Count
    }

    It 'matches the reason codes listed in docs/verdict.md exactly' {
        # The doc lists each code as a markdown bullet with the code in backticks.
        $section = ($verdictDoc -split '## Reason codes')[1] -split '## verdict.json' | Select-Object -First 1
        $documented = @([regex]::Matches($section, '^- `([a-z-]+)`', 'Multiline') | ForEach-Object { $_.Groups[1].Value })
        $documented | Should -Be $codes
    }

    It 'matches inconclusiveWhen in policies/default.policy.json exactly' {
        @($policy.inconclusiveWhen) | Should -Be $codes
    }
}
