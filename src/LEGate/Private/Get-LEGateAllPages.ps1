function Get-LEGateAllPages {
    <#
    .SYNOPSIS
        Walks a paged list endpoint and returns every item.
    .DESCRIPTION
        Login Enterprise list endpoints take count, offset, and includeTotalCount and
        return { items[], totalCount, offset }. This function keeps requesting pages
        until offset + items.length reaches totalCount, or until a page comes back
        empty, and returns the concatenated items.

        The caller supplies count in -Query. Anything else in -Query (filter, testType,
        orderBy, direction) is passed through unchanged on every page.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [hashtable]$Query,

        [ValidateRange(1, 10000)]
        [int]$MaxPages = 500
    )

    if (-not $Query.ContainsKey('count')) {
        throw 'Get-LEGateAllPages requires count in -Query.'
    }

    $items = New-Object System.Collections.ArrayList
    $offset = 0
    $page = 0

    while ($page -lt $MaxPages) {
        $page++
        $pageQuery = @{}
        foreach ($key in $Query.Keys) { $pageQuery[$key] = $Query[$key] }
        $pageQuery['offset'] = $offset
        $pageQuery['includeTotalCount'] = $true

        $response = Invoke-LEGateRequest -Session $Session -Method GET -Path $Path -Query $pageQuery
        $pageItems = @()
        if ($null -ne $response -and $null -ne $response.items) {
            $pageItems = @($response.items)
        }

        foreach ($item in $pageItems) { [void]$items.Add($item) }
        $offset += $pageItems.Count

        $totalCount = $null
        if ($null -ne $response -and $null -ne $response.totalCount) {
            $totalCount = [int]$response.totalCount
        }

        Write-LEGateLog -Level Debug -Message 'Fetched page' -Fields @{ path = $Path; page = $page; pageItems = $pageItems.Count; offset = $offset; totalCount = $totalCount }

        if ($pageItems.Count -eq 0) { break }
        if ($null -eq $totalCount) { break }
        if ($offset -ge $totalCount) { break }
    }

    if ($page -ge $MaxPages) {
        Write-LEGateLog -Level Warn -Message 'Stopped paging at the page limit' -Fields @{ path = $Path; maxPages = $MaxPages; itemsSoFar = $items.Count }
    }

    return $items.ToArray()
}
