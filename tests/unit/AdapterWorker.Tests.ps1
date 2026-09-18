Describe 'Demo adapter worker with synthetic files and mocked installer boundary' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
    }
    BeforeEach {
        $workerRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($workerRoot) | Out-Null
        $exe = Join-Path $workerRoot 'demo.exe'
        [IO.File]::WriteAllText($exe, '2.0')
        $manifest = [pscustomobject]@{
            installDirectory = $workerRoot; executable = 'demo.exe'; directoryProperty = 'INSTALLDIR'
            before = [pscustomobject]@{ version = '1.0'; sha256 = ('a' * 64); productCode = '{11111111-1111-1111-1111-111111111111}'; url = 'https://synthetic.invalid/before.msi' }
            after = [pscustomobject]@{ version = '2.0'; sha256 = ('b' * 64); productCode = '{22222222-2222-2222-2222-222222222222}'; url = 'https://synthetic.invalid/after.msi' }
        }
        Mock -ModuleName LEGate Get-Item {
            $item = Microsoft.PowerShell.Management\Get-Item -Force -LiteralPath $LiteralPath
            if ($LiteralPath -match 'demo\.exe') {
                return [pscustomobject]@{ Attributes = $item.Attributes; VersionInfo = @{ FileVersion = [IO.File]::ReadAllText($LiteralPath) } }
            }
            return $item
        }
        Mock -ModuleName LEGate Invoke-WebRequest { throw 'Unmatched download blocked.' }
        Mock -ModuleName LEGate Start-Process { throw 'Unmatched installer blocked.' }
    }
    It 'verifies the intended break then restores through actual file operations without installer calls' {
        InModuleScope LEGate -Parameters @{ manifest = $manifest } {
            (Invoke-LEGateAdapterWorker -Operation apply -Adapter break -Manifest $manifest -TimeoutSeconds 10).status | Should -Be 'succeeded'
            (Invoke-LEGateAdapterWorker -Operation verify -Adapter break -Manifest $manifest -TimeoutSeconds 10).details.brokenStateVerified | Should -BeTrue
            # Same version avoids installation while exercising the real rename restoration.
            $manifest.before.version = $manifest.after.version
            (Invoke-LEGateAdapterWorker -Operation revert -Adapter break -Manifest $manifest -TimeoutSeconds 10).details.restored | Should -BeTrue
        }
        Test-Path $exe | Should -BeTrue
        Test-Path ($exe + '.legate-disabled') | Should -BeFalse
        Should -Invoke -ModuleName LEGate Start-Process -Times 0
    }
    It 'refuses unbroken verification and restore collisions' {
        InModuleScope LEGate -Parameters @{ manifest = $manifest } {
            { Invoke-LEGateAdapterWorker -Operation verify -Adapter break -Manifest $manifest -TimeoutSeconds 10 } | Should -Throw '*break*'
        }
        [IO.File]::WriteAllText(($exe + '.legate-disabled'), '2.0')
        InModuleScope LEGate -Parameters @{ manifest = $manifest } {
            { Invoke-LEGateAdapterWorker -Operation revert -Adapter break -Manifest $manifest -TimeoutSeconds 10 } | Should -Throw '*collision*'
        }
    }
    It 'handles installer failure without claiming restoration' {
        $package = Join-Path $workerRoot 'synthetic.msi'
        [IO.File]::WriteAllText($package, 'synthetic installer')
        $manifest.before.sha256 = (Get-FileHash $package -Algorithm SHA256).Hash.ToLowerInvariant()
        Move-Item $package (Join-Path $workerRoot ('installer-' + $manifest.before.sha256 + '.msi'))
        Mock -ModuleName LEGate Start-Process {
            $process = [pscustomobject]@{ ExitCode = 1603 }
            $process | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { param($milliseconds) return $milliseconds -gt 0 }
            return $process
        }
        InModuleScope LEGate -Parameters @{ manifest = $manifest } {
            { Invoke-LEGateAdapterWorker -Operation revert -Adapter app-update -Manifest $manifest -TimeoutSeconds 10 } | Should -Throw '*Installer failed*'
        }
        Should -Invoke -ModuleName LEGate Start-Process -Times 1 -ParameterFilter { $WindowStyle -eq 'Hidden' -and $ArgumentList[0] -eq '/x' -and $ArgumentList -contains '/qn' }
        [IO.File]::ReadAllText($exe) | Should -Be '2.0'
    }
    It 'rejects a downloaded installer checksum before process execution' {
        Mock -ModuleName LEGate Invoke-WebRequest { [IO.File]::WriteAllText($OutFile, 'synthetic wrong bytes') }
        InModuleScope LEGate -Parameters @{ manifest = $manifest } {
            { Invoke-LEGateAdapterWorker -Operation revert -Adapter app-update -Manifest $manifest -TimeoutSeconds 10 } | Should -Throw '*checksum*'
        }
        Should -Invoke -ModuleName LEGate Start-Process -Times 0
        Should -Invoke -ModuleName LEGate Invoke-WebRequest -Times 1 -ParameterFilter { $MaximumRedirection -eq 0 -and $Uri -eq 'https://synthetic.invalid/before.msi' }
    }
}
