@echo off
setlocal
set "RADAR_PORT=%~1"
if "%RADAR_PORT%"=="" set "RADAR_PORT=COM4"

call "%~dp0restore-robot-probe.cmd" %RADAR_PORT%
if errorlevel 1 exit /b %errorlevel%

pushd "%~dp0radar_dashboard"
where py >nul 2>nul
if not errorlevel 1 (
  start "MR60BHA2 Dashboard Server" /min py -m http.server 8765 --bind 127.0.0.1
) else (
  start "MR60BHA2 Dashboard Server" /min python -m http.server 8765 --bind 127.0.0.1
)
popd

timeout /t 2 /nobreak >nul
start "" msedge "http://localhost:8765"
