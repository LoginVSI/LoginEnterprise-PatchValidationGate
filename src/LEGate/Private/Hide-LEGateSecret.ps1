function Hide-LEGateSecret {
    <#
    .SYNOPSIS
        Removes known secrets and bearer tokens from a string.
    .DESCRIPTION
        Connect-LEGate registers the API token in the module's secret list. This
        function replaces every registered secret with [REDACTED] and also masks
        anything that looks like a bearer token, so text that came from an exception
        or a raw HTTP header is safe to log. Write-LEGateLog and Invoke-LEGateRequest
        both route their output through here.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Text
    )

    process {
        if ([string]::IsNullOrEmpty($Text)) {
            return $Text
        }

        $result = $Text
        foreach ($secret in @($script:LEGateSecrets)) {
            if (-not [string]::IsNullOrEmpty($secret)) {
                $result = $result.Replace($secret, '[REDACTED]')
            }
        }

        $result = [regex]::Replace($result, '(?i)bearer\s+(?!\[REDACTED\])\S+', 'Bearer [REDACTED]')
        return $result
    }
}
