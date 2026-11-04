@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\dev\play-school.ps1" -Integrated %*
