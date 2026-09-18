function Write-LEGateJson {
    <# .SYNOPSIS
    Writes UTF-8 JSON atomically; callers decide whether the content is private.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][AllowNull()][object]$Value)
    $parent = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Path))
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    $temp = $Path + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    [IO.File]::WriteAllText($temp, (ConvertTo-Json -InputObject $Value -Depth 80), (New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination $Path -Force
}
