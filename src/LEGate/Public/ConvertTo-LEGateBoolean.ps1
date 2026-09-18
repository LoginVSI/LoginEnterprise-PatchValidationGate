function ConvertTo-LEGateBoolean {
    <# .SYNOPSIS
    Parses an explicit certificate/configuration flag consistently in both shells.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param([AllowNull()][AllowEmptyString()][string]$Value)
    switch ($Value.ToLowerInvariant()) {
        { $_ -in @('', '0', 'false') } { return $false }
        { $_ -in @('1', 'true') } { return $true }
        default { throw 'Boolean setting must be empty, 0, 1, false, or true.' }
    }
}
