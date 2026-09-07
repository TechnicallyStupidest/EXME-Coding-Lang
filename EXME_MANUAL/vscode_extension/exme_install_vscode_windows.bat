@echo off
setlocal
set "DEST=%USERPROFILE%\.vscode\extensions\exme-manual-language-2.0.0"
if exist "%DEST%" rmdir /s /q "%DEST%"
mkdir "%DEST%"
xcopy /e /i /y "%~dp0*" "%DEST%\" >nul
if errorlevel 1 exit /b %errorlevel%
echo EXME Manual VS Code extension installed. Restart VS Code.
