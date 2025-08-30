<# Starfleet OS Repo Verifier (PowerShell)
   Checks structure, roles, packages, firstboot, archiso base, CI, and scripts.
   Usage:
     .\tools\verify_repo.ps1
     .\tools\verify_repo.ps1 -Role server
     .\tools\verify_repo.ps1 -NoStrict
#>
[CmdletBinding()]
param(
  [ValidateSet('server','control','drone')]
  [string]$Role,
  [switch]$NoStrict
)
$ErrorActionPreference = 'Stop'
function Write-Color($t,$c){ Write-Host $t -ForegroundColor $c }
function Pass($m){ $script:PASS += $m }
function Warn($m){ $script:WARN += $m }
function Fail($m){ $script:FAIL += $m }
$PASS=@(); $WARN=@(); $FAIL=@()
function D($p){ Test-Path $p -PathType Container }
function F($p){ Test-Path $p -PathType Leaf }

Write-Color "== Top-level structure ==" Cyan
$needDirs = @('archiso','roles','scripts','system')
foreach($d in $needDirs){ if(D $d){ Pass "dir: $d" } else { Fail "missing dir: $d" } }

if(F ".github/workflows/build-iso.yml"){ Pass "CI workflow ok" } else { Warn "CI workflow missing: .github/workflows/build-iso.yml" }

Write-Color "`n== ArchISO base/profile ==" Cyan
$Base="archiso/base"; $Profile="archiso/profiles/starfleet"
if(D $Base){
  Pass "base dir: $Base"
  foreach($f in @("$Base/profiledef.sh","$Base/packages.x86_64")){
    if(F $f){ Pass "base file: $f" } else { Warn "missing: $f" }
  }
  if(F "$Base/profiledef.sh"){
    $head = (Get-Content "$Base/profiledef.sh" -TotalCount 1) -join ''
    if($head -match '^\#\!' -or (Select-String -Path "$Base/profiledef.sh" -SimpleMatch 'iso_name=' -Quiet)){
      Pass "profiledef.sh looks sane"
    } else { Warn "profiledef.sh header looks odd (no shebang/iso_name)" }
  }
} else { Warn "base dir missing: $Base (repair script can scaffold it)" }

if(D $Profile){ Pass "composed profile present: $Profile" } else { Warn "composed profile not generated (run scripts/merge_role.sh <role>)" }

Write-Color "`n== Roles ==" Cyan
$roles = @('server','control','drone')
if($PSBoundParameters.ContainsKey('Role')){ $roles=@($Role) }
foreach($r in $roles){
  $rdir="roles/$r"
  if(-not (D $rdir)){ Fail "role dir missing: $rdir"; continue }
  Pass "role dir: $rdir"
  $pfile="$rdir/packages.txt"
  if(F $pfile){
    $lines=Get-Content $pfile
    if(-not $lines){ Fail "empty packages.txt: $pfile" }
    $bad=@()
    for($i=0;$i -lt $lines.Count;$i++){
      $line=$lines[$i].Trim()
      if($line -eq '' -or $line.StartsWith('#')){ continue }
      if($line -notmatch '^[A-Za-z0-9@._+-]+$'){ $bad+=("{0}:{1}" -f ($i+1),$line) }
    }
    if($bad.Count){ Fail ("invalid tokens in {0}: {1}" -f $pfile, ($bad -join '; ')) }
    $pkgs = $lines | ?{ $_ -and -not $_.StartsWith('#') } | % { $_.Trim() }
    $dups = $pkgs | Group-Object | ?{ $_.Count -gt 1 } | % { $_.Name }
    if($dups){ Warn ("duplicate packages in {0}: {1}" -f $pfile, ($dups -join ', ')) } else { Pass "packages.txt ok: $pfile" }
  } else { Fail "missing packages.txt: $pfile" }
  $odir="$rdir/overlay"
  if(D $odir){ Pass "overlay: $odir" } else { Warn "overlay missing (ok if package-only): $odir" }
}

Write-Color "`n== Firstboot (system/firstboot) ==" Cyan
$fdir="system/firstboot"; $unit="$fdir/starfleet-firstboot.service"; $script="$fdir/starfleet-firstboot.sh"
if(D $fdir){ Pass "firstboot dir: $fdir" } else { Warn "firstboot dir missing: $fdir" }
if(F $unit){
  Pass "unit present: $unit"
  $txt=(Get-Content $unit) -join "`n"
  $need=@('[Unit]','[Service]','[Install]'); $miss=$need | ?{ $txt -notmatch [regex]::Escape($_) }
  if($miss){ Fail ("unit missing sections: {0}" -f ($miss -join ', ')) } else { Pass "unit sections ok" }
} else { Warn "unit missing: $unit" }
if(F $script){
  Pass "script present: $script"
  $h=(Get-Content $script -TotalCount 1) -join ''
  if($h -match '^\#\!'){ Pass "script has shebang" } else { Warn "script missing shebang (#!/usr/bin/env bash)" }
} else { Warn "firstboot script missing: $script" }

Write-Color "`n== Build scripts ==" Cyan
foreach($s in @("scripts/merge_role.sh","scripts/build_iso_local.sh","scripts/verify_repo.sh")){
  if(F $s){ Pass "script present: $s" } else { Warn "script missing: $s" }
}

Write-Color "`n== Tooling hints ==" Cyan
if(Get-Command wsl -ErrorAction SilentlyContinue){ Pass "WSL detected" } else { Warn "WSL not detected (use Docker/CI or an Arch host)" }
if(Get-Command docker -ErrorAction SilentlyContinue){ Pass "Docker detected" } else { Warn "Docker not found (container builds unavailable)" }

Write-Host ""
Write-Color "======== VERIFY SUMMARY ========" Magenta
if($PASS.Count){ Write-Color "PASS:" Green; $PASS | % { "  • $_" | Write-Host } }
if($WARN.Count){ Write-Color "WARN:" Yellow; $WARN | % { "  • $_" | Write-Host } }
if($FAIL.Count){ Write-Color "FAIL:" Red;  $FAIL | % { "  • $_" | Write-Host } }

if($FAIL.Count -and -not $NoStrict){ Write-Color "Exit: FAIL (strict). Fix or run repair, then re-run verify." Red; exit 1 }
Write-Color ("Exit: {0}" -f (if($FAIL.Count){"WARN (non-strict)"}else{"OK"})) Green
exit 0
