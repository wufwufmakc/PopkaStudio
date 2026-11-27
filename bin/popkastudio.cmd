@echo off
rem Start PopkaStudio on Windows: its helper (studio\studio.py) and the editor in your browser - http://localhost:8466.
rem Ctrl+C here (or closing this window) stops it. Installed by install.ps1 (the Python in .venv, arduino-cli in .tools\bin).
setlocal
set "DIR=%~dp0.."
for %%I in ("%DIR%") do set "DIR=%%~fI"
set "PY=%DIR%\.venv\Scripts\python.exe"
if not exist "%PY%" (
  rem (the installer's download step didn't finish - no internet, closed early: finish it here, in this window)
  echo PopkaStudio's tools are not installed yet - installing them now ^(5-20 minutes the first time^)...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\install.ps1" -Setup
)
if not exist "%PY%" (
  echo.
  echo The install did not finish. Its log: "%DIR%\install.log"
  pause
  exit /b 1
)
set "PATH=%DIR%\.tools\bin;%PATH%"
rem UTF-8 everywhere: the log's dashes and the tools' output (arduino-cli, esptool) - not the console's code page
set "PYTHONUTF8=1"
set "URL=http://localhost:8466"
title PopkaStudio
curl.exe -s -o NUL "%URL%/api/about" >NUL 2>&1 && (
  start "" "%URL%"
  exit /b 0
)
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "Start-Sleep -Milliseconds 1500; Start-Process '%URL%'"
"%PY%" "%DIR%\studio\studio.py" %*
