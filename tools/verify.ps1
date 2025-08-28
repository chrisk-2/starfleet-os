Write-Host "=== Starfleet USB Verification ===`n"

$vol = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
if ($vol) {
  Write-Host "Drive: $($vol.DriveLetter):  Label=$($vol.FileSystemLabel)  FS=$($vol.FileSystem)"
  Write-Host "Size: $([math]::Round($vol.Size/1GB,1)) GB  Free: $([math]::Round($vol.SizeRemaining/1GB,1)) GB`n"
} else {
  Write-Warning "Volume D: not found."
  exit 1
}

$repoPath = "D:\starfleet-os"
if (Test-Path (Join-Path $repoPath ".git")) {
  Write-Host "Repo: starfleet-os present ✅"
  git -C $repoPath status
  git -C $repoPath config --get core.autocrlf
  git -C $repoPath config --get core.eol
  git -C $repoPath config --get core.longpaths
} else {
  Write-Warning "No Git repo found at $repoPath ❌"
}
