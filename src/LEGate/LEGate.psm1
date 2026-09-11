# LEGate: thin PowerShell wrapper over the Login Enterprise Public API.
# One function per file. Private\*.ps1 are helpers and stay inside the module.
# Public\*.ps1 are exported. PowerShell 5.1 compatible.

Set-StrictMode -Version 1.0

# Secrets registered by Connect-LEGate. Hide-LEGateSecret redacts these from every
# log line and error message. In-memory only, never written anywhere.
$script:LEGateSecrets = @()

$privateFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
$publicFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Public'

foreach ($file in @(Get-ChildItem -Path $privateFolder -Filter *.ps1 -ErrorAction SilentlyContinue)) {
    . $file.FullName
}

$publicFunctions = @()
foreach ($file in @(Get-ChildItem -Path $publicFolder -Filter *.ps1 -ErrorAction SilentlyContinue)) {
    . $file.FullName
    $publicFunctions += $file.BaseName
}

Export-ModuleMember -Function $publicFunctions
