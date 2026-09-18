<# .SYNOPSIS
Materializes optional private workflow config into fixed ignored repository paths.
#>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$root = Split-Path -Path $PSScriptRoot -Parent
$inputs = @{
    'policies/demo.local.json' = $env:LE_POLICY_JSON
    'examples/changes/demo.local.json' = $env:LE_CHANGE_JSON
    'config/response-profile.local.json' = $env:LE_RESPONSE_PROFILE_JSON
}
foreach ($relative in $inputs.Keys) {
    if ($inputs[$relative]) {
        try {
            $null = ConvertFrom-Json -InputObject $inputs[$relative]
            $path = Join-Path -Path $root -ChildPath $relative
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path)) | Out-Null
            [IO.File]::WriteAllText($path, $inputs[$relative], (New-Object Text.UTF8Encoding($false)))
        }
        catch { Write-Output 'Private workflow configuration is invalid.'; exit 2 }
    }
}
