#!/usr/bin/env pwsh
[CmdletBinding()]
param(
    [string]$Address = '127.0.0.1',
    [int]$Port = 8000
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

$venvPython = Join-Path $repoRoot '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
    throw "Virtualenv python not found at $venvPython. Create it with: python -m venv .venv"
}

# Call python -m mkdocs directly to bypass mkdocs.exe launcher,
# which hardcodes the venv path at install time and breaks if the repo is moved/renamed.
& $venvPython -c "import mkdocs" 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "mkdocs not installed in venv. Run: .\.venv\Scripts\python.exe -m pip install -r requirements.txt"
}

Write-Host "Serving docs at http://${Address}:${Port} (livereload on)" -ForegroundColor Cyan
& $venvPython -m mkdocs serve --dev-addr "${Address}:${Port}" --livereload
