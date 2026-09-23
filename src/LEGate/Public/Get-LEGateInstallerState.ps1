function Get-LEGateInstallerState {
    <# .SYNOPSIS
    Reads Windows Installer service/process state without starting or stopping anything.
    .DESCRIPTION
    A resident msiexec service may be idle. Reads service accepted controls, PID,
    client processes and in-progress state. Unknown observations fail closed.
    This is an observation, not a reservation; retain exclusive target ownership.
    .PARAMETER Target
    Windows target hostname. With Local, used only as the caller's target label.
    .PARAMETER TargetTransport
    HTTP compatibility or HTTPS with normal certificate validation.
    .PARAMETER TargetPort
    Explicit WSMan port, defaulting to the selected transport's standard port.
    .PARAMETER Credential
    Explicit Windows remoting credential.
    .PARAMETER UseCurrentCredentials
    Deliberately use the process identity.
    .PARAMETER Local
    Read this Windows computer without remoting.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidatePattern('^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$')][string]$Target,
        [ValidateSet('HTTP', 'HTTPS')][string]$TargetTransport = 'HTTP',
        [ValidateRange(1, 65535)][int]$TargetPort = $(if ($TargetTransport -eq 'HTTPS') { 5986 } else { 5985 }),
        [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local
    )
    if (($Credential -and $UseCurrentCredentials) -or (-not $Credential -and -not $UseCurrentCredentials)) { throw 'Choose explicit credentials or deliberate current credentials.' }
    if ($Local -and $Credential) { throw 'Local queries use current credentials.' }
    $query = {
        $ErrorActionPreference = 'Stop'
        $result = [ordered]@{ querySucceeded = $false; state = $null; acceptStop = $null; serviceProcessId = $null; processIds = @(); inProgressRegistry = $null }
        try {
            $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='msiserver'" -ErrorAction Stop
            $processes = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='msiexec.exe'" -ErrorAction Stop)
            if (@($service).Count -ne 1) { throw 'Service identity unavailable.' }
            $result.state = [string]$service.State
            $result.acceptStop = [bool]$service.AcceptStop
            $result.serviceProcessId = [int]$service.ProcessId
            $result.processIds = @($processes | ForEach-Object { [int]$_.ProcessId })
            $result.inProgressRegistry = Test-Path -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\InProgress' -ErrorAction Stop
            $result.querySucceeded = $true
        }
        catch { $result.querySucceeded = $false }
        [pscustomobject]$result
    }
    if ($Local) { $observed = & $query }
    else {
        $requestArgs = @{ ComputerName = $Target; UseSSL = ($TargetTransport -eq 'HTTPS'); Port = $TargetPort; Authentication = 'Negotiate'; ScriptBlock = $query; AsJob = $true; ErrorAction = 'Stop' }
        if ($Credential) { $requestArgs.Credential = $Credential }
        $job = Invoke-Command @requestArgs
        try {
            if (-not (Wait-Job -Job $job -Timeout 120)) { Stop-Job -Job $job; throw 'Installer state query timed out.' }
            $observed = Receive-Job -Job $job -ErrorAction Stop
            if ($job.State -ne 'Completed' -or @($observed).Count -ne 1) { throw 'Incomplete installer state observation.' }
        }
        finally { Remove-Job -Job $job -Force }
    }
    $observed | Add-Member -NotePropertyName safeToInstall -NotePropertyValue (Test-LEGateInstallerIdle -Status $observed) -Force
    return $observed
}
