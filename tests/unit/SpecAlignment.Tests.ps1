Describe 'Synthetic responses derived from the reviewed v8-preview specification' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'TestHelpers.ps1')
        Import-LEGateForTest
        $spec = Get-Content (Join-Path $script:LEGateRepoRoot 'docs/api/login-enterprise-v8-preview.openapi.json') -Raw | ConvertFrom-Json
        $session = New-LEGateTestSession
        $synthetic = Join-Path $script:LEGateRepoRoot 'tests/synthetic'
        $responseProfile = Get-Content (Join-Path $synthetic 'response-profile.json') -Raw | ConvertFrom-Json
    }
    BeforeEach {
        $capture = Get-Content (Join-Path $synthetic 'pass.json') -Raw | ConvertFrom-Json
    }
    It 'selects the candidate overview row by run ID, not array position or isBase' {
        $spec.components.schemas.ApplicationTestResultOverview.properties.applicationTestResult.items.'$ref' | Should -Be '#/components/schemas/ApplicationTestData'
        $baseline = $capture.overview.applicationTestResult[0].PSObject.Copy()
        $baseline.testRunId = 'baseline'; $baseline.isBase = $true
        $capture.overview.applicationTestResult[0].isBase = $false
        $capture.overview.applicationTestResult[0].platformSummary = [pscustomobject]@{ loginSuccessful = $false }
        $capture.overview.applicationTestResult = @($baseline, $capture.overview.applicationTestResult[0])
        $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run'
        $n.complete | Should -BeTrue
        $n.loginSuccessful | Should -BeFalse
    }
    It 'rejects absent, duplicate and contradictory candidate overview rows' {
        $capture.overview.applicationTestResult[0].testRunId = 'other'
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
        $capture.overview.applicationTestResult[0].testRunId = 'synthetic-run'
        $capture.overview.applicationTestResult += $capture.overview.applicationTestResult[0]
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
        $capture.overview.applicationTestResult = @($capture.overview.applicationTestResult[0])
        $capture.overview.applicationTestResult[0].testResult = 'cancelled'
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
    }
    It 'uses the baseline in the path and the candidate as the comparison query' {
        Mock -ModuleName LEGate Invoke-RestMethod { [pscustomobject]@{ applicationTestResult = @() } }
        $null = Get-LEGateRunOverview -Session $session -TestRunId 'candidate' -BaselineRunId 'baseline'
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Uri -match '/application-test-run-overview/baseline\?testRunIds=candidate$' }
    }
    It 'collects screenshot metadata once without invented paging parameters and retains binary bytes' {
        $path = '/v8-preview/test-runs/{testRunId}/app-executions/{appExecutionId}/screenshots'
        $spec.paths.$path.get.responses.'200'.content.'application/json'.schema.type | Should -Be 'array'
        @($spec.paths.$path.get.parameters | Where-Object { $_.in -eq 'query' }).Count | Should -Be 0
        $state = @{ metadataCalls = 0 }
        Mock -ModuleName LEGate Invoke-RestMethod {
            if ($Uri -match '\?') { throw 'Screenshot endpoint has no query contract.' }
            if ($OutFile) { [IO.File]::WriteAllBytes($OutFile, [byte[]]@(1, 2, 3)); return }
            $state.metadataCalls++
            return , @([pscustomobject]@{ id = 'screen 1.png'; created = '2026-09-18T00:00:00Z' })
        }
        $executions = @([pscustomobject]@{ id = 'exec-1'; state = 'endedWithErrors' })
        $records = @(Get-LEGateRunScreenshot -Session $session -TestRunId 'run-1' -Executions $executions -ResponseMap $responseProfile -CaptureRoot $TestDrive)
        $state.metadataCalls | Should -Be 1
        $records.Count | Should -Be 1
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { ([uri]$Uri).AbsoluteUri -match '/screen%201\.png$' -and $OutFile -match '[a-f0-9]{64}\.bin$' }
        [IO.File]::ReadAllBytes((Join-Path $TestDrive $records[0].path)) | Should -Be @([byte]1, [byte]2, [byte]3)
    }
    It 'reads native eventType and blocks capacity failures and contradictory application failures' {
        $actualTypes = InModuleScope LEGate { Get-LEGateEventType }
        @($actualTypes | Sort-Object) | Should -Be @($spec.components.schemas.EventType.enum | Sort-Object)
        $spec.components.schemas.Event.properties.eventType.'$ref' | Should -Be '#/components/schemas/EventType'
        foreach ($kind in @('launcherCapacityExceeded', 'accountCapacityExceeded', 'sessionDiscoveryError', 'licenseSessionLimit', 'appExecutionAbandoned')) {
            $spec.components.schemas.EventType.enum | Should -Contain $kind
            $capture.events = @([pscustomobject]@{ eventType = $kind; testRunId = 'synthetic-run' })
            $n = ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run'
            $n.infrastructureFailure | Should -BeTrue
        }
        $capture.events = @([pscustomobject]@{ eventType = 'applicationFailure'; applicationId = 'demo-app' })
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
        $capture.events = @([pscustomobject]@{ eventType = 'testRunFinished'; testRunId = 'other' })
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
    }
    It 'rejects screenshot dot segments before a download can escape its endpoint' {
        $state = @{ screenshotId = '.' }
        Mock -ModuleName LEGate Invoke-RestMethod {
            return , @([pscustomobject]@{ id = $state.screenshotId })
        }
        $executions = @([pscustomobject]@{ id = 'exec-1'; state = 'endedWithErrors' })
        foreach ($segment in @('.', '..')) {
            $state.screenshotId = $segment
            { Get-LEGateRunScreenshot -Session $session -TestRunId 'run-1' -Executions $executions -ResponseMap $responseProfile -CaptureRoot $TestDrive } | Should -Throw '*dot segment*'
        }
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 0 -Exactly -ParameterFilter { $OutFile }
    }
    It 'resolves continuous tests without the unsupported text filter and verifies enabled scheduling after start' {
        $spec.components.schemas.ContinuousTest.allOf[1].properties.PSObject.Properties.Name | Should -Contain 'isEnabled'
        $spec.components.schemas.ContinuousTest.allOf[1].properties.PSObject.Properties.Name | Should -Not -Contain 'state'
        $state = @{ enabled = $false }
        Mock -ModuleName LEGate Invoke-RestMethod {
            if ($Uri -match 'filter=') { throw 'Unsupported continuous name filter.' }
            $test = [pscustomobject]@{ id = 'continuous-1'; name = 'existing'; isEnabled = $state.enabled }
            if ($Method -eq 'PUT') { $state.enabled = $true; return [pscustomobject]@{ id = 'started-run' } }
            if ($Uri -match '/tests/continuous-1$') { return $test }
            return New-LEGatePage -Items @($test) -TotalCount 1
        }
        (Start-LEGateContinuousTest -Session $session -Name 'existing').succeeded | Should -BeTrue
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'GET' -and $Uri -match '/tests/continuous-1$' }
        (Start-LEGateContinuousTest -Session $session -Name 'existing').alreadyRunning | Should -BeTrue
        Should -Invoke -ModuleName LEGate Invoke-RestMethod -Times 1 -Exactly -ParameterFilter { $Method -eq 'PUT' }
    }
    It 'rejects unknown event enums and malformed supplied event relationships' {
        foreach ($field in @('testRunId', 'userSessionId', 'applicationId')) {
            foreach ($value in @('', @('synthetic-run'), [pscustomobject]@{ id = 'synthetic-run' })) {
                $testEvent = [pscustomobject]@{ eventType = 'testRunFinished' }
                $testEvent | Add-Member -NotePropertyName $field -NotePropertyValue $value
                $capture.events = @($testEvent)
                (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
            }
        }
        $capture.events = @([pscustomobject]@{ eventType = 'futureUnknownEvent' })
        (ConvertTo-LEGateResult -Capture $capture -ResponseMap $responseProfile -TestRunId 'synthetic-run').complete | Should -BeFalse
    }
    It 'fails continuous handoff when start is accepted but enabled scheduling is not confirmed' {
        Mock -ModuleName LEGate Invoke-RestMethod {
            $test = [pscustomobject]@{ id = 'continuous-1'; name = 'existing'; isEnabled = $false }
            if ($Method -eq 'PUT') { return [pscustomobject]@{ id = 'started-run' } }
            if ($Uri -match '/tests/continuous-1$') { return $test }
            return New-LEGatePage -Items @($test) -TotalCount 1
        }
        { Start-LEGateContinuousTest -Session $session -Name 'existing' } | Should -Throw '*not confirmed*'
    }
}
