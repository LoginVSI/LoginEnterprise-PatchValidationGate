@{
    RootModule        = 'LEGate.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '0390037d-2e2c-4e04-b47e-a4531252bb93'
    Author            = 'Login Enterprise Patch Validation Gate contributors'
    Description       = 'Thin PowerShell wrapper over the Login Enterprise Public API, used as an evidence gate for patch promotion.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Connect-LEGate',
        'Get-LEGateVersion',
        'Resolve-LEGateTest',
        'Start-LEGateRun',
        'Wait-LEGateRun'
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
