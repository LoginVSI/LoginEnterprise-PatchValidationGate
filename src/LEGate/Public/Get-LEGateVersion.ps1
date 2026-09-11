function Get-LEGateVersion {
    <#
    .SYNOPSIS
        Reads the appliance version. GET /system/version.
    .DESCRIPTION
        The first real call against an appliance and the cheapest way to prove the
        base URL, token, and API version are right. Returns the object the appliance
        sends, which carries currentVersion and latestVersion.
    .PARAMETER Session
        Session from Connect-LEGate.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session
    )

    $version = Invoke-LEGateRequest -Session $Session -Method GET -Path '/system/version'
    Write-LEGateLog -Level Info -Message 'Appliance version' -Fields @{ currentVersion = $version.currentVersion; latestVersion = $version.latestVersion }
    return $version
}
