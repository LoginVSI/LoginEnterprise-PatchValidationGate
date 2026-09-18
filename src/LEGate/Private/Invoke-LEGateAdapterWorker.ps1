function Invoke-LEGateAdapterWorker {
    <# .SYNOPSIS
    Executes the bounded app-only operation locally; also serialized to WinRM.
    #>
    [CmdletBinding()]
    param([string]$Operation, [string]$Adapter, [object]$Manifest, [int]$TimeoutSeconds)
    $root = [IO.Path]::GetFullPath($Manifest.installDirectory)
    $ancestor = $root
    while ($ancestor) {
        if ((Test-Path -LiteralPath $ancestor) -and ((Get-Item -Force -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe app directory ancestor.' }
        $ancestor = Split-Path -Path $ancestor -Parent
    }
    [IO.Directory]::CreateDirectory($root) | Out-Null
    if ((Get-Item -Force -LiteralPath $root).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Unsafe app directory.' }
    $exe = Join-Path -Path $root -ChildPath $Manifest.executable
    $disabled = $exe + '.legate-disabled'
    foreach ($candidate in @($exe, $disabled)) {
        if ((Test-Path -LiteralPath $candidate) -and ((Get-Item -Force -LiteralPath $candidate).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Unsafe executable link.' }
    }
    $after = [string]$Manifest.after.version
    $observed = $null
    if (Test-Path -LiteralPath $exe -PathType Leaf) { $observed = (Get-Item -Force -LiteralPath $exe).VersionInfo.FileVersion }
    if ($Operation -eq 'verify') {
        if ($Adapter -eq 'break') {
            if ((Test-Path -LiteralPath $exe) -or -not (Test-Path -LiteralPath $disabled -PathType Leaf) -or
                (Get-Item -Force -LiteralPath $disabled).VersionInfo.FileVersion -ne $after) { throw 'Intended break is not present.' }
            return @{ status = 'succeeded'; details = @{ brokenStateVerified = $true; version = $after } }
        }
        if ($observed -ne $after) { throw 'Installed version verification failed.' }
        return @{ status = 'succeeded'; details = @{ version = $observed } }
    }
    if ($Operation -eq 'revert' -and (Test-Path -LiteralPath $disabled)) {
        if (Test-Path -LiteralPath $exe) { throw 'Restore collision.' }
        Move-Item -LiteralPath $disabled -Destination $exe
        $observed = (Get-Item -Force -LiteralPath $exe).VersionInfo.FileVersion
    }
    if ($Adapter -eq 'break' -and $Operation -eq 'apply' -and (Test-Path -LiteralPath $disabled)) {
        if ((Test-Path -LiteralPath $exe) -or (Get-Item -Force -LiteralPath $disabled).VersionInfo.FileVersion -ne $after) { throw 'Unexpected disabled executable.' }
        return @{ status = 'skipped'; details = @{ brokenStateVerified = $true; version = $after } }
    }
    $desired = $Manifest.after
    $previous = $Manifest.before
    if ($Operation -eq 'revert') { $desired = $Manifest.before; $previous = $Manifest.after }
    if ($observed -ne $desired.version) {
        if ($observed -ne $previous.version) { throw 'Target version is neither the documented initial nor desired state.' }
        $package = Join-Path -Path $root -ChildPath ('installer-' + $desired.sha256 + '.msi')
        if (-not (Test-Path -LiteralPath $package)) {
            Invoke-WebRequest -Uri $desired.url -OutFile $package -UseBasicParsing -MaximumRedirection 0 -TimeoutSec $TimeoutSeconds -ErrorAction Stop | Out-Null
        }
        if ((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash -ine $desired.sha256) { throw 'Installer checksum mismatch.' }
        $commands = @(
            @('/x', $previous.productCode, '/qn', '/norestart'),
            @('/i', ('"' + $package + '"'), '/qn', '/norestart', ($Manifest.directoryProperty + '="' + $root + '"'))
        )
        foreach ($arguments in $commands) {
            $process = Start-Process -FilePath "$env:SystemRoot\System32\msiexec.exe" -ArgumentList $arguments -PassThru -WindowStyle Hidden
            if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { $process.Kill(); throw 'Installer timeout; target requires recovery.' }
            if ($process.ExitCode -ne 0) { throw 'Installer failed or requires a reboot; recover target before testing.' }
        }
        if (-not (Test-Path -LiteralPath $exe) -or (Get-Item -Force -LiteralPath $exe).VersionInfo.FileVersion -ne $desired.version) { throw 'Post-install version mismatch.' }
    }
    if ($Adapter -eq 'break' -and $Operation -eq 'apply') {
        if (Test-Path -LiteralPath $disabled) { throw 'Break destination exists.' }
        Move-Item -LiteralPath $exe -Destination $disabled
        if ((Test-Path -LiteralPath $exe) -or -not (Test-Path -LiteralPath $disabled)) { throw 'Break did not apply.' }
    }
    return @{ status = 'succeeded'; details = @{ version = $desired.version; restored = ($Operation -eq 'revert'); installerSha256 = $desired.sha256; simulatedProduction = $true } }
}
