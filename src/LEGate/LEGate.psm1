# LEGate: thin PowerShell wrapper over the Login Enterprise Public API.
# Functions live in Public\*.ps1 and are dot-sourced here. PowerShell 5.1 compatible.
Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter *.ps1 -ErrorAction SilentlyContinue |
    ForEach-Object { . $_.FullName }