function Test-LEGateChangeManifest {
    <# .SYNOPSIS
    Rejects unconfigured or unsafe lab installer manifests before target mutation.
    #>
    [CmdletBinding()]
    param([object]$Manifest, [ValidateSet('app-update', 'break', 'noop')][string]$Adapter)
    if ($null -eq $Manifest -or $Manifest.manifestVersion -ne '1') { throw 'Invalid change manifest version.' }
    if ($Adapter -eq 'noop') {
        if ($Manifest.kind -ne 'noop') { throw 'Noop requires a noop manifest.' }
        return $true
    }
    if ($Manifest.kind -ne 'pinned-msi' -or $Manifest.application -notin @('7zip', 'notepadpp')) { throw 'Only configured demo-app MSI manifests are supported.' }
    if ($Manifest.installDirectory -notmatch '^C:\\LEGateDemo\\[A-Za-z0-9_-]+$' -or
        $Manifest.executable -notin @('7zFM.exe', 'notepad++.exe') -or
        $Manifest.directoryProperty -notin @('INSTALLDIR', 'TARGETDIR')) { throw 'Installer paths/properties must target a dedicated C:\LEGateDemo app directory.' }
    if (($Manifest.application -eq '7zip' -and $Manifest.executable -ne '7zFM.exe') -or
        ($Manifest.application -eq 'notepadpp' -and $Manifest.executable -ne 'notepad++.exe')) { throw 'Application/executable mismatch.' }
    foreach ($package in @($Manifest.before, $Manifest.after)) {
        $uri = $null
        if ($null -eq $package -or -not [Uri]::TryCreate([string]$package.url, [UriKind]::Absolute, [ref]$uri) -or
            $uri.Scheme -ne 'https' -or $uri.UserInfo -or $uri.Fragment -or $package.url -match 'REPLACE|CONFIGURE|example' -or
            $package.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or $package.sha256 -match '^0+$' -or
            $package.productCode -notmatch '^\{[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}\}$' -or
            $package.version -notmatch '^\d+(\.\d+){1,3}$') { throw 'Installer provenance, checksum, product code and version must be configured.' }
    }
    if ($Manifest.before.version -eq $Manifest.after.version) { throw 'Before and after versions must differ.' }
    return $true
}
