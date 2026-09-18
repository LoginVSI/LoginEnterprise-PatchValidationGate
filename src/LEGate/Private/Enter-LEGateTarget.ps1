function Enter-LEGateTarget {
    <# .SYNOPSIS
    Takes a cross-process file lock in an operator-managed shared state directory.
    #>
    [CmdletBinding()]
    param([string]$StateRoot, [string]$Target)
    [IO.Directory]::CreateDirectory($StateRoot) | Out-Null
    $key = Get-LEGateTextHash -Text $Target.ToLowerInvariant()
    $path = Resolve-LEGatePath -Root $StateRoot -RelativePath ($key + '.lock')
    try { $stream = [IO.File]::Open($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None) }
    catch { throw 'Target is locked by another operation.' }
    return [pscustomobject]@{ stream = $stream; leasePath = (Resolve-LEGatePath -Root $StateRoot -RelativePath ($key + '.json')) }
}
