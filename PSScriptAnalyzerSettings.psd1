@{
    # Lint settings for the whole repo. scripts/Invoke-Lint.ps1 passes this file to
    # Invoke-ScriptAnalyzer. The compatibility rules are the important ones: they
    # catch syntax and cmdlets that do not exist on Windows PowerShell 5.1.

    Severity     = @('Error', 'Warning')

    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPositionalParameters',
        'PSAvoidGlobalVars',
        'PSAvoidDefaultValueSwitchParameter',
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidAssignmentToAutomaticVariable',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidTrailingWhitespace',
        'PSMisleadingBacktick',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfAssignmentOperator',
        'PSPossibleIncorrectUsageOfRedirectionOperator',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSShouldProcess',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSUseLiteralInitializerForHashtable',
        'PSUsePSCredentialType',
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseCompatibleSyntax',
        'PSUseCompatibleCmdlets',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseCorrectCasing',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseBOMForUnicodeEncodedFile'
    )

    Rules        = @{
        PSUseCompatibleSyntax  = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
        }
        PSUseCompatibleCmdlets = @{
            compatibility = @('desktop-5.1.14393.206-windows')
        }
        PSUseConsistentIndentation = @{
            Enable              = $true
            IndentationSize     = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind                = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable                          = $true
            CheckInnerBrace                 = $true
            CheckOpenBrace                  = $true
            CheckOpenParen                  = $true
            CheckOperator                   = $false
            CheckPipe                       = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator                  = $true
            CheckParameter                  = $false
        }
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }
        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }
        PSUseSingularNouns = @{
            NounAllowList = @('Pages', 'Codes')
        }
    }
}
