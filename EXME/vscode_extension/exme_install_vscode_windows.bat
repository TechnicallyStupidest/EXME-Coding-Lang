@echo off
setlocal EnableExtensions

set "EXTROOT=%USERPROFILE%\.vscode\extensions"
set "DEST=%EXTROOT%\exme.exme-language-2.0.1"

if not exist "%EXTROOT%" mkdir "%EXTROOT%"

rem Remove older manually-installed EXME copies so VS Code cannot keep loading a stale package/icon.
for /d %%D in ("%EXTROOT%\exme.exme-language-*" "%EXTROOT%\exme-language-*" "%EXTROOT%\exme-manual-language-*") do (
    if exist "%%~fD" rmdir /s /q "%%~fD"
)

mkdir "%DEST%"
xcopy /e /i /h /y "%~dp0*" "%DEST%\" >nul
if errorlevel 1 (
    echo EXME extension installation failed.
    exit /b 1
)

if not exist "%DEST%\exme.png" (
    echo EXME logo was not copied. Installation failed.
    exit /b 1
)
if not exist "%DEST%\package.json" (
    echo EXME package.json was not copied. Installation failed.
    exit /b 1
)

echo EXME VS Code extension 2.0.1 installed.
echo Close ALL VS Code windows, then reopen VS Code so its icon cache reloads.
exit /b 0
