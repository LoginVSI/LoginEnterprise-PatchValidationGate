function Wait-LEGateApprovalEvidence {
    <# .SYNOPSIS
    Waits for atomic delivery of independently acquired approval evidence, fail closed.
    #>
    [CmdletBinding()]
    param(
        [string]$Path,
        [ValidateRange(1, 600)][int]$MaxWaitSeconds = 120,
        [ValidateRange(1, 30)][int]$PollIntervalSeconds = 2
    )
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'Authoritative approval evidence delivery path is required.' }
    $deadline = (Get-LEGateUtcNow).AddSeconds($MaxWaitSeconds)
    while ((Get-LEGateUtcNow) -lt $deadline) {
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            $evidence = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ((Get-LEGateUtcNow) -ge $deadline) { break }
            return $evidence
        }
        $remaining = [Math]::Floor(($deadline - (Get-LEGateUtcNow)).TotalMilliseconds)
        if ($remaining -le 0) { break }
        Start-Sleep -Milliseconds ([int][Math]::Min($PollIntervalSeconds * 1000, $remaining))
    }
    throw 'Authoritative approval evidence was not delivered within the bounded wait. Handoff incomplete.'
}
