<# .SYNOPSIS
Exports a pinned development commit for a single private Actions execution repository.
.DESCRIPTION
Creates local files only. Does not create a GitHub repository, push, register a
runner or dispatch a workflow. Regenerate from the development source to sync.
.PARAMETER Repository
Exact owner/name of the intended private execution repository.
.PARAMETER SourceCommit
Full commit SHA from this development checkout.
.PARAMETER Destination
New directory outside this checkout. Existing output is never overwritten.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')][string]$Repository,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$SourceCommit,
    [Parameter(Mandatory = $true)][string]$Destination
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Path $PSScriptRoot -Parent
$output = [IO.Path]::GetFullPath($Destination)
if ($Repository -ceq 'LoginVSI/LoginEnterprise-PatchValidationGate') { throw 'Choose the intended private execution repository.' }
if ($output.TrimEnd('\', '/') -ieq $root.TrimEnd('\', '/') -or $output.StartsWith($root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Export outside the development checkout.' }
if (Test-Path -LiteralPath $output) { throw 'Destination already exists; preserve it and choose a fresh export.' }
$commit = git -C $root rev-parse --verify ($SourceCommit + '^{commit}')
if ($LASTEXITCODE -ne 0 -or $commit -ine $SourceCommit) { throw 'Source commit is unavailable.' }
$zip = Join-Path ([IO.Path]::GetTempPath()) ('legate-export-' + [guid]::NewGuid().ToString('N') + '.zip')
try {
    git -C $root archive --format=zip ('--output=' + $zip) $SourceCommit
    if ($LASTEXITCODE -ne 0) { throw 'Git archive failed.' }
    Expand-Archive -LiteralPath $zip -DestinationPath $output
    $workflow = Join-Path $output '.github/workflows/validate-patch.yml'
    $text = [IO.File]::ReadAllText($workflow)
    $original = "github.ref == 'refs/heads/main' && github.repository == 'LoginVSI/LoginEnterprise-PatchValidationGate'"
    if ([regex]::Matches($text, [regex]::Escape($original)).Count -ne 1) { throw 'Reviewed source repository/ref guard is absent or ambiguous.' }
    $replacement = "github.ref == 'refs/heads/main' && github.repository == '$Repository'"
    [IO.File]::WriteAllText($workflow, $text.Replace($original, $replacement), (New-Object Text.UTF8Encoding($false)))
    [ordered]@{ sourceRepository = 'LoginVSI/LoginEnterprise-PatchValidationGate'; sourceCommit = $SourceCommit.ToLowerInvariant(); executionRepository = $Repository; allowedRef = 'refs/heads/main'; generatedAt = [DateTime]::UtcNow.ToString('o'); transformation = 'Exact execution-repository guard only; no wildcard or ref relaxation.' } |
        ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'execution-source.json') -Encoding utf8
    Write-Output 'Local execution export prepared. Review before publishing; no GitHub operation was performed.'
}
finally { if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip } }
