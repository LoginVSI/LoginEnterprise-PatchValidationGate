Describe 'Get-LEGateAllPages' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $calls = [System.Collections.ArrayList]::new()
        $all = @(1..7 | ForEach-Object { [pscustomobject]@{ id = "item-$_" } })

        Mock -ModuleName LEGate Invoke-RestMethod {
            [void]$calls.Add($Uri)
            $query = @{}
            foreach ($pair in (($Uri -split '\?')[1] -split '&')) {
                $kv = $pair -split '=', 2
                $query[$kv[0]] = [Uri]::UnescapeDataString($kv[1])
            }
            $offset = [int]$query['offset']
            $count = [int]$query['count']
            $slice = @($all | Select-Object -Skip $offset -First $count)
            New-LEGatePage -Items $slice -TotalCount $all.Count -Offset $offset
        }
    }

    BeforeEach { $calls.Clear() }

    It 'walks count/offset/totalCount until every item is collected' {
        $items = @(InModuleScope LEGate -Parameters @{ s = $session } { Get-LEGateAllPages -Session $s -Path '/tests' -Query @{ count = 3; testType = 'applicationTest' } })
        $items.Count | Should -Be 7
        $items[0].id | Should -Be 'item-1'
        $items[6].id | Should -Be 'item-7'
        $calls.Count | Should -Be 3
        $calls[0] | Should -Match 'offset=0'
        $calls[1] | Should -Match 'offset=3'
        $calls[2] | Should -Match 'offset=6'
    }

    It 'passes the other query values through on every page and asks for the total count' {
        InModuleScope LEGate -Parameters @{ s = $session } { Get-LEGateAllPages -Session $s -Path '/tests' -Query @{ count = 5; testType = 'applicationTest'; filter = 'x' } } | Out-Null
        foreach ($uri in $calls) {
            $uri | Should -Match 'testType=applicationTest'
            $uri | Should -Match 'filter=x'
            $uri | Should -Match 'includeTotalCount=true'
        }
    }

    It 'returns an empty array when there is nothing' {
        Mock -ModuleName LEGate Invoke-RestMethod { New-LEGatePage -Items @() -TotalCount 0 }
        $items = @(InModuleScope LEGate -Parameters @{ s = $session } { Get-LEGateAllPages -Session $s -Path '/tests' -Query @{ count = 5 } })
        $items.Count | Should -Be 0
    }

    It 'stops when a page comes back empty even if totalCount says otherwise' {
        Mock -ModuleName LEGate Invoke-RestMethod { New-LEGatePage -Items @() -TotalCount 100 }
        $items = @(InModuleScope LEGate -Parameters @{ s = $session } { Get-LEGateAllPages -Session $s -Path '/tests' -Query @{ count = 5 } })
        $items.Count | Should -Be 0
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly
    }

    It 'requires count in the query' {
        { InModuleScope LEGate -Parameters @{ s = $session } { Get-LEGateAllPages -Session $s -Path '/tests' -Query @{ filter = 'x' } } } | Should -Throw '*count*'
    }
}
