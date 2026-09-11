Describe 'Resolve-LEGateTest' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $calls = [System.Collections.ArrayList]::new()

        # The appliance filter is a contains-match on name or description, so the
        # list always returns the partial matches too. Exact matching is our job.
        $tests = @(
            [pscustomobject]@{ id = 'aaaa-1'; name = 'Patch Gate - Office'; state = 'enabled'; description = 'Office apps' },
            [pscustomobject]@{ id = 'aaaa-2'; name = 'Patch Gate - Office (copy)'; state = 'disabled'; description = 'copy' },
            [pscustomobject]@{ id = 'aaaa-3'; name = 'patch gate - office'; state = 'enabled'; description = 'lower case' },
            [pscustomobject]@{ id = 'aaaa-4'; name = 'Something else'; state = 'enabled'; description = 'mentions Patch Gate - Office' }
        )

        Mock -ModuleName LEGate Invoke-RestMethod {
            # AbsoluteUri keeps the escaping that goes on the wire; ToString() would unescape it.
            [void]$calls.Add(@{ Method = $Method; Uri = ([uri]$Uri).AbsoluteUri })
            if ($Uri -like '*/tests/aaaa-1?*') {
                return [pscustomobject]@{ id = 'aaaa-1'; name = 'Patch Gate - Office'; state = 'enabled'; appThresholds = @(); sessionThresholds = @() }
            }
            $afterFilter = ([string]$Uri -split 'filter=')[1]
            $filter = [Uri]::UnescapeDataString(@($afterFilter -split '&')[0])
            $hits = @($tests | Where-Object { $_.name -like "*$filter*" -or $_.description -like "*$filter*" })
            New-LEGatePage -Items $hits -TotalCount $hits.Count
        }
    }

    BeforeEach { $calls.Clear() }

    It 'queries application tests with the name as filter' {
        Resolve-LEGateTest -Session $session -Name 'Patch Gate - Office' 6>$null | Out-Null
        $calls[0].Method | Should -Be 'GET'
        $calls[0].Uri | Should -Match '/publicApi/v8-preview/tests\?'
        $calls[0].Uri | Should -Match 'testType=applicationTest'
        $calls[0].Uri | Should -Match 'filter=Patch%20Gate%20-%20Office'
        $calls[0].Uri | Should -Match 'count=50'
    }

    It 'returns only the exact name match and rejects partial and case-different matches' {
        $test = Resolve-LEGateTest -Session $session -Name 'Patch Gate - Office' 6>$null
        $test.id | Should -Be 'aaaa-1'
        $test.name | Should -BeExactly 'Patch Gate - Office'
    }

    It 'throws when nothing matches exactly even though the filter found candidates' {
        { Resolve-LEGateTest -Session $session -Name 'Patch Gate' 6>$null } | Should -Throw '*No application test named exactly*'
    }

    It 'throws when nothing matches at all' {
        { Resolve-LEGateTest -Session $session -Name 'Does Not Exist' 6>$null } | Should -Throw '*No application test named exactly*'
    }

    It 'throws when more than one test has the exact name' {
        $dupe = New-LEGateTestSession
        Mock -ModuleName LEGate Invoke-RestMethod {
            New-LEGatePage -Items @(
                [pscustomobject]@{ id = 'dup-1'; name = 'Dup'; state = 'enabled' },
                [pscustomobject]@{ id = 'dup-2'; name = 'Dup'; state = 'enabled' }
            ) -TotalCount 2
        }
        { Resolve-LEGateTest -Session $dupe -Name 'Dup' 6>$null } | Should -Throw '*More than one*'
    }

    It 'reads the test again with include=thresholds when asked' {
        $test = Resolve-LEGateTest -Session $session -Name 'Patch Gate - Office' -Include thresholds 6>$null
        $test.id | Should -Be 'aaaa-1'
        $test.PSObject.Properties.Name | Should -Contain 'appThresholds'
        $calls.Count | Should -Be 2
        $calls[1].Uri | Should -Be 'https://appliance.example.test/publicApi/v8-preview/tests/aaaa-1?include=thresholds'
    }

    It 'only accepts thresholds as an include value' {
        { Resolve-LEGateTest -Session $session -Name 'Patch Gate - Office' -Include 'everything' } | Should -Throw
    }
}
