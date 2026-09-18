function Get-LEGateResultList {
    <# .SYNOPSIS
    Applies an explicit list profile to a documented results endpoint.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$Path, [hashtable]$Query, [object]$ListProfile, [string]$CaptureRoot)
    $requestArgs = @{ Session = $Session; Path = $Path; Query = $Query; CaptureRoot = $CaptureRoot }
    if ($ListProfile) {
        $requestArgs.Envelope = $ListProfile.envelope
        $requestArgs.ArrayTerminationConfirmed = $ListProfile.arrayTerminationConfirmed -eq $true
    }
    return Get-LEGateAllPages @requestArgs
}
