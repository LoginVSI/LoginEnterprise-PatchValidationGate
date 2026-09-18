function Start-LEGateRun {
    <#
    .SYNOPSIS
        Starts a fresh application run; refuses an existing named run.
    .DESCRIPTION
        A matching run name is refused. Use Invoke-Gate -Resume with durable identity to resume safely.

        Otherwise it calls PUT /tests/{testId}/start with testRunName set to the change
        id and comment set to -Comment. The comment defaults to the policy hash when
        -PolicyPath is given, so a run can be traced back to the exact policy file that
        gated it. A 409 from the appliance (test already running or disabled) becomes a
        plain error that says so.

        Supports -WhatIf. Writes are never retried.
    .PARAMETER Session
        Session from Connect-LEGate.
    .PARAMETER TestId
        Application test id from Resolve-LEGateTest.
    .PARAMETER ChangeId
        Change identifier. Stored on the run as testRunName and used to find the run again.
    .PARAMETER Comment
        Free text stored on the run. Overrides the policy hash.
    .PARAMETER PolicyPath
        Policy file. Its SHA-256 hash becomes the run comment when -Comment is not given.
    .OUTPUTS
        The test run id as a string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TestId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ChangeId,

        [string]$Comment,

        [string]$PolicyPath
    )

    Assert-LEGateIdentifier -Value $TestId
    Assert-LEGateIdentifier -Value $ChangeId
    $runsPath = '/tests/{0}/test-runs' -f $TestId
    $existing = @(Get-LEGateAllPages -Session $Session -Path $runsPath -Query @{ count = 20; orderBy = 'created'; direction = 'desc' })
    $match = @($existing | Where-Object { [string]::Equals([string]$_.testRunName, $ChangeId, [System.StringComparison]::Ordinal) })

    if ($match.Count -gt 0) {
        throw 'A named run already exists. Use Invoke-Gate -Resume with the original durable identity, or a fresh change ID.'
    }

    if ([string]::IsNullOrWhiteSpace($Comment)) {
        if (-not [string]::IsNullOrWhiteSpace($PolicyPath)) {
            if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
                throw ('Policy file not found: {0}' -f $PolicyPath)
            }
            $hash = (Get-FileHash -LiteralPath $PolicyPath -Algorithm SHA256).Hash.ToLowerInvariant()
            $Comment = 'policyHash=sha256:' + $hash
        }
        else {
            $Comment = 'LEGate change ' + $ChangeId
        }
    }

    $body = @{
        testRunName = $ChangeId
        comment     = $Comment
    }

    if (-not $PSCmdlet.ShouldProcess(('test {0}' -f $TestId), ('Start run for change {0}' -f $ChangeId))) {
        return $null
    }

    try {
        $result = Invoke-LEGateRequest -Session $Session -Method PUT -Path ('/tests/{0}/start' -f $TestId) -Body $body
    }
    catch {
        $status = $_.Exception.Data['LEGate.StatusCode']
        if ($status -eq 409) {
            $title = $_.Exception.Data['LEGate.Title']
            $reason = 'the test is already running or is disabled'
            if ($title) { $reason = [string]$title }
            throw ('Test {0} could not be started for change {1}: {2} (HTTP 409). Wait for the current run to finish or enable the test, then try again.' -f $TestId, $ChangeId, $reason)
        }
        throw
    }

    if ($null -eq $result -or [string]::IsNullOrWhiteSpace([string]$result.id)) {
        throw ('Start returned no run id for test {0}. Raw response: {1}' -f $TestId, (ConvertTo-Json -InputObject $result -Compress -Depth 5))
    }

    Write-LEGateLog -Level Info -Message 'Started run' -Fields @{ changeId = $ChangeId; testId = $TestId; testRunId = $result.id; comment = $Comment }
    return [string]$result.id
}
