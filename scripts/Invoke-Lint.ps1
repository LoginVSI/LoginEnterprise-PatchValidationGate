<#
.SYNOPSIS
    Runs PSScriptAnalyzer over the repo with the settings at the root.
.DESCRIPTION
    Lints src, scripts, and tests using PSScriptAnalyzerSettings.psd1. Prints every
    finding and exits 1 when any Error or Warning is reported, so CI and a pre-commit
    hook can both call it.
.PARAMETER Path
    Folders or files to lint. Defaults to src, scripts, and tests.
.EXAMPLE
    .\scripts\Invoke-Lint.ps1
#>
[CmdletBinding()]
param(
    [string[]]$Path
)

$ErrorActionPreference = 'Stop'

if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
    Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
}
else {
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $moduleRoot = Join-Path -Path $documents -ChildPath 'WindowsPowerShell/Modules/PSScriptAnalyzer'
    $installed = Get-ChildItem -LiteralPath $moduleRoot -Filter PSScriptAnalyzer.psd1 -Recurse -ErrorAction Stop | Sort-Object -Property FullName -Descending | Select-Object -First 1
    if (-not $installed) { throw 'PSScriptAnalyzer is unavailable. Run Initialize-DevEnvironment in the intended shell.' }
    Import-Module -Name $installed.FullName -ErrorAction Stop
}

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$rootSettings = Join-Path -Path $repoRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'
$testSettings = Join-Path -Path $repoRoot -ChildPath 'tests\PSScriptAnalyzerSettings.psd1'
$testsFolder = Join-Path -Path $repoRoot -ChildPath 'tests'

if (-not $Path) {
    $Path = @('src', 'scripts', 'tests', 'adapters') | ForEach-Object { Join-Path -Path $repoRoot -ChildPath $_ }
}

$findings = @()
foreach ($target in $Path) {
    # Test files get their own settings because Pester scoping confuses two rules.
    $settings = $rootSettings
    $resolved = (Resolve-Path -Path $target).Path
    if ($resolved.StartsWith($testsFolder, [System.StringComparison]::OrdinalIgnoreCase)) {
        $settings = $testSettings
    }
    $findings += @(Invoke-ScriptAnalyzer -Path $target -Recurse -Settings $settings)
}

if ($findings.Count -eq 0) {
    Write-Output 'PSScriptAnalyzer: no findings.'
    exit 0
}

$findings |
    Sort-Object -Property Severity, ScriptPath, Line |
    Format-Table -Property Severity, RuleName, @{ Name = 'File'; Expression = { $_.ScriptPath.Replace($repoRoot, '').TrimStart('\') } }, Line, Message -AutoSize -Wrap |
    Out-String -Width 220 |
    Write-Output

$blocking = @($findings | Where-Object { $_.Severity -in @('Error', 'Warning') })
Write-Output ('PSScriptAnalyzer: {0} finding(s), {1} blocking.' -f $findings.Count, $blocking.Count)

if ($blocking.Count -gt 0) { exit 1 }
exit 0
