function Resolve-LEGateTest {
    <#
    .SYNOPSIS
        Finds one application test by its exact name.
    .DESCRIPTION
        Calls GET /tests?testType=applicationTest&filter={name}. The appliance filter
        matches on name or description and is not exact, so the result is narrowed
        client-side to items whose name equals -Name (case-sensitive, ordinal).

        Zero exact matches or more than one is an error. The gate must never run
        against a guessed test.

        With -Include thresholds, the resolved test is read again through
        GET /tests/{testId}?include=thresholds and that fuller object is returned.
    .PARAMETER Session
        Session from Connect-LEGate.
    .PARAMETER Name
        Exact application test name.
    .PARAMETER Include
        Optional include value for the follow-up read. Only thresholds is supported.
    .OUTPUTS
        The test object as returned by the appliance.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [ValidateSet('thresholds')]
        [string]$Include
    )

    $query = @{
        testType = 'applicationTest'
        filter   = $Name
        count    = 50
    }

    $candidates = @(Get-LEGateAllPages -Session $Session -Path '/tests' -Query $query)
    $exact = @($candidates | Where-Object { [string]::Equals([string]$_.name, $Name, [System.StringComparison]::Ordinal) })

    Write-LEGateLog -Level Debug -Message 'Resolved test candidates' -Fields @{ name = $Name; candidates = $candidates.Count; exactMatches = $exact.Count }

    if ($exact.Count -eq 0) {
        throw ('No application test named exactly "{0}". The appliance returned {1} candidate(s) for that filter; none matched the name.' -f $Name, $candidates.Count)
    }
    if ($exact.Count -gt 1) {
        $ids = ($exact | ForEach-Object { $_.id }) -join ', '
        throw ('More than one application test is named "{0}" ({1} matches: {2}). Rename the tests so the name is unique.' -f $Name, $exact.Count, $ids)
    }

    $test = $exact[0]

    if ($Include) {
        $test = Invoke-LEGateRequest -Session $Session -Method GET -Path ('/tests/{0}' -f $test.id) -Query @{ include = $Include }
    }

    Write-LEGateLog -Level Info -Message 'Resolved application test' -Fields @{ name = $test.name; testId = $test.id; state = $test.state }
    return $test
}
