function Wait-LEGateRun {
    <#
    .SYNOPSIS
        Polls a test run until it completes or the wait budget runs out.
    .DESCRIPTION
        Calls GET /test-runs/{testRunId} every -PollIntervalSeconds. The run moves
        through created, testRunEnded, and completed; the function returns once state
        is completed. State changes are logged as they happen.

        If -MaxWaitMinutes passes first, the function does not throw. It returns the
        last run object it saw with timedOut set to true, so the caller can record an
        INCONCLUSIVE verdict with the run-timeout reason code. A timeout says nothing
        about the patch.

        Whatever run object was seen last, completed or not, is written as raw JSON
        to {EvidenceRoot}/{changeId}/run.json. That file is the evidence; the object
        returned to the caller carries two extra properties, timedOut and waitedSeconds,
        which are not written to disk.
    .PARAMETER Session
        Session from Connect-LEGate.
    .PARAMETER TestRunId
        Run id from Start-LEGateRun.
    .PARAMETER ChangeId
        Change identifier. Names the evidence folder.
    .PARAMETER PollIntervalSeconds
        Seconds between polls. Default 30.
    .PARAMETER MaxWaitMinutes
        Total wait budget. Default 45.
    .PARAMETER EvidenceRoot
        Folder that holds one subfolder per change id. Default is evidence under the current location.
    .OUTPUTS
        The run object with timedOut and waitedSeconds added.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [PSTypeName('LEGate.Session')]
        [PSCustomObject]$Session,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TestRunId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ChangeId,

        [ValidateRange(1, 3600)]
        [int]$PollIntervalSeconds = 30,

        [ValidateRange(1, 1440)]
        [int]$MaxWaitMinutes = 45,

        [string]$EvidenceRoot = (Join-Path -Path (Get-Location).Path -ChildPath 'evidence')
    )

    $path = '/test-runs/{0}' -f $TestRunId
    $startedAt = Get-LEGateUtcNow
    $deadline = $startedAt.AddMinutes($MaxWaitMinutes)
    $lastState = $null
    $run = $null
    $timedOut = $false

    Write-LEGateLog -Level Info -Message 'Waiting for run' -Fields @{ testRunId = $TestRunId; changeId = $ChangeId; pollIntervalSeconds = $PollIntervalSeconds; maxWaitMinutes = $MaxWaitMinutes; deadline = $deadline }

    while ($true) {
        $run = Invoke-LEGateRequest -Session $Session -Method GET -Path $path
        $state = [string]$run.state

        if ($state -ne $lastState) {
            Write-LEGateLog -Level Info -Message 'Run state' -Fields @{ testRunId = $TestRunId; state = $state; result = $run.result }
            $lastState = $state
        }

        if ($state -eq 'completed') {
            break
        }

        $now = Get-LEGateUtcNow
        if ($now -ge $deadline) {
            $timedOut = $true
            Write-LEGateLog -Level Warn -Message 'Run did not complete inside the wait budget' -Fields @{ testRunId = $TestRunId; state = $state; maxWaitMinutes = $MaxWaitMinutes }
            break
        }

        Start-Sleep -Seconds $PollIntervalSeconds
    }

    $waitedSeconds = [int][Math]::Round(((Get-LEGateUtcNow) - $startedAt).TotalSeconds)

    $folder = Join-Path -Path $EvidenceRoot -ChildPath $ChangeId
    if (-not (Test-Path -LiteralPath $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
    $runPath = Join-Path -Path $folder -ChildPath 'run.json'
    $json = ConvertTo-Json -InputObject $run -Depth 20
    [System.IO.File]::WriteAllText($runPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    Write-LEGateLog -Level Info -Message 'Wrote run evidence' -Fields @{ path = $runPath; testRunId = $TestRunId; state = $run.state; result = $run.result; timedOut = $timedOut; waitedSeconds = $waitedSeconds }

    $output = $run.PSObject.Copy()
    $output | Add-Member -NotePropertyName timedOut -NotePropertyValue $timedOut -Force
    $output | Add-Member -NotePropertyName waitedSeconds -NotePropertyValue $waitedSeconds -Force
    return $output
}
