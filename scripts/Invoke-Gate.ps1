<# .SYNOPSIS
Runs private live validation; optionally exports a safe public projection.
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
    [pscredential]$Credential, [switch]$UseCurrentCredentials, [switch]$Local,
    [switch]$Resume, [switch]$Revert, [switch]$RecoveryConfirmed, [switch]$ReportIssue,
    [string]$PublicationPath, [string]$BaselineRunId
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Path $PSScriptRoot -Parent
Import-Module (Join-Path -Path $root -ChildPath 'src/LEGate/LEGate.psd1') -Force
if ($env:GITHUB_OUTPUT) { 'verdict=INCONCLUSIVE' | Out-File -LiteralPath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
try {
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
        StateRoot = $StateRoot; EvidenceRoot = $EvidenceRoot; PromotionMode = $PromotionMode
        UseCurrentCredentials = $UseCurrentCredentials; Local = $Local; Resume = $Resume; Revert = $Revert
        RecoveryConfirmed = $RecoveryConfirmed; ReportIssue = $ReportIssue; BaselineRunId = $BaselineRunId; SourceCommit = $sourceCommit
    }
    if ($Credential) { $requestArgs.Credential = $Credential }
    $result = Invoke-LEGateValidation @requestArgs
    if ($Revert) {
        if ($result.restored) { Write-Output 'Restoration verified; private record preserved.'; exit 0 }
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
