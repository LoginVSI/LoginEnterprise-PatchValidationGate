function Resolve-LEGatePath {
    <# .SYNOPSIS
    Resolves a relative path under a root and rejects traversal and reparse points.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory = $true)][string]$Root, [Parameter(Mandatory = $true)][string]$RelativePath)
    if ([IO.Path]::IsPathRooted($RelativePath) -or $RelativePath -match '(^|[\\/])\.\.([\\/]|$)|[:\x00-\x1f]' -or $RelativePath -match '[*?]') {
        throw 'Unsafe relative path.'
    }
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $full = [IO.Path]::GetFullPath((Join-Path -Path $base -ChildPath $RelativePath))
    if (-not $full.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) { throw 'Path escapes root.' }
    $cursor = $full
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -Force -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse points are not allowed.' }
        }
        $parent = [IO.Path]::GetDirectoryName($cursor)
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}
