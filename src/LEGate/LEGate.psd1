@{
    RootModule        = 'LEGate.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '0390037d-2e2c-4e04-b47e-a4531252bb93'
    Author            = 'Login Enterprise Patch Validation Gate contributors'
    Description       = 'Thin PowerShell wrapper over the Login Enterprise Public API, used as an evidence gate for patch promotion.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Add-LEGateChangeComment',
        'Close-LEGateChangeIssue',
        'Connect-LEGate',
        'ConvertTo-LEGateBoolean',
        'ConvertTo-LEGateResult',
        'Export-LEGateEvidence',
        'Export-LEGateRunResult',
        'Get-LEGateApproval',
        'Get-LEGateRunAppExecution',
        'Get-LEGateRunEvent',
        'Get-LEGateRunMeasurement',
        'Get-LEGateRunOverview',
        'Get-LEGateRunScreenshot',
        'Get-LEGateRunSession',
        'Get-LEGateTimestamp',
        'Get-LEGateVersion',
        'Invoke-LEGateChangeAdapter',
        'Invoke-LEGateContinuousHandoff',
        'Invoke-LEGateValidation',
        'New-LEGateChangeIssue',
        'Publish-LEGateEvidence',
        'Read-LEGatePolicy',
        'Resolve-LEGateContinuousTest',
        'Resolve-LEGateTest',
        'Start-LEGateContinuousTest',
        'Start-LEGateRun',
        'Test-LEGateChangeManifest',
        'Test-LEGateEvidence',
        'Test-LEGatePolicy',
        'Test-LEGatePolicyDefinition',
        'Wait-LEGateApprovalEvidence',
        'Wait-LEGateRun',
        'Write-LEGatePromotionRecord'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('LoginEnterprise', 'PatchValidation', 'Gate')
            LicenseUri = ''
            ProjectUri = ''
        }
    }
}
