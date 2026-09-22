function Invoke-LEGateChangeAdapter {
    <# .SYNOPSIS
    Calls one allowlisted adapter operation and returns its contract result.
    .DESCRIPTION
    Target remoting uses Negotiate with normal certificate validation for HTTPS.
    The same transport and port must be used for apply, verify and restoration.
    .PARAMETER TargetTransport
    HTTP (compatibility default) or HTTPS. Independent of appliance TLS settings.
    .PARAMETER TargetPort
    Target WSMan port. Defaults to 5985 for HTTP or 5986 for HTTPS.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet('apply', 'verify', 'revert')][string]$Operation,
        [ValidateSet('app-update', 'break', 'noop')][string]$Adapter,
        [string]$ChangeId, [string]$Target, [object]$Parameters,
        [ValidateSet('HTTP', 'HTTPS')][string]$TargetTransport = 'HTTP',
        [ValidateRange(1, 65535)][int]$TargetPort = $(if ($TargetTransport -eq 'HTTPS') { 5986 } else { 5985 }),
        [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local,
        [ValidateRange(10, 3600)][int]$TimeoutSeconds = 600
    )
    Assert-LEGateIdentifier -Value $ChangeId
    if (-not $Target -or $Target -notmatch '^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$') { throw 'Invalid target.' }
    if (($Credential -and $UseCurrentCredentials) -or (-not $Credential -and -not $UseCurrentCredentials)) { throw 'Choose explicit credentials or deliberate current credentials.' }
    if ($Local -and $Credential) { throw 'Local execution uses current credentials only.' }
    $null = Test-LEGateChangeManifest -Manifest $Parameters -Adapter $Adapter
    $started = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
    $status = 'skipped'; $details = @{}
    if ($PSCmdlet.ShouldProcess('configured lab target', $Operation)) {
        try {
            if ($Adapter -eq 'noop') { $status = 'succeeded'; $details = @{ noop = $true; restored = ($Operation -eq 'revert') } }
            elseif ($Local) { $result = Invoke-LEGateAdapterWorker -Operation $Operation -Adapter $Adapter -Manifest $Parameters -TimeoutSeconds $TimeoutSeconds; $status = $result.status; $details = $result.details }
            else {
                $block = (Get-Command -Name Invoke-LEGateAdapterWorker).ScriptBlock
                $requestArgs = @{ ComputerName = $Target; ScriptBlock = $block; ArgumentList = @($Operation, $Adapter, $Parameters, $TimeoutSeconds); AsJob = $true; ErrorAction = 'Stop'; UseSSL = ($TargetTransport -eq 'HTTPS'); Port = $TargetPort; Authentication = 'Negotiate' }
                if ($Credential) { $requestArgs.Credential = $Credential }
                $job = Invoke-Command @requestArgs
                try {
                    if (-not (Wait-Job -Job $job -Timeout ($TimeoutSeconds * 3 + 30))) { Stop-Job -Job $job; throw 'Remote adapter timeout.' }
                    $result = Receive-Job -Job $job -ErrorAction Stop
                    if ($job.State -ne 'Completed' -or @($result).Count -ne 1 -or $result.status -notin @('succeeded', 'skipped')) { throw 'Invalid remote adapter result.' }
                    $status = $result.status; $details = $result.details
                }
                finally { Remove-Job -Job $job -Force }
            }
        }
        catch { $status = 'failed'; $details = @{ code = 'adapter-operation-failed'; recoveryRequired = $true; message = Hide-LEGateSecret -Text $_.Exception.Message } }
    }
    return [pscustomobject][ordered]@{
        status = $status; changeId = $ChangeId; operation = $Operation; target = $Target
        details = $details; startedAt = $started; finishedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
    }
}
