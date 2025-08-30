Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Write-Host "== Verify (Windows) =="
@("archiso","roles","scripts","system") | ForEach-Object {
  if (-not (Test-Path $_)) { Write-Warning "Missing: $_" } else { Write-Host "OK: $_" -ForegroundColor Green }
}
if (-not (Test-Path ".github/workflows/build-iso.yml")) { Write-Warning "Missing CI workflow"; }
Write-Host "Tip: run scripts under WSL for mkarchiso, or build on Arch."
