@echo off
setlocal EnableExtensions

set "INSTALL=%LOCALAPPDATA%\EXME"
set "BIN=%INSTALL%\bin"
set "EXTROOT=%USERPROFILE%\.vscode\extensions"
set "EXTDEST=%EXTROOT%\exme.exme-language-2.1.0"

echo Installing EXME...

if not exist "%INSTALL%" mkdir "%INSTALL%"
if not exist "%BIN%" mkdir "%BIN%"

copy /y "%~dp0bin\exme.cmd" "%BIN%\exme.cmd" >nul || goto :fail
copy /y "%~dp0bin\exme.ps1" "%BIN%\exme.ps1" >nul || goto :fail
copy /y "%~dp0exme.png" "%INSTALL%\exme.png" >nul || goto :fail

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$bin=[IO.Path]::GetFullPath('%BIN%'); $p=[Environment]::GetEnvironmentVariable('Path','User'); if([string]::IsNullOrEmpty($p)){$p=''}; $parts=$p -split ';' | Where-Object { $_ -ne '' }; if(-not ($parts | Where-Object { [IO.Path]::GetFullPath($_).TrimEnd('\') -ieq $bin.TrimEnd('\') })) { [Environment]::SetEnvironmentVariable('Path', (($parts + $bin) -join ';'), 'User') }"
if errorlevel 1 goto :fail

if not exist "%EXTROOT%" mkdir "%EXTROOT%"
for /d %%D in ("%EXTROOT%\exme.exme-language-*" "%EXTROOT%\exme-language-*" "%EXTROOT%\exme-manual-language-*") do (
    if exist "%%~fD" rmdir /s /q "%%~fD"
)
mkdir "%EXTDEST%" || goto :fail
xcopy /e /i /h /y "%~dp0vscode_extension\*" "%EXTDEST%\" >nul || goto :fail

if not exist "%EXTDEST%\exme.png" goto :fail
if not exist "%EXTDEST%\package.json" goto :fail

echo.
echo EXME installed successfully.
echo.
echo Close ALL VS Code windows and terminal windows, then reopen them.
echo After reopening, try:
echo     exme --version
echo.
echo No C++, g++, MinGW, or Visual Studio compiler is required.
exit /b 0

:fail
echo.
echo EXME installation failed.
exit /b 1
