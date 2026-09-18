function Read-LEGatePolicy {
    <# .SYNOPSIS
    Reads and validates policy bytes only from a relative path inside the repository.
    #>
    [CmdletBinding()]
    param([string]$RepositoryRoot, [string]$RelativePath)
    $path = Resolve-LEGatePath -Root $RepositoryRoot -RelativePath $RelativePath
    $policy = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    if (-not (Test-LEGatePolicyDefinition -Policy $policy).valid) { throw 'Unsupported or unconfigured policy.' }
    return [pscustomobject]@{ policy = $policy; hash = 'sha256:' + (Get-LEGateHash -Path $path) }
}
