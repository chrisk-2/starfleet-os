@echo off
set ROLE=%1
if "%ROLE%"=="" set ROLE=server
wsl bash -lc "./scripts/build_iso_local.sh %ROLE%"
pause
