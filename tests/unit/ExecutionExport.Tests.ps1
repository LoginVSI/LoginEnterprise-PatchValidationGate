Describe 'Pinned execution repository export' {
    BeforeAll {
        $repositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        # Isolate a development-source fixture so these tests also run in generated copies.
        $sourceRoot = Join-Path $TestDrive 'development-source'
        $null = New-Item -ItemType Directory -Path (Join-Path $sourceRoot 'scripts') -Force
        $null = New-Item -ItemType Directory -Path (Join-Path $sourceRoot '.github/workflows') -Force
        $exportScript = Join-Path $sourceRoot 'scripts/Export-ExecutionRepository.ps1'
        Copy-Item (Join-Path $repositoryRoot 'scripts/Export-ExecutionRepository.ps1') $exportScript
        $sourceWorkflow = Get-Content (Join-Path $repositoryRoot '.github/workflows/validate-patch.yml') -Raw
        $sourceWorkflow = $sourceWorkflow -replace "github.repository == '[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+'", "github.repository == 'LoginVSI/LoginEnterprise-PatchValidationGate'"
        Set-Content (Join-Path $sourceRoot '.github/workflows/validate-patch.yml') $sourceWorkflow -Encoding utf8
        # This fixture models development CI even when tests run in a public export.
        $ciWorkflow = Get-Content (Join-Path $repositoryRoot '.github/workflows/ci.yml') -Raw
        if ($ciWorkflow -notmatch '(?m)^  pull_request:') { $ciWorkflow = $ciWorkflow -replace '(?m)^permissions:', "  pull_request:`npermissions:" }
        Set-Content (Join-Path $sourceRoot '.github/workflows/ci.yml') $ciWorkflow -Encoding utf8
        git -C $sourceRoot init --quiet
        git -C $sourceRoot add -- .
        git -C $sourceRoot -c user.name=Fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false commit --quiet -m 'Synthetic export source'
        if ($LASTEXITCODE -ne 0) { throw 'Could not prepare isolated Git fixture.' }
        $sourceCommit = git -C $sourceRoot rev-parse HEAD
    }
    It 'exports a pinned commit with one exact repository guard and unchanged main restriction' {
        $destination = Join-Path $TestDrive 'execution-copy'
        & $exportScript -Repository 'example-owner/private-execution' -SourceCommit $sourceCommit -Destination $destination
        $workflow = Get-Content (Join-Path $destination '.github/workflows/validate-patch.yml') -Raw
        $workflow | Should -Match "github.ref == 'refs/heads/main' && github.repository == 'example-owner/private-execution'"
        $workflow | Should -Not -Match "github.repository == 'LoginVSI/LoginEnterprise-PatchValidationGate'"
        $metadata = Get-Content (Join-Path $destination 'execution-source.json') -Raw | ConvertFrom-Json
        $metadata.sourceCommit | Should -Be $sourceCommit
        $metadata.allowedRef | Should -Be 'refs/heads/main'
        { & $exportScript -Repository 'example-owner/private-execution' -SourceCommit $sourceCommit -Destination $destination } | Should -Throw '*already exists*'
    }
    It 'rejects an expression injection as the repository name' {
        { & $exportScript -Repository "owner/repo' || true" -SourceCommit $sourceCommit -Destination (Join-Path $TestDrive 'invalid') } | Should -Throw
    }
    It 'omits untrusted PR execution only from explicitly public exports' {
        $destination = Join-Path $TestDrive 'public-copy'
        & $exportScript -Repository 'example-owner/public-execution' -SourceCommit $sourceCommit -Destination $destination -PublicRepository
        $ci = Get-Content (Join-Path $destination '.github/workflows/ci.yml') -Raw
        $ci | Should -Not -Match 'pull_request'
        $ci | Should -Match "branches: \[main, 'chore/sync-\*'\]"
        $ci | Should -Match 'runs-on: windows-latest'
        (Get-Content (Join-Path $sourceRoot '.github/workflows/ci.yml') -Raw) | Should -Match 'pull_request:'
        $metadata = Get-Content (Join-Path $destination 'execution-source.json') -Raw | ConvertFrom-Json
        $metadata.publicRepository | Should -BeTrue
    }
    It 'rejects the development destination irrespective of casing' {
        { & $exportScript -Repository 'loginvsi/loginenterprise-patchvalidationgate' -SourceCommit $sourceCommit -Destination (Join-Path $TestDrive 'self') } | Should -Throw '*separate execution*'
    }
}
