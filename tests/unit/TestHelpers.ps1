# Shared helpers for unit tests. Dot-source from BeforeAll.
# Nothing here touches the network.

$script:LEGateManifestPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\LEGate\LEGate.psd1'
$script:LEGateRepoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..')).Path
$script:LEGateTestToken = 'unit-test-token-0123456789abcdef'

function Import-LEGateForTest {
    Import-Module -Name $script:LEGateManifestPath -Force -ErrorAction Stop
}

function New-LEGateTestSession {
    param(
        [string]$BaseUrl = 'https://appliance.example.test',
        [string]$ApiVersion = 'v8-preview'
    )
    # Discard the info line Connect-LEGate writes so test output stays quiet.
    Connect-LEGate -BaseUrl $BaseUrl -ApiToken $script:LEGateTestToken -ApiVersion $ApiVersion 6>$null
}

function Initialize-LEGateTestExceptionType {
    if (-not ('LEGateTestHttpException' -as [type])) {
        Add-Type -TypeDefinition @'
public class LEGateTestHttpException : System.Exception
{
    public object Response;
    public LEGateTestHttpException(string message, object response) : base(message)
    {
        Response = response;
    }
}
'@
    }
}

function New-LEGateTestHttpException {
    # Mimics the shape Invoke-RestMethod errors have on 5.1 and 7: an exception
    # with a Response that carries a StatusCode.
    param(
        [Parameter(Mandatory = $true)][int]$StatusCode,
        [string]$Message = 'The remote server returned an error.'
    )
    Initialize-LEGateTestExceptionType
    $response = [pscustomobject]@{ StatusCode = $StatusCode }
    return New-Object LEGateTestHttpException($Message, $response)
}

function New-LEGateTestTransportException {
    param([string]$Message = 'The remote name could not be resolved')
    return New-Object System.Net.WebException($Message, $null, [System.Net.WebExceptionStatus]::NameResolutionFailure, $null)
}

function New-LEGateTestProblemRecord {
    # An ErrorRecord whose ErrorDetails carries a ProblemDetails body, the way
    # PowerShell surfaces a JSON error body from Invoke-RestMethod.
    param(
        [Parameter(Mandatory = $true)][int]$StatusCode,
        [Parameter(Mandatory = $true)][string]$Title,
        [string]$Detail
    )
    $ex = New-LEGateTestHttpException -StatusCode $StatusCode
    $record = New-Object System.Management.Automation.ErrorRecord($ex, 'LEGateTest', [System.Management.Automation.ErrorCategory]::InvalidOperation, $null)
    $problem = [ordered]@{ type = 'about:blank'; title = $Title; status = $StatusCode }
    if ($Detail) { $problem['detail'] = $Detail }
    $record.ErrorDetails = New-Object System.Management.Automation.ErrorDetails((ConvertTo-Json -InputObject $problem -Compress))
    return $record
}

function New-LEGatePage {
    # Builds a { items, totalCount, offset } page the way the appliance returns lists.
    param(
        [object[]]$Items = @(),
        [int]$TotalCount = 0,
        [int]$Offset = 0
    )
    return [pscustomobject]@{ items = @($Items); totalCount = $TotalCount; offset = $Offset }
}
