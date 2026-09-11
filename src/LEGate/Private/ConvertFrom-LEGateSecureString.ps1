function ConvertFrom-LEGateSecureString {
    <#
    .SYNOPSIS
        Turns a SecureString back into plain text for the duration of one request.
    .DESCRIPTION
        The session keeps the API token as a SecureString so an accidental dump of the
        session object does not print it. This helper works on PowerShell 5.1, which
        has no -AsPlainText switch on ConvertFrom-SecureString.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Security.SecureString]$SecureString
    )

    $bstr = [IntPtr]::Zero
    try {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}
