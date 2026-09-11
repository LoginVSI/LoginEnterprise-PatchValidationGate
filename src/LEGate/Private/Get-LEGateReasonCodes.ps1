function Get-LEGateReasonCodes {
    <#
    .SYNOPSIS
        Returns the INCONCLUSIVE reason codes defined in docs/verdict.md.
    .DESCRIPTION
        This is the single place the reason codes live in code. The evaluator (Part 2),
        the tests, and the docs all read from the same list. A unit test compares this
        output against docs/verdict.md and policies/default.policy.json so the three
        cannot drift apart without a test failing.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'test-not-found',
        'preflight-failed',
        'run-timeout',
        'launcher-or-connection-error',
        'results-incomplete',
        'policy-invalid'
    )
}
