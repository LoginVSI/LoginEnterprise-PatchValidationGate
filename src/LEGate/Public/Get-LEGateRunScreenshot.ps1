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
        # Screenshot[] is an unpaged endpoint, unlike the other result sets.
        $response = Invoke-LEGateRequest -Session $Session -Method GET -Path $path
        Write-LEGateJson -Path (Join-Path $folder 'metadata.json') -Value $response
        if ($null -eq $response -or $response -isnot [array]) { throw 'Screenshot metadata must be an array.' }
        $screenshots = @($response)
        if ($screenshots.Count -eq 0) { throw 'Failed execution has no screenshot evidence.' }
        $seen = @{}
        foreach ($screenshot in $screenshots) {
            $sid = Get-LEGateField -Value $screenshot -Selector $ResponseMap.selectors.screenshotId
            if ($sid -isnot [string] -or [string]::IsNullOrWhiteSpace($sid)) { throw 'Screenshot identity is missing or malformed.' }
            if ($sid -in @('.', '..')) { throw 'Screenshot identity cannot be a URI dot segment.' }
            if ($seen.ContainsKey($sid)) { throw 'Duplicate screenshot identity.' }
            $seen[$sid] = $true
            $fileName = (Get-LEGateTextHash -Text $sid) + '.bin'
            $file = Resolve-LEGatePath -Root $folder -RelativePath $fileName
            Invoke-LEGateRequest -Session $Session -Method GET -Path ($path + '/' + [Uri]::EscapeDataString($sid)) -OutFile $file | Out-Null
            if (-not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).Length -eq 0) { throw 'Screenshot download is empty.' }
            [void]$records.Add([pscustomobject]@{ runId = $TestRunId; executionId = $id; screenshotId = $sid; path = $id + '/' + $fileName })
        }
    }
    return $records.ToArray()
}
