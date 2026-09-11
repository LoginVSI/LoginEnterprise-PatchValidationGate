Describe 'LEGate module' {
    BeforeAll {
        . (Join-Path -Path $PSScriptRoot -ChildPath 'TestHelpers.ps1')
        Import-LEGateForTest
        $manifest = Test-ModuleManifest -Path $script:LEGateManifestPath -ErrorAction Stop
        $publicFolder = Join-Path -Path $script:LEGateRepoRoot -ChildPath 'src\LEGate\Public'
        $privateFolder = Join-Path -Path $script:LEGateRepoRoot -ChildPath 'src\LEGate\Private'
    }

    It 'has a valid manifest at version 0.1.0 for PowerShell 5.1' {
        $manifest.Version.ToString() | Should -Be '0.1.0'
        $manifest.PowerShellVersion.ToString() | Should -Be '5.1'
    }

    It 'exports exactly the functions in Public and nothing else' {
        $expected = @(Get-ChildItem -Path $publicFolder -Filter *.ps1 | ForEach-Object { $_.BaseName } | Sort-Object)
        $exported = @((Get-Command -Module LEGate).Name | Sort-Object)
        $exported | Should -Be $expected
        @($manifest.ExportedFunctions.Keys | Sort-Object) | Should -Be $expected
    }

    It 'names every public function Verb-LEGate*' {
        foreach ($file in Get-ChildItem -Path $publicFolder -Filter *.ps1) {
            $file.BaseName | Should -Match '^[A-Z][a-z]+-LEGate([A-Z][A-Za-z]*)?$'
        }
    }

    It 'does not export private helpers' {
        foreach ($file in Get-ChildItem -Path $privateFolder -Filter *.ps1) {
            Get-Command -Name $file.BaseName -Module LEGate -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        }
    }

    It 'defines one function per file with a matching name' {
        foreach ($file in (Get-ChildItem -Path $publicFolder, $privateFolder -Filter *.ps1)) {
            $tokens = $null
            $errors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
            $errors | Should -BeNullOrEmpty
            $functions = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false))
            $functions.Count | Should -Be 1 -Because "$($file.Name) should define one function"
            $functions[0].Name | Should -Be $file.BaseName
        }
    }

    It 'contains no PowerShell 7 only syntax' {
        $pattern = '\?\?|\?\.|\s\?\s.*\s:\s|-Parallel'
        foreach ($file in (Get-ChildItem -Path $publicFolder, $privateFolder -Filter *.ps1)) {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            $code = ($tokens | Where-Object { $_.Kind -ne 'Comment' } | ForEach-Object { $_.Text }) -join ' '
            $code | Should -Not -Match $pattern -Because "$($file.Name) must run on 5.1"
        }
    }
}
