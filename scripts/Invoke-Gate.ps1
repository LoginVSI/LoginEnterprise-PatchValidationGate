<# .SYNOPSIS
Runs private live validation; optionally exports a safe public projection.
.DESCRIPTION
Target remoting is independent of LE appliance TLS. HTTPS validates the target
certificate normally and never falls back to HTTP.
.PARAMETER TargetTransport
HTTP or HTTPS; defaults to LE_TARGET_TRANSPORT, otherwise HTTP for compatibility.
.PARAMETER TargetPort
WSMan port; defaults to LE_TARGET_PORT, otherwise 5986 for HTTPS or 5985 for HTTP.
#>
[CmdletBinding()]
param(
    [string]$ChangeId = $env:LE_CHANGE_ID,
    [string]$PolicyFile = 'policies/default.policy.json',
    [string]$ChangeManifest = 'examples/changes/app-update.json',
    [string]$ResponseProfile = 'config/response-profile.local.json',
    [ValidateSet('app-update', 'break', 'noop')][string]$Adapter = 'app-update',
    [string]$Target = $env:LE_TARGET,
    [string]$ContinuousTestName = 'patch-gate-continuous',
    [ValidateSet('manual', 'auto')][string]$PromotionMode = 'manual',
    [string]$StateRoot = $env:LE_STATE_ROOT,
    [string]$EvidenceRoot = $env:LE_PRIVATE_ROOT,
    [ValidateSet('HTTP', 'HTTPS')][string]$TargetTransport = $(if ($env:LE_TARGET_TRANSPORT) { $env:LE_TARGET_TRANSPORT } else { 'HTTP' }),
    [ValidateRange(1, 65535)][int]$TargetPort = $(if ($env:LE_TARGET_PORT) { $env:LE_TARGET_PORT } elseif ($TargetTransport -eq 'HTTPS') { 5986 } else { 5985 }),
    [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local,
    [switch]$Resume, [switch]$Revert, [switch]$RecoveryConfirmed, [switch]$ReportIssue,
    [string]$PublicationPath, [string]$BaselineRunId
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path -Path $root -ChildPath 'src/LEGate/LEGate.psd1') -Force
if ($env:GITHUB_OUTPUT) { 'verdict=INCONCLUSIVE' | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
try {
    # PowerShell does not apply validation attributes to default expressions.
    if ($TargetTransport -notin @('HTTP', 'HTTPS') -or $TargetPort -lt 1 -or $TargetPort -gt 65535) { throw 'Invalid target transport or port.' }
    if (-not $StateRoot -or -not $EvidenceRoot) { throw 'Set private evidence and durable state roots.' }
    if ($env:GITHUB_ACTIONS -eq 'true') {
        foreach ($privateRoot in @($StateRoot, $EvidenceRoot)) {
            $absolute = [IO.Path]::GetFullPath($privateRoot).TrimEnd('\') + '\'
            if ($absolute.StartsWith(([IO.Path]::GetFullPath($root).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) { throw 'Workflow private roots must be outside the checkout.' }
        }
    }
    $sourceCommit = $env:GITHUB_SHA
    if (-not $sourceCommit) { $sourceCommit = git -C $root rev-parse HEAD }
    if (-not $Credential -and $env:TARGET_USER -and $env:TARGET_PASSWORD) {
        $secure = New-Object Security.SecureString
        foreach ($character in $env:TARGET_PASSWORD.ToCharArray()) { $secure.AppendChar($character) }
        $secure.MakeReadOnly()
        $Credential = New-Object Management.Automation.PSCredential($env:TARGET_USER, $secure)
    }
    $requestArgs = @{
        ChangeId = $ChangeId; RepositoryRoot = $root; PolicyFile = $PolicyFile; ChangeManifest = $ChangeManifest
        ResponseProfile = $ResponseProfile; Adapter = $Adapter; Target = $Target; ContinuousTestName = $ContinuousTestName
        TargetTransport = $TargetTransport; TargetPort = $TargetPort
        StateRoot = $StateRoot; EvidenceRoot = $EvidenceRoot; PromotionMode = $PromotionMode
        UseCurrentCredentials = $UseCurrentCredentials; Local = $Local; Resume = $Resume; Revert = $Revert
        RecoveryConfirmed = $RecoveryConfirmed; ReportIssue = $ReportIssue; BaselineRunId = $BaselineRunId; SourceCommit = $sourceCommit
    }
    if ($Credential) { $requestArgs.Credential = $Credential }
    $result = Invoke-LEGateValidation @requestArgs
    if ($Revert) {
        if ($result.restored) { Write-Output 'Restoration verified; private record preserved. Check exit code for reporting failure.'; exit $result.exitCode }
        exit 2
    }
    if ($PublicationPath) {
        $published = Publish-LEGateEvidence -PrivatePath $result.privatePath -OutputPath $PublicationPath
        $null = Test-LEGateEvidence -Path $PublicationPath -ExpectedManifestHash $published.manifestSha256
        if ($env:GITHUB_OUTPUT) {
            ('manifest_hash=' + $published.manifestSha256) | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8
        }
    }
    if ($env:GITHUB_OUTPUT) {
        ('verdict=' + $result.verdict) | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8
        if ($result.issueNumber) { ('issue_number=' + [int]$result.issueNumber) | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
    }
    Write-Output ('Validation: {0}. Evidence preserved. Production promotion is simulated.' -f $result.verdict)
    exit $result.exitCode
}
catch { Write-Output 'Gate could not complete. Inspect private evidence and durable target state; no promotion is permitted.'; exit 2 }
