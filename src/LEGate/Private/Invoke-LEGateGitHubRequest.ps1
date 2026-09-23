function Invoke-LEGateGitHubRequest {
    <# .SYNOPSIS
    Calls GitHub over normal TLS with a separate token and fixed API origin.
    #>
    [CmdletBinding()]
    param([ValidateSet('GET', 'POST', 'PATCH')][string]$Method, [string]$Path, [object]$Body)
    if ([string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN) -or $env:GITHUB_REPOSITORY -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'GitHub credentials/repository are not configured.' }
    $existingPath = $Path -match '^/(issues|actions/runs)(/|\?|$)'
    $approvalRead = $Method -ceq 'GET' -and ($Path -match '^/pulls/[1-9][0-9]*(/reviews\?per_page=100&page=[1-9][0-9]*)?$' -or
        $Path -match '^/contents/\.acceptance/approval-request\.json\?ref=[a-f0-9]{40}$' -or
        $Path -match '^/collaborators/[A-Za-z0-9_-]{1,100}/permission$')
    if ((-not $existingPath -and -not $approvalRead) -or $Path -match '\.\.|[\r\n]') { throw 'Unsupported GitHub request path.' }
    $script:LEGateSecrets += $env:GITHUB_TOKEN
    $requestArgs = @{
        Uri = 'https://api.github.com/repos/' + $env:GITHUB_REPOSITORY + $Path
        Method = $Method; Headers = @{ Authorization = 'Bearer ' + $env:GITHUB_TOKEN; Accept = 'application/vnd.github+json'; 'X-GitHub-Api-Version' = '2026-03-10' }
        TimeoutSec = 60; MaximumRedirection = 0; ErrorAction = 'Stop'
    }
    if ($null -ne $Body) { $requestArgs.ContentType = 'application/json'; $requestArgs.Body = ConvertTo-Json -InputObject $Body -Depth 20 -Compress }
    try { return Invoke-RestMethod @requestArgs }
    catch { throw 'GitHub reporting/approval request failed. No response text is published.' }
}
