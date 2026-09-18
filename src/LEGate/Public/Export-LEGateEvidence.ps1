function Export-LEGateEvidence {
    <# .SYNOPSIS
    Writes a private or publication-projected evidence bundle and byte manifest.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)][object]$Verdict, [Parameter(Mandatory = $true)][object]$Context, [object]$Results, [object]$Adapter)
    [IO.Directory]::CreateDirectory($Path) | Out-Null
    Write-LEGateJson -Path (Resolve-LEGatePath -Root $Path -RelativePath 'verdict.json') -Value $Verdict
    if ($Results) { Write-LEGateJson -Path (Resolve-LEGatePath -Root $Path -RelativePath 'normalized.json') -Value $Results }
    $text = '# Validation evidence' + [Environment]::NewLine + [Environment]::NewLine +
    ('Verdict: **{0}**. Provenance: **{1}**.' -f $Verdict.verdict, $Context.provenance) + [Environment]::NewLine +
    'See verdict.json for the decision, normalized.json for functional evidence, and manifest.json for integrity. Promotion is a separate record.' + [Environment]::NewLine
    [IO.File]::WriteAllText((Resolve-LEGatePath -Root $Path -RelativePath 'summary.md'), $text, (New-Object Text.UTF8Encoding($false)))
    $files = @()
    foreach ($file in @(Get-ChildItem -Force -LiteralPath $Path -Recurse -File | Sort-Object -Property FullName)) {
        $relative = $file.FullName.Substring([IO.Path]::GetFullPath($Path).TrimEnd('\', '/').Length + 1).Replace('\', '/')
        if ($relative -in @('manifest.json', 'manifest.sha256')) { continue }
        $safe = Resolve-LEGatePath -Root $Path -RelativePath $relative
        $kind = 'report'
        if ($relative -eq 'verdict.json') { $kind = 'verdict' }
        elseif ($relative -eq 'summary.md') { $kind = 'summary' }
        elseif ($relative -match 'screenshots/.+\.bin$') { $kind = 'screenshot' }
        elseif ($relative -match 'run.json$') { $kind = 'run' }
        $files += [pscustomobject]@{ path = $relative; kind = $kind; sha256 = Get-LEGateHash -Path $safe; bytes = $file.Length }
    }
    $manifest = [ordered]@{
        manifestVersion = '1'; changeId = $Verdict.changeId; generatedAt = $Context.evaluatedAt
        appliance = @{ apiVersion = $Context.apiVersion; currentVersion = $Context.applianceVersion }
        test = @{ id = $Context.testId; name = $Verdict.testName }
        testRun = @{ id = $Verdict.testRunId; state = $Results.state; result = $Results.result; testRunName = $Verdict.changeId }
        policy = @{ name = $Verdict.policyName; hash = $Verdict.policyHash; path = $Context.policyPath }
        adapter = $Adapter; files = @($files)
        provenance = $Context.provenance; sourceCommit = $Context.sourceCommit
        changeManifestHash = $Context.changeManifestHash; identityHash = $Context.identityHash
        completeness = ($null -ne $Results -and $Results.complete -eq $true -and $Results.integrityValid -eq $true)
        publication = $Context.publication
    }
    $manifestPath = Resolve-LEGatePath -Root $Path -RelativePath 'manifest.json'
    Write-LEGateJson -Path $manifestPath -Value $manifest
    $hash = Get-LEGateHash -Path $manifestPath
    [IO.File]::WriteAllText((Resolve-LEGatePath -Root $Path -RelativePath 'manifest.sha256'), $hash, (New-Object Text.UTF8Encoding($false)))
    return [pscustomobject]@{ path = [IO.Path]::GetFullPath($Path); manifestSha256 = $hash; verdict = $Verdict.verdict }
}
