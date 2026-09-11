Describe 'Invoke-LEGateRequest' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $session = New-LEGateTestSession
        $sleeps = [System.Collections.ArrayList]::new()
        Mock -ModuleName LEGate Start-Sleep { [void]$sleeps.Add($Seconds) }
    }

    BeforeEach { $sleeps.Clear() }

    Context 'URL building' {
        It 'builds {baseUrl}/publicApi/{apiVersion}{path} and encodes query values' {
            $captured = @{}
            # Invoke-RestMethod takes a [uri]; ToString() unescapes, AbsoluteUri is what goes on the wire.
            Mock -ModuleName LEGate Invoke-RestMethod { $captured.Uri = ([uri]$Uri).AbsoluteUri; $captured.Method = $Method; $captured.Headers = $Headers; 'ok' }
            InModuleScope LEGate -Parameters @{ s = $session } {
                Invoke-LEGateRequest -Session $s -Method GET -Path '/tests' -Query @{ filter = 'a b&c'; count = 50; includeTotalCount = $true }
            } | Should -Be 'ok'
            $captured.Uri | Should -Be 'https://appliance.example.test/publicApi/v8-preview/tests?count=50&filter=a%20b%26c&includeTotalCount=true'
            $captured.Headers['Accept'] | Should -Be 'application/json'
        }

        It 'sends a JSON body for PUT' {
            $captured = @{}
            Mock -ModuleName LEGate Invoke-RestMethod { $captured.Body = $Body; $captured.ContentType = $ContentType; [pscustomobject]@{ id = 'r' } }
            InModuleScope LEGate -Parameters @{ s = $session } {
                Invoke-LEGateRequest -Session $s -Method PUT -Path '/tests/t/start' -Body @{ testRunName = 'CHG-1'; comment = 'c' }
            } | Out-Null
            $captured.ContentType | Should -Be 'application/json'
            (ConvertFrom-Json -InputObject $captured.Body).testRunName | Should -Be 'CHG-1'
        }
    }

    Context 'retry policy' {
        It 'retries GET three times on 5xx with backoff, then throws' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestHttpException -StatusCode 503 -Message 'Service Unavailable') }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/system/version' 6>$null 3>$null }
            } | Should -Throw '*HTTP 503*after 3 attempts*'
            Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 3 -Exactly
            $sleeps | Should -Be @(2, 4)
        }

        It 'retries GET on transport errors' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestTransportException) }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/system/version' 6>$null 3>$null }
            } | Should -Throw '*transport error*'
            Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 3 -Exactly
        }

        It 'returns the result when a later GET attempt succeeds' {
            $counter = @{ n = 0 }
            Mock -ModuleName LEGate Invoke-RestMethod {
                $counter.n++
                if ($counter.n -lt 2) { throw (New-LEGateTestHttpException -StatusCode 502) }
                [pscustomobject]@{ currentVersion = '6.8.6' }
            }
            $result = InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/system/version' 6>$null 3>$null }
            $result.currentVersion | Should -Be '6.8.6'
            $counter.n | Should -Be 2
        }

        It 'does not retry GET on 4xx' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestHttpException -StatusCode 404 -Message 'Not Found') }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/tests/x' 6>$null }
            } | Should -Throw '*HTTP 404*'
            Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly
            $sleeps.Count | Should -Be 0
        }

        It 'never retries PUT, even on 5xx' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestHttpException -StatusCode 503) }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method PUT -Path '/tests/x/start' -Body @{} 6>$null }
            } | Should -Throw '*HTTP 503*'
            Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly
            $sleeps.Count | Should -Be 0
        }

        It 'never retries POST' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestTransportException) }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method POST -Path '/x' -Body @{} 6>$null }
            } | Should -Throw
            Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly
        }
    }

    Context 'error surfacing' {
        It 'puts the ProblemDetails title and detail in the message and on Data' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestProblemRecord -StatusCode 409 -Title 'Test is already running' -Detail 'Wait for run 42') }
            $caught = $null
            try {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method PUT -Path '/tests/x/start' -Body @{} 6>$null }
            }
            catch { $caught = $_ }
            $caught | Should -Not -BeNullOrEmpty
            $caught.Exception.Message | Should -Match 'PUT /tests/x/start failed: HTTP 409: Test is already running: Wait for run 42'
            $caught.Exception.Data['LEGate.StatusCode'] | Should -Be 409
            $caught.Exception.Data['LEGate.Title'] | Should -Be 'Test is already running'
            $caught.Exception.Data['LEGate.Detail'] | Should -Be 'Wait for run 42'
        }

        It 'falls back to the exception message when there is no ProblemDetails body' {
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestHttpException -StatusCode 401 -Message 'Unauthorized') }
            {
                InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/system/version' 6>$null }
            } | Should -Throw '*HTTP 401*Unauthorized*'
        }
    }

    Context 'token redaction' {
        It 'never lets the token into the error message, the exception data, or the log stream' {
            $token = $script:LEGateTestToken
            Mock -ModuleName LEGate Invoke-RestMethod {
                throw (New-LEGateTestHttpException -StatusCode 401 -Message ("Request with 'Authorization: Bearer $token' was rejected, token $token is invalid"))
            }
            $streams = @(& {
                    try {
                        InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/system/version' }
                    }
                    catch {
                        'CAUGHT: ' + $_.Exception.Message
                        $data = $_.Exception.Data
                        'DATA: ' + (@($data.Keys | ForEach-Object { [string]$data[$_] }) -join ' ')
                    }
                } 6>&1 3>&1 4>&1 | ForEach-Object { [string]$_ })
            $all = $streams -join "`n"
            $all | Should -Match 'CAUGHT: GET /system/version failed: HTTP 401'
            $all | Should -Not -Match ([regex]::Escape($token))
            $all | Should -Match '\[REDACTED\]'
        }

        It 'redacts the token from retry warnings too' {
            $token = $script:LEGateTestToken
            Mock -ModuleName LEGate Invoke-RestMethod { throw (New-LEGateTestTransportException -Message "connect failed for Bearer $token") }
            $warnings = @(& {
                    try { InModuleScope LEGate -Parameters @{ s = $session } { Invoke-LEGateRequest -Session $s -Method GET -Path '/x' } } catch { $null = $_ }
                } 3>&1 6>&1 | ForEach-Object { [string]$_ })
            $warnings.Count | Should -BeGreaterThan 0
            ($warnings -join "`n") | Should -Not -Match ([regex]::Escape($token))
        }
    }
}
