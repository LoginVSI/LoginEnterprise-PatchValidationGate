<#
.SYNOPSIS
    Installs the modules the repo needs and tells you what to set.
.DESCRIPTION
    Installs Pester 5 and PSScriptAnalyzer for the current user when they are
    missing. Nothing is installed machine-wide and nothing else is touched.
    Then prints the environment variables the smoke and integration scripts read.

    Works on Windows PowerShell 5.1 and PowerShell 7.
.EXAMPLE
    .\scripts\Initialize-DevEnvironment.ps1
#>
[CmdletBinding()]
# The PowerShellGet cmdlets ship with Windows PowerShell 5.1 but are not in the
# analyzer's base 5.1 cmdlet profile, so the compatibility rule flags them here.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseCompatibleCmdlets', '', Justification = 'PowerShellGet cmdlets are present on 5.1')]
param()

$ErrorActionPreference = 'Stop'

# When Windows PowerShell 5.1 inherits a PSModulePath that lists the PowerShell 7
# module folder first, it tries to load PowerShell 7's PackageManagement and fails.
# Drop those entries for this process only.
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    $cleaned = @($env:PSModulePath -split ';' | Where-Object { $_ -and ($_ -notmatch '\\PowerShell\\7[^\\]*\\Modules') })
    $env:PSModulePath = $cleaned -join ';'
}

# Windows PowerShell 5.1 can default to a protocol PowerShell Gallery no longer accepts.
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

$required = @(
    @{ Name = 'Pester'; MinimumVersion = '5.7.1'; RequiredVersion = '5.7.1' },
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.21.0' }
)

try {
    Import-Module -Name PackageManagement -ErrorAction Stop
    $nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge [Version]'2.8.5.201' }
    if (-not $nuget) {
        Write-Output 'Installing the NuGet package provider for the current user.'
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force | Out-Null
    }
}
catch {
    # Install-Module -Force bootstraps the provider itself, so this is not fatal.
    Write-Warning ('Could not check the NuGet package provider: {0}' -f $_.Exception.Message)
}

foreach ($module in $required) {
    $installed = Get-Module -ListAvailable -Name $module.Name | Where-Object {
        if ($module.RequiredVersion) { $_.Version -eq [Version]$module.RequiredVersion }
        else { $_.Version -ge [Version]$module.MinimumVersion }
    } | Select-Object -First 1
    if ($installed) {
        Write-Output ('{0} {1} is already available.' -f $module.Name, $installed.Version)
        continue
    }
    Write-Output ('Installing the configured version of {0} for the current user.' -f $module.Name)
    try {
        Import-Module -Name PowerShellGet -ErrorAction Stop
    }
    catch {
        Write-Warning ('PowerShellGet could not be loaded in this PowerShell: {0}' -f $_.Exception.Message)
        Write-Warning ('Fallback: from PowerShell 7 run  Save-Module -Name {0} -Path "$HOME\Documents\WindowsPowerShell\Modules"  and rerun this script. See docs/setup.md.' -f $module.Name)
        exit 1
    }
    $installArgs = @{ Name = $module.Name; Scope = 'CurrentUser'; Force = $true; SkipPublisherCheck = $true; AllowClobber = $true }
    if ($module.RequiredVersion) { $installArgs.RequiredVersion = $module.RequiredVersion }
    else { $installArgs.MinimumVersion = $module.MinimumVersion }
    Install-Module @installArgs
    $installed = Get-Module -ListAvailable -Name $module.Name | Where-Object {
        if ($module.RequiredVersion) { $_.Version -eq [Version]$module.RequiredVersion }
        else { $_.Version -ge [Version]$module.MinimumVersion }
    } | Sort-Object -Property Version -Descending | Select-Object -First 1
    if (-not $installed) { throw 'The configured module version is unavailable after installation.' }
    Write-Output ('Installed {0} {1}.' -f $module.Name, $installed.Version)
}

Write-Output ''
Write-Output 'Environment variables the appliance-facing scripts read:'
Write-Output '  LE_BASE_URL     Appliance base URL, for example https://appliance.example.test'
Write-Output '  LE_API_TOKEN    System access token with a read-tests and start-tests role'
Write-Output ''
Write-Output 'Optional:'
Write-Output '  LE_TEST_NAME       Exact application test name, used by the integration tests'
Write-Output '  LE_SKIP_CERT_CHECK Keep false and configure trusted appliance TLS'
Write-Output '  LEGATE_LOG_FORMAT  Set to json for one JSON object per log line'
Write-Output ''

$state = @{
    LE_BASE_URL  = -not [string]::IsNullOrWhiteSpace($env:LE_BASE_URL)
    LE_API_TOKEN = -not [string]::IsNullOrWhiteSpace($env:LE_API_TOKEN)
}
foreach ($name in ($state.Keys | Sort-Object)) {
    $status = 'not set'
    if ($state[$name]) { $status = 'set' }
    Write-Output ('  {0}: {1}' -f $name, $status)
}
Write-Output ''
Write-Output 'Set them for this session with $env:LE_BASE_URL = "..." and $env:LE_API_TOKEN = "...". Never put the token in a file in this repo.'
Write-Output 'Next: .\scripts\Invoke-Lint.ps1, .\tests\Invoke-Tests.ps1, then .\scripts\Invoke-Smoke.ps1'
