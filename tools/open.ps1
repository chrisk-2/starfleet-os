@'
param([switch]$NoCode)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $here
Set-Location -LiteralPath $repo
git status
if (-not $NoCode) {
  $c = Get-Command code -ErrorAction SilentlyContinue
  if ($c) { & code . } else { Write-Host "VS Code not found; staying in shell." }
}
'@ | Set-Content -Path D:\starfleet-os\tools\open.ps1 -Encoding UTF8
