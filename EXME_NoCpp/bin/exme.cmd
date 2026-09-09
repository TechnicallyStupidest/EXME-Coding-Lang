@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0exme.ps1" %*
exit /b %errorlevel%
