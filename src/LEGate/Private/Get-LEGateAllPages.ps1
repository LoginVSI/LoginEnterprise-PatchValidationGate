function Get-LEGateAllPages {
    <# .SYNOPSIS
    Collects strict result-set pages and optionally records private page provenance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][PSTypeName('LEGate.Session')][object]$Session,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][hashtable]$Query,
        [ValidateRange(1, 10000)][int]$MaxPages = 500,
        [ValidateSet('envelope', 'array')][string]$Envelope = 'envelope',
        [switch]$ArrayTerminationConfirmed,
        [string]$CaptureRoot
    )
    if (-not $Query.ContainsKey('count') -or [int]$Query.count -lt 1) { throw 'Paging requires count in -Query.' }
    $items = New-Object Collections.ArrayList
    $offset = 0
    $expected = $null
    for ($page = 1; $page -le $MaxPages; $page++) {
        $q = @{}
        foreach ($key in $Query.Keys) { $q[$key] = $Query[$key] }
        $q.offset = $offset
        $q.includeTotalCount = $true
        try {
            $response = Invoke-LEGateRequest -Session $Session -Method GET -Path $Path -Query $q
            if ($CaptureRoot) {
                Write-LEGateJson -Path (Join-Path -Path $CaptureRoot -ChildPath ('page-{0:D4}.json' -f $page)) -Value @{
                    endpoint = $Path; query = $q; response = $response; capturedAt = ConvertTo-LEGateTimestamp -Value (Get-LEGateUtcNow)
                }
            }
            if ($Envelope -eq 'array') {
                if (-not $ArrayTerminationConfirmed -or $null -eq $response -or $response -isnot [array]) { throw 'Array paging requires a confirmed termination rule and an array response.' }
                $part = @($response)
                $done = $part.Count -lt [int]$Query.count
            }
            else {
                if ($null -eq $response -or $null -eq $response.items -or $response.items -isnot [array] -or
                    $null -eq $response.totalCount -or $null -eq $response.offset) { throw 'Unexpected list envelope or missing paging metadata.' }
                if ([string]$response.totalCount -notmatch '^\d+$' -or [string]$response.offset -notmatch '^\d+$') { throw 'Invalid paging counts.' }
                if ([long]$response.offset -ne $offset) { throw 'Page offset mismatch.' }
                if ($null -eq $expected) { $expected = [long]$response.totalCount }
                if ([long]$response.totalCount -ne $expected) { throw 'Total count changed while paging.' }
                $part = @($response.items)
                if ($offset + $part.Count -gt $expected) { throw 'Page exceeds total count.' }
                $done = $offset + $part.Count -eq $expected
                if (-not $done -and $part.Count -eq 0) { throw 'Premature empty page.' }
            }
            if ($part.Count -gt [int]$Query.count -or @($part | Where-Object { $null -eq $_ }).Count) { throw 'Invalid page contents.' }
            foreach ($item in $part) { [void]$items.Add($item) }
            $offset += $part.Count
            if ($done) { return $items.ToArray() }
        }
        catch {
            if ($CaptureRoot) { Write-LEGateJson -Path (Join-Path -Path $CaptureRoot -ChildPath 'retrieval-error.json') -Value @{ endpoint = $Path; query = $q; error = 'paging-or-request-failed'; page = $page } }
            throw
        }
    }
    throw 'Page limit reached before completeness was established.'
}
