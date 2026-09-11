# Contributing

Thanks for looking. The full guide is in [docs/contributing.md](docs/contributing.md). It covers branch naming, the one function per file rule, the tests every public function needs, and how fixtures are captured and sanitized.

Before opening a pull request, run these from the repo root in Windows PowerShell 5.1:

```powershell
.\scripts\Initialize-DevEnvironment.ps1
.\scripts\Invoke-Lint.ps1
.\tests\Invoke-Tests.ps1
```

CI runs the same two commands on a hosted Windows runner with no appliance.
