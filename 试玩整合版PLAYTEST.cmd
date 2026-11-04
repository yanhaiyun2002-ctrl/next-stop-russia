@echo off
echo [LEGACY P1 BUILD] This is NOT School V0.4-R2. Use the School V04 or Integrated V04 launcher for the latest school.
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "scripts\dev\play-integrated.ps1" %*
