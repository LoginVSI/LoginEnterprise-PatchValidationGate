function Get-LEGateTargetSessionOption {
    <# .SYNOPSIS
    Applies an explicit WSMan proxy choice without relaxing transport security.
    .DESCRIPTION
    An unset LE_TARGET_PROXY_ACCESS_TYPE preserves the platform default. This
    setting affects target remoting only, not appliance or installer HTTPS.
    #>
    [CmdletBinding()]
    param()
    $proxy = $env:LE_TARGET_PROXY_ACCESS_TYPE
    if ([string]::IsNullOrWhiteSpace($proxy)) { return }
    if ($proxy -cnotin @('IEConfig', 'WinHttpConfig', 'AutoDetect', 'NoProxyServer')) { throw 'Unsupported target proxy access type.' }
    return New-PSSessionOption -ProxyAccessType $proxy -OpenTimeout 30000 -MaxConnectionRetryCount 0 -MaximumRedirection 0
}
