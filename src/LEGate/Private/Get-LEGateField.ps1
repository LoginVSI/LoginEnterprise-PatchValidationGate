function Get-LEGateField {
    <# .SYNOPSIS
    Reads a configured dot-separated property selector, without evaluating code.
    #>
    [CmdletBinding()]
    param([AllowNull()][object]$Value, [Parameter(Mandatory = $true)][string]$Selector)
    if ($Selector -eq '$') { return , $Value }
    if ($Selector -notmatch '^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)*$') { throw 'Invalid response selector.' }
    $current = $Value
    foreach ($segment in $Selector.Split('.')) {
        if ($null -eq $current -or $null -eq $current.PSObject.Properties[$segment]) { throw 'Configured response field is missing.' }
        $current = $current.$segment
    }
    return , $current
}
