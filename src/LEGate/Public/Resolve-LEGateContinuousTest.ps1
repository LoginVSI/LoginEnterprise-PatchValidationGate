function Resolve-LEGateContinuousTest {
    <# .SYNOPSIS
    Resolves exactly one existing continuous test, never creates or edits tests.
    #>
    [CmdletBinding()]
    param([object]$Session, [string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Continuous test name is required.' }
    $tests = @(Get-LEGateAllPages -Session $Session -Path '/tests' -Query @{ testType = 'continuousTest'; count = 50; filter = $Name })
    $exactMatches = @($tests | Where-Object { $_.name -ceq $Name })
    if ($exactMatches.Count -ne 1) { throw 'Continuous test name is missing or ambiguous.' }
    return $exactMatches[0]
}
