function Write-LEGateLog {
    <#
    .SYNOPSIS
        The one logging function every LEGate function uses.
    .DESCRIPTION
        Writes a log line with a level, a message, and optional structured fields.
        Nothing in the module calls Write-Host or Write-Verbose directly.

        Text mode writes Debug to the verbose stream, Warn to the warning stream,
        and Info and Error to the information stream. JSON mode writes one JSON
        object per line to the information stream regardless of level, so a
        pipeline can capture a single stream and parse it.

        JSON mode is on when -AsJson is passed or when the environment variable
        LEGATE_LOG_FORMAT is set to json.

        Every line, in both modes, passes through Hide-LEGateSecret before it is
        written. Timestamps are UTC ISO 8601.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('Debug', 'Info', 'Warn', 'Error')]
        [string]$Level,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [string]$Message,

        [Parameter(Position = 2)]
        [hashtable]$Fields,

        [switch]$AsJson
    )

    $useJson = $AsJson.IsPresent -or ($env:LEGATE_LOG_FORMAT -eq 'json')
    $timestamp = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)

    if ($useJson) {
        $record = [ordered]@{
            timestamp = $timestamp
            level     = $Level.ToLowerInvariant()
            message   = $Message
        }
        if ($Fields) {
            foreach ($key in $Fields.Keys) {
                if (-not $record.Contains($key)) {
                    $record[$key] = $Fields[$key]
                }
            }
        }
        $line = Hide-LEGateSecret -Text (ConvertTo-Json -InputObject $record -Compress -Depth 5)
        Write-Information -MessageData $line -InformationAction Continue
        return
    }

    $suffix = ''
    if ($Fields -and $Fields.Count -gt 0) {
        $pairs = foreach ($key in ($Fields.Keys | Sort-Object)) {
            $value = $Fields[$key]
            if ($null -eq $value) { $value = '' }
            elseif ($value -is [DateTime]) { $value = ConvertTo-LEGateTimestamp -Value $value }
            elseif (-not ($value -is [string] -or $value -is [ValueType])) { $value = ConvertTo-Json -InputObject $value -Compress -Depth 5 }
            '{0}={1}' -f $key, $value
        }
        $suffix = ' ' + ($pairs -join ' ')
    }

    $line = Hide-LEGateSecret -Text ('{0} [{1}] {2}{3}' -f $timestamp, $Level.ToUpperInvariant(), $Message, $suffix)

    switch ($Level) {
        'Debug' { Write-Verbose -Message $line }
        'Warn' { Write-Warning -Message $line }
        default { Write-Information -MessageData $line -InformationAction Continue }
    }
}
