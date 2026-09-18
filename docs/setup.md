# Setup

Use Windows PowerShell 5.1 or PowerShell 7 on Windows. Tests need Pester 5; lint needs PSScriptAnalyzer. No SDK or PSLoginEnterprise.

```powershell
$PSVersionTable
Get-Module -ListAvailable Pester,PSScriptAnalyzer
Get-ExecutionPolicy -List
```

If needed, use scripts/Initialize-DevEnvironment.ps1 under approved installation policy. PS7 lint can discover an existing WindowsPowerShell user installation. Do not weaken machine or organizational execution policy. Where permitted, use process-scoped RemoteSigned:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File tests/Invoke-Tests.ps1 -Output Normal
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File scripts/Invoke-Lint.ps1
pwsh -NoProfile -File tests/Invoke-Tests.ps1 -Output Normal
pwsh -NoProfile -File scripts/Invoke-Lint.ps1
```

Pester uses temporary files and registry entries. Request normal access approval if sandbox restrictions block them. NUnit output stays private in ignored tests/results; CI publishes only count summaries.

Static checks require Python and PyYAML:

```powershell
py -m pip install --target .private/python PyYAML==6.0.3
py scripts/Test-RepositoryArtifacts.py
```

These check YAML, pins, gates and skill structure/examples. They do not execute Actions or evaluate an AI model.

Live prerequisites are in the [runbook](runbook.md). Certificate flags accept empty/0/false or 1/true. Prefer valid trust. PS7 supports an appliance-request-only exception; PS5.1 rejects skipping. GitHub and installer TLS validation is always enabled.
