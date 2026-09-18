function Get-LEGateTimestamp {
    <# .SYNOPSIS
    Supplies the centralized UTC clock to script entrypoints.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()
    return ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
}
