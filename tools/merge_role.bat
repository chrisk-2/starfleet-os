@echo off
set ROLE=%1
if "%ROLE%"=="" set ROLE=server
wsl bash -lc "./scripts/merge_role.sh %ROLE%"
pause
