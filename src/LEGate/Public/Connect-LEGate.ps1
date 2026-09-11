function Connect-LEGate {
    <#
    .SYNOPSIS
        Builds a session object for the Login Enterprise Public API.
    .DESCRIPTION
        Reads LE_BASE_URL and LE_API_TOKEN from the environment unless -BaseUrl and
        -ApiToken override them. Nothing is sent to the appliance here; the first real
        call is Get-LEGateVersion.

        The token is kept as a SecureString on the session and registered with the
        module's redaction list, so it never shows up in log lines or error text.

        -SkipCertificateCheck is for lab appliances with self-signed certificates. On
        Windows PowerShell 5.1 it installs a process-wide certificate validation
        callback, because Invoke-RestMethod has no -SkipCertificateCheck switch there.
        On PowerShell 7 the switch is passed through per request instead.
    .PARAMETER BaseUrl
        Appliance base URL, for example https://appliance.example.test. Defaults to LE_BASE_URL.
    .PARAMETER ApiToken
        System access token. Defaults to LE_API_TOKEN.
    .PARAMETER ApiVersion
        Public API version segment. Defaults to v8-preview. See docs/api-notes.md.
    .PARAMETER SkipCertificateCheck
        Trust the appliance certificate without validation. Lab use only.
    .OUTPUTS
        PSCustomObject with PSTypeName LEGate.Session.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$BaseUrl,

        [string]$ApiToken,

        [ValidatePattern('^[A-Za-z0-9.-]+$')]
        [string]$ApiVersion = 'v8-preview',

        [switch]$SkipCertificateCheck
    )

    if ([string]::IsNullOrWhiteSpace($BaseUrl)) { $BaseUrl = $env:LE_BASE_URL }
    if ([string]::IsNullOrWhiteSpace($ApiToken)) { $ApiToken = $env:LE_API_TOKEN }

    if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
        throw 'No base URL. Set LE_BASE_URL or pass -BaseUrl.'
    }
    if ([string]::IsNullOrWhiteSpace($ApiToken)) {
        throw 'No API token. Set LE_API_TOKEN or pass -ApiToken.'
    }

    $BaseUrl = $BaseUrl.Trim().TrimEnd('/')
    $parsed = $null
    if (-not [Uri]::TryCreate($BaseUrl, [UriKind]::Absolute, [ref]$parsed) -or $parsed.Scheme -notin @('http', 'https')) {
        throw ('Base URL is not an absolute http or https URL: {0}' -f $BaseUrl)
    }

    # Register the token for redaction before anything can log it.
    if (-not ($script:LEGateSecrets -contains $ApiToken)) {
        $script:LEGateSecrets += $ApiToken
    }

    $secureToken = New-Object System.Security.SecureString
    foreach ($char in $ApiToken.ToCharArray()) { $secureToken.AppendChar($char) }
    $secureToken.MakeReadOnly()

    # Windows PowerShell 5.1 defaults can exclude TLS 1.2 on older builds.
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

    $nativeSkip = (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck')
    if ($SkipCertificateCheck.IsPresent -and -not $nativeSkip) {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { param($senderObject, $certificate, $chain, $sslPolicyErrors) $true }
        Write-LEGateLog -Level Warn -Message 'Certificate validation disabled for this process'
    }

    $session = [PSCustomObject]@{
        PSTypeName           = 'LEGate.Session'
        BaseUrl              = $BaseUrl
        ApiVersion           = $ApiVersion
        Token                = $secureToken
        SkipCertificateCheck = [bool]$SkipCertificateCheck.IsPresent
        ConnectedAt          = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
    }

    Write-LEGateLog -Level Info -Message 'Session created' -Fields @{ baseUrl = $BaseUrl; apiVersion = $ApiVersion; skipCertificateCheck = $session.SkipCertificateCheck }
    return $session
}
