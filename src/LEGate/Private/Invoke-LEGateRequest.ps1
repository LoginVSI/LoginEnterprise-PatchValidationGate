function Invoke-LEGateRequest {
    <#
    .SYNOPSIS
        Sends one request to the Login Enterprise Public API.
    .DESCRIPTION
        Thin wrapper over Invoke-RestMethod. Builds {baseUrl}/publicApi/{apiVersion}{path},
        adds the bearer token from the session, and returns whatever the appliance sent
        back as parsed JSON.

        GET requests are retried on 5xx responses and transport errors, three attempts
        with a short backoff. PUT, POST, and everything else run exactly once, because
        a retried write could start a second test run.

        On a non-retryable failure the function throws a System.Exception whose message
        includes the HTTP status and the ProblemDetails title and detail when the
        appliance sent them. The status code, title, and detail are also available on
        the exception's Data dictionary under LEGate.StatusCode, LEGate.Title, and
        LEGate.Detail so callers can branch on them without parsing text.

        The token never appears in log output or error text. Everything passes through
        Hide-LEGateSecret first.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'PUT', 'POST', 'DELETE', 'PATCH')]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^/')]
        [string]$Path,

        [hashtable]$Query,

        [object]$Body,

        [ValidateRange(1, 10)]
        [int]$MaxAttempts = 3,

        [ValidateRange(0, 300)]
        [int]$TimeoutSeconds = 60
    )

    $uri = '{0}/publicApi/{1}{2}' -f $Session.BaseUrl, $Session.ApiVersion, $Path
    if ($Query -and $Query.Count -gt 0) {
        $pairs = foreach ($key in ($Query.Keys | Sort-Object)) {
            $value = $Query[$key]
            if ($null -eq $value) { continue }
            if ($value -is [bool]) { $value = $value.ToString().ToLowerInvariant() }
            '{0}={1}' -f [Uri]::EscapeDataString([string]$key), [Uri]::EscapeDataString([string]$value)
        }
        if ($pairs) {
            $uri = $uri + '?' + ($pairs -join '&')
        }
    }

    $attempts = 1
    if ($Method -eq 'GET') {
        $attempts = $MaxAttempts
    }

    $token = ConvertFrom-LEGateSecureString -SecureString $Session.Token
    $headers = @{
        Authorization = 'Bearer ' + $token
        Accept        = 'application/json'
    }

    $splat = @{
        Method      = $Method
        Uri         = $uri
        Headers     = $headers
        TimeoutSec  = $TimeoutSeconds
        ErrorAction = 'Stop'
    }
    if ($null -ne $Body) {
        $splat['ContentType'] = 'application/json'
        if ($Body -is [string]) {
            $splat['Body'] = $Body
        }
        else {
            $splat['Body'] = ConvertTo-Json -InputObject $Body -Depth 10 -Compress
        }
    }
    if ($Session.SkipCertificateCheck -and (Get-Command Invoke-RestMethod).Parameters.ContainsKey('SkipCertificateCheck')) {
        $splat['SkipCertificateCheck'] = $true
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le $attempts; $attempt++) {
        Write-LEGateLog -Level Debug -Message 'API request' -Fields @{ method = $Method; uri = $uri; attempt = $attempt; maxAttempts = $attempts }
        try {
            $response = Invoke-RestMethod @splat
            return $response
        }
        catch {
            $lastError = $_
            $statusCode = $null
            $exception = $_.Exception
            if ($exception.Response -and $exception.Response.StatusCode) {
                $statusCode = [int]$exception.Response.StatusCode
            }

            $retryable = ($null -eq $statusCode) -or ($statusCode -ge 500)
            if ($retryable -and $attempt -lt $attempts) {
                $delay = 2 * $attempt
                Write-LEGateLog -Level Warn -Message 'API request failed, retrying' -Fields @{
                    method     = $Method
                    uri        = $uri
                    attempt    = $attempt
                    statusCode = $statusCode
                    delaySec   = $delay
                    error      = $exception.Message
                }
                Start-Sleep -Seconds $delay
                continue
            }
            break
        }
    }

    # Build a clear, redacted error from the last failure.
    $exception = $lastError.Exception
    $statusCode = $null
    if ($exception.Response -and $exception.Response.StatusCode) {
        $statusCode = [int]$exception.Response.StatusCode
    }

    $problemTitle = $null
    $problemDetail = $null
    $bodyText = $null
    if ($lastError.ErrorDetails -and $lastError.ErrorDetails.Message) {
        $bodyText = $lastError.ErrorDetails.Message
    }
    elseif ($exception.Response -and ($exception.Response.PSObject.Methods.Name -contains 'GetResponseStream')) {
        try {
            $stream = $exception.Response.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                $bodyText = $reader.ReadToEnd()
                $reader.Dispose()
            }
        }
        catch {
            $bodyText = $null
        }
    }
    if ($bodyText) {
        try {
            $problem = ConvertFrom-Json -InputObject $bodyText
            if ($problem.title) { $problemTitle = [string]$problem.title }
            if ($problem.detail) { $problemDetail = [string]$problem.detail }
        }
        catch {
            $problemTitle = $null
        }
    }

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add(('{0} {1} failed' -f $Method, $Path))
    if ($null -ne $statusCode) { $parts.Add(('HTTP {0}' -f $statusCode)) } else { $parts.Add('transport error') }
    if ($problemTitle) { $parts.Add($problemTitle) }
    if ($problemDetail) { $parts.Add($problemDetail) }
    if (-not $problemTitle -and $exception.Message) { $parts.Add($exception.Message) }
    if ($attempts -gt 1) { $parts.Add(('after {0} attempts' -f $attempts)) }

    $message = Hide-LEGateSecret -Text ($parts -join ': ')
    Write-LEGateLog -Level Error -Message $message -Fields @{ method = $Method; path = $Path; statusCode = $statusCode }

    $failure = New-Object System.Exception($message)
    $failure.Data['LEGate.StatusCode'] = $statusCode
    $failure.Data['LEGate.Title'] = $problemTitle
    $failure.Data['LEGate.Detail'] = $problemDetail
    $failure.Data['LEGate.Method'] = $Method
    $failure.Data['LEGate.Path'] = $Path
    throw $failure
}
