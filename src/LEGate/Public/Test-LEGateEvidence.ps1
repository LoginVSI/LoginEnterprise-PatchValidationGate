function Test-LEGateEvidence {
    <# .SYNOPSIS
    Verifies manifest identity, paths, exact bytes and absence of unlisted files.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path, [string]$ExpectedManifestHash)
    $manifestPath = Resolve-LEGatePath -Root $Path -RelativePath 'manifest.json'
    $hash = Get-LEGateHash -Path $manifestPath
    $sidecar = (Get-Content -LiteralPath (Resolve-LEGatePath -Root $Path -RelativePath 'manifest.sha256') -Raw).Trim()
    if ($hash -cne $sidecar -or ($ExpectedManifestHash -and $hash -cne $ExpectedManifestHash)) { throw 'Evidence manifest hash mismatch.' }
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    if ($manifest.manifestVersion -ne '1' -or $manifest.files -isnot [array]) { throw 'Unsupported evidence manifest.' }
    $seen = @{}
    foreach ($entry in $manifest.files) {
        if ($seen.ContainsKey($entry.path) -or $entry.path -in @('manifest.json', 'manifest.sha256')) { throw 'Duplicate or circular manifest entry.' }
        $safe = Resolve-LEGatePath -Root $Path -RelativePath $entry.path
        if (-not (Test-Path -LiteralPath $safe -PathType Leaf) -or $entry.sha256 -notmatch '^[a-f0-9]{64}$' -or
            (Get-Item -Force -LiteralPath $safe).Length -ne $entry.bytes -or (Get-LEGateHash -Path $safe) -cne $entry.sha256) { throw 'Evidence file integrity mismatch.' }
        $seen[$entry.path] = $true
    }
    foreach ($required in @('verdict.json', 'summary.md')) { if (-not $seen.ContainsKey($required)) { throw 'Required evidence file missing.' } }
    if (@(Get-ChildItem -Force -LiteralPath $Path -Recurse -File).Count -ne ($seen.Count + 2)) { throw 'Unlisted evidence file.' }
    $verdict = Get-Content -LiteralPath (Resolve-LEGatePath -Root $Path -RelativePath 'verdict.json') -Raw | ConvertFrom-Json
    if ($verdict.verdict -notin @('PASS', 'FAIL', 'INCONCLUSIVE') -or $verdict.changeId -cne $manifest.changeId -or
        $verdict.testRunId -cne $manifest.testRun.id -or $verdict.policyHash -cne $manifest.policy.hash) { throw 'Verdict and manifest disagree.' }
    return [pscustomobject]@{ valid = $true; manifest = $manifest; verdict = $verdict; manifestSha256 = $hash }
}
