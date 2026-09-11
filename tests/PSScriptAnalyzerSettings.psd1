@{
    # Lint settings for the Pester test files only. scripts/Invoke-Lint.ps1 applies
    # this file to the tests folder and the root settings to everything else.
    #
    # Two rules from the root set are dropped here on purpose:
    #   PSUseDeclaredVarsMoreThanAssignments  Pester 5 sets variables in BeforeAll and
    #                                         reads them in It blocks. The analyzer cannot
    #                                         see across those scriptblocks.
    #   PSUseShouldProcessForStateChangingFunctions  Test helpers named New-* build
    #                                         in-memory objects and change nothing.

    Severity     = @('Error', 'Warning')

    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidGlobalVars',
        'PSAvoidAssignmentToAutomaticVariable',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidTrailingWhitespace',
        'PSMisleadingBacktick',
        'PSPossibleIncorrectComparisonWithNull',
        'PSPossibleIncorrectUsageOfAssignmentOperator',
        'PSPossibleIncorrectUsageOfRedirectionOperator',
        'PSUseApprovedVerbs',
        'PSUseCompatibleSyntax',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSUseCorrectCasing',
        'PSPlaceOpenBrace',
        'PSPlaceCloseBrace',
        'PSUseBOMForUnicodeEncodedFile'
    )

    Rules        = @{
        PSUseCompatibleSyntax = @{
            Enable         = $true
            TargetVersions = @('5.1', '7.0')
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
    }
}
