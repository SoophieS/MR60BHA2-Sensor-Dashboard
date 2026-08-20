@echo off
setlocal
set "RADAR_PORT=%~1"
if "%RADAR_PORT%"=="" set "RADAR_PORT=COM4"

call "%~dp0restore-robot-probe.cmd" %RADAR_PORT%
if errorlevel 1 exit /b %errorlevel%
call "%~dp0start-demo.cmd"
exit /b %errorlevel%
