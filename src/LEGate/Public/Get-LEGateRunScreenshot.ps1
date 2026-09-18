function Get-LEGateRunScreenshot {
    <# .SYNOPSIS
    Saves failed-execution screenshot lists and binary bytes privately.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$TestRunId, [object[]]$Executions, [object]$ResponseMap, [string]$CaptureRoot)
    Assert-LEGateIdentifier -Value $TestRunId
    $records = New-Object Collections.ArrayList
    foreach ($execution in $Executions) {
        if ($execution.state -ne 'endedWithErrors') { continue }
        $id = [string](Get-LEGateField -Value $execution -Selector $ResponseMap.selectors.executionId)
        Assert-LEGateIdentifier -Value $id
        $path = '/test-runs/{0}/app-executions/{1}/screenshots' -f $TestRunId, $id
        $folder = Resolve-LEGatePath -Root $CaptureRoot -RelativePath $id
        [IO.Directory]::CreateDirectory($folder) | Out-Null
        $screenshots = @(Get-LEGateResultList -Session $Session -Path $path -Query @{ count = 100 } -ListProfile $ResponseMap.lists.screenshots -CaptureRoot $folder)
        if ($screenshots.Count -eq 0) { throw 'Failed execution has no screenshot evidence.' }
        $seen = @{}
        foreach ($screenshot in $screenshots) {
            $sid = [string](Get-LEGateField -Value $screenshot -Selector $ResponseMap.selectors.screenshotId)
            Assert-LEGateIdentifier -Value $sid
            if ($seen.ContainsKey($sid)) { throw 'Duplicate screenshot identity.' }
            $seen[$sid] = $true
            $file = Resolve-LEGatePath -Root $folder -RelativePath ($sid + '.bin')
            Invoke-LEGateRequest -Session $Session -Method GET -Path ($path + '/' + $sid) -OutFile $file | Out-Null
            if (-not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -eq 0) { throw 'Screenshot download is empty.' }
            [void]$records.Add([pscustomobject]@{ runId = $TestRunId; executionId = $id; screenshotId = $sid; path = $id + '/' + $sid + '.bin' })
        }
    }
    return $records.ToArray()
}
