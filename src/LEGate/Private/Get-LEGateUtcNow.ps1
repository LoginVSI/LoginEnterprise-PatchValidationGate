function Get-LEGateUtcNow {
    <#
    .SYNOPSIS
        Returns the current time in UTC.
    .DESCRIPTION
        Every time check in the module goes through this function so tests can
        mock the clock instead of waiting for real minutes to pass.
    #>
    [CmdletBinding()]
    [OutputType([DateTime])]
    param()

    return [DateTime]::UtcNow
}
