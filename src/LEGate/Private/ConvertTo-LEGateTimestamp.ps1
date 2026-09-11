function ConvertTo-LEGateTimestamp {
    <#
    .SYNOPSIS
        Formats a DateTime as a UTC ISO 8601 string.
    .DESCRIPTION
        All timestamps the module produces use this format: yyyy-MM-ddTHH:mm:ss.fffZ.
        Local times are converted to UTC first. Unspecified kinds are treated as UTC,
        because everything the module creates comes from Get-LEGateUtcNow.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [DateTime]$Value
    )

    process {
        if ($Value.Kind -eq [DateTimeKind]::Unspecified) {
            $Value = [DateTime]::SpecifyKind($Value, [DateTimeKind]::Utc)
        }
        return $Value.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ', [System.Globalization.CultureInfo]::InvariantCulture)
    }
}
