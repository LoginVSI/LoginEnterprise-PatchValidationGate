Describe 'Read-only installer preflight' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
    }
    It 'accepts remoted ArrayList state only for a positively idle service' {
        InModuleScope LEGate {
            $status = [pscustomobject]@{ querySucceeded = $true; state = 'Stopped'; acceptStop = $false; serviceProcessId = 0; processIds = (New-Object Collections.ArrayList); inProgressRegistry = $false }
            Test-LEGateInstallerIdle $status | Should -BeTrue
            $status.state = 'Running'; $status.acceptStop = $true; $status.serviceProcessId = 123
            [void]$status.processIds.Add(123)
            Test-LEGateInstallerIdle $status | Should -BeTrue
            $status.acceptStop = $false
            Test-LEGateInstallerIdle $status | Should -BeFalse
            $status.acceptStop = $true; [void]$status.processIds.Add(456)
            Test-LEGateInstallerIdle $status | Should -BeFalse
        }
    }
    It 'fails closed on unknown or in-progress observations' {
        InModuleScope LEGate {
            Test-LEGateInstallerIdle $null | Should -BeFalse
            Test-LEGateInstallerIdle ([pscustomobject]@{ querySucceeded = $false }) | Should -BeFalse
            Test-LEGateInstallerIdle ([pscustomobject]@{ querySucceeded = $true; state = 'Stopped'; serviceProcessId = 0; processIds = @(); inProgressRegistry = $true }) | Should -BeFalse
        }
    }
    It 'passes HTTPS port and explicit Negotiate credentials to the actual remoting boundary' {
        $credential = New-Object Management.Automation.PSCredential('synthetic-user', (ConvertTo-SecureString 'synthetic-password' -AsPlainText -Force))
        Mock -ModuleName LEGate Invoke-Command {
            Start-Job -ScriptBlock { [pscustomobject]@{ querySucceeded = $true; state = 'Stopped'; acceptStop = $false; serviceProcessId = 0; processIds = @(); inProgressRegistry = $false } }
        }
        (Get-LEGateInstallerState -Target target.invalid -TargetTransport HTTPS -TargetPort 5986 -Credential $credential).safeToInstall | Should -BeTrue
        Should -Invoke -ModuleName LEGate Invoke-Command -Times 1 -Exactly -ParameterFilter { $UseSSL -and $Port -eq 5986 -and $Authentication -eq 'Negotiate' -and $Credential.UserName -eq 'synthetic-user' }
    }
}
