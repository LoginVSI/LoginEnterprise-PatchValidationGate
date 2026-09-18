function Export-LEGateRunResult {
    <# .SYNOPSIS
    Captures documented run endpoints, preserving partial private results on errors.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$TestRunId, [object]$ResponseMap, [string]$OutputPath, [string]$BaselineRunId)
    Assert-LEGateIdentifier -Value $TestRunId
    [IO.Directory]::CreateDirectory($OutputPath) | Out-Null
    $capture = [ordered]@{ provenance = 'appliance-capture'; complete = $true; run = $null; overview = $null; sessions = @(); executions = @(); events = @(); measurements = @(); screenshots = @(); errors = @() }
    if ($Session.Synthetic) { $capture.provenance = 'synthetic' }
    $Session = $Session.PSObject.Copy()
    $Session | Add-Member -NotePropertyName TraceRoot -NotePropertyValue (Join-Path -Path $OutputPath -ChildPath 'requests') -Force
    foreach ($kind in @('run', 'overview', 'sessions', 'executions', 'events', 'measurements', 'screenshots')) {
        try {
            $folder = Resolve-LEGatePath -Root $OutputPath -RelativePath $kind
            switch ($kind) {
                'run' { $value = Invoke-LEGateRequest -Session $Session -Method GET -Path ('/test-runs/' + $TestRunId) }
                'overview' { $value = Get-LEGateRunOverview -Session $Session -TestRunId $TestRunId -BaselineRunId $BaselineRunId }
                'sessions' { $value = @(Get-LEGateRunSession -Session $Session -TestRunId $TestRunId -ListProfile $ResponseMap.lists.sessions -CaptureRoot $folder) }
                'executions' { $value = @(Get-LEGateRunAppExecution -Session $Session -TestRunId $TestRunId -UserSessions $capture.sessions -ResponseMap $ResponseMap -CaptureRoot $folder) }
                'events' { $value = @(Get-LEGateRunEvent -Session $Session -TestRunId $TestRunId -ListProfile $ResponseMap.lists.events -CaptureRoot $folder) }
                'measurements' { $value = @(Get-LEGateRunMeasurement -Session $Session -TestRunId $TestRunId -ListProfile $ResponseMap.lists.measurements -CaptureRoot $folder) }
                'screenshots' { $value = @(Get-LEGateRunScreenshot -Session $Session -TestRunId $TestRunId -Executions $capture.executions -ResponseMap $ResponseMap -CaptureRoot $folder) }
            }
            $capture[$kind] = $value
            Write-LEGateJson -Path (Resolve-LEGatePath -Root $OutputPath -RelativePath ($kind + '.json')) -Value $value
        }
        catch { $capture.complete = $false; $capture.errors += [pscustomobject]@{ stage = $kind; code = 'retrieval-failed'; message = Hide-LEGateSecret -Text $_.Exception.Message } }
    }
    Write-LEGateJson -Path (Join-Path -Path $OutputPath -ChildPath 'capture.json') -Value $capture
    return [pscustomobject]$capture
}
