function Assert-LEGateIdentifier {
    <# .SYNOPSIS
    Rejects identifiers that are unsafe in paths, URLs, or workflow outputs.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$Value)
    if ($Value -notmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$' -or $Value -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$') {
        throw 'Invalid identifier. Use 1-100 ASCII letters, digits, underscores or hyphens.'
    }
}
