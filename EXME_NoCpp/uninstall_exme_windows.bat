@echo off
setlocal EnableExtensions
set "INSTALL=%LOCALAPPDATA%\EXME"
set "BIN=%INSTALL%\bin"
set "EXTROOT=%USERPROFILE%\.vscode\extensions"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "$bin=[IO.Path]::GetFullPath('%BIN%').TrimEnd('\'); $p=[Environment]::GetEnvironmentVariable('Path','User'); if($p){ $new=(($p -split ';') | Where-Object { $_ -and ([IO.Path]::GetFullPath($_).TrimEnd('\') -ine $bin) }) -join ';'; [Environment]::SetEnvironmentVariable('Path',$new,'User') }"

if exist "%INSTALL%" rmdir /s /q "%INSTALL%"
for /d %%D in ("%EXTROOT%\exme.exme-language-*" "%EXTROOT%\exme-language-*" "%EXTROOT%\exme-manual-language-*") do (
    if exist "%%~fD" rmdir /s /q "%%~fD"
)

echo EXME uninstalled. Reopen terminals and VS Code.
exit /b 0
