function Test-LEGateInstallerIdle {
    <# .SYNOPSIS
    Evaluates read-only Windows Installer observations without equating process presence with activity.
    #>
    [CmdletBinding()]
    param([AllowNull()][object]$Status)
    if ($null -eq $Status -or $Status.querySucceeded -isnot [bool] -or -not $Status.querySucceeded -or
        $Status.inProgressRegistry -isnot [bool] -or $Status.inProgressRegistry -or
        $Status.processIds -isnot [Collections.IList]) { return $false }
    $ids = @($Status.processIds)
    if ($Status.state -ceq 'Stopped' -and $ids.Count -eq 0 -and $Status.serviceProcessId -eq 0) { return $true }
    return ($Status.state -ceq 'Running' -and $Status.acceptStop -is [bool] -and $Status.acceptStop -and
        $Status.serviceProcessId -gt 0 -and $ids.Count -eq 1 -and $ids[0] -eq $Status.serviceProcessId)
}
