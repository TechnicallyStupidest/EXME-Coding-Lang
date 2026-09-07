@echo off
setlocal
cd /d "%~dp0"
g++ exme_main.cpp exme_manual.cpp -O3 -std=c++17 -DNDEBUG -s -o exme.exe
if errorlevel 1 exit /b %errorlevel%
