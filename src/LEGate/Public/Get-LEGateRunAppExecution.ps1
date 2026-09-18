function Get-LEGateRunAppExecution {
    <# .SYNOPSIS
    Retrieves executions across every supplied session with relationship checks.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$TestRunId, [object[]]$UserSessions, [object]$ResponseMap, [string]$CaptureRoot)
    Assert-LEGateIdentifier -Value $TestRunId
    $all = New-Object Collections.ArrayList
    $seen = @{}
    foreach ($userSession in $UserSessions) {
        $id = [string](Get-LEGateField -Value $userSession -Selector $ResponseMap.selectors.sessionId)
        Assert-LEGateIdentifier -Value $id
        if ($seen.ContainsKey($id)) { throw 'Duplicate session ID.' }
        $seen[$id] = $true
        $path = '/test-runs/{0}/user-sessions/{1}/app-executions' -f $TestRunId, $id
        $folder = $null
        if ($CaptureRoot) { $folder = Join-Path -Path $CaptureRoot -ChildPath $id }
        $items = @(Get-LEGateResultList -Session $Session -Path $path -Query @{ count = 200; direction = 'asc' } -ListProfile $ResponseMap.lists.executions -CaptureRoot $folder)
        foreach ($item in $items) {
            if ((Get-LEGateField -Value $item -Selector $ResponseMap.selectors.executionSessionId) -cne $id -or
                (Get-LEGateField -Value $item -Selector $ResponseMap.selectors.executionRunId) -cne $TestRunId) { throw 'Execution relationship mismatch.' }
            [void]$all.Add($item)
        }
    }
    return $all.ToArray()
}
