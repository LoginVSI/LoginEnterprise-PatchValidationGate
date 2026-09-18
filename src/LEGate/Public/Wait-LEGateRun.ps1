function Wait-LEGateRun {
    <# .SYNOPSIS
    Polls with a fixed budget, retaining the last private response even on API error.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][PSTypeName('LEGate.Session')][object]$Session,
        [Parameter(Mandatory = $true)][string]$TestRunId,
        [Parameter(Mandatory = $true)][string]$ChangeId,
        [ValidateRange(1, 3600)][int]$PollIntervalSeconds = 30,
        [ValidateRange(1, 1440)][int]$MaxWaitMinutes = 45,
        [string]$EvidenceRoot = (Join-Path -Path (Get-Location).Path -ChildPath 'evidence')
    )
    Assert-LEGateIdentifier -Value $TestRunId
    Assert-LEGateIdentifier -Value $ChangeId
    $folder = Resolve-LEGatePath -Root $EvidenceRoot -RelativePath $ChangeId
    [IO.Directory]::CreateDirectory($folder) | Out-Null
    $started = Get-LEGateUtcNow
    $deadline = $started.AddMinutes($MaxWaitMinutes)
    $run = $null; $timedOut = $false
    try {
        while ($true) {
            $run = Invoke-LEGateRequest -Session $Session -Method GET -Path ('/test-runs/' + $TestRunId)
            Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'run.json') -Value $run
            if ($run.id -cne $TestRunId) { throw 'Poll response run ID mismatch.' }
            if ($run.state -eq 'completed') { break }
            if ($run.state -notin @('created', 'testRunEnded')) { throw 'Unknown run state.' }
            if ((Get-LEGateUtcNow) -ge $deadline) { $timedOut = $true; break }
            Start-Sleep -Seconds $PollIntervalSeconds
        }
    }
    catch {
        Write-LEGateJson -Path (Join-Path -Path $folder -ChildPath 'poll-error.json') -Value @{ code = 'poll-failed'; lastResponseAvailable = ($null -ne $run) }
        throw
    }
    $output = $run.PSObject.Copy()
    $output | Add-Member -NotePropertyName timedOut -NotePropertyValue $timedOut -Force
    $output | Add-Member -NotePropertyName waitedSeconds -NotePropertyValue ([int][Math]::Round(((Get-LEGateUtcNow) - $started).TotalSeconds)) -Force
    return $output
}
