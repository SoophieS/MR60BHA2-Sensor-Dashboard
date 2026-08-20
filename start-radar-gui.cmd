@echo off
setlocal
set "RADAR_PORT=%~1"
if "%RADAR_PORT%"=="" set "RADAR_PORT=COM4"

call "%~dp0arduino-env.cmd" compile --upload --port %RADAR_PORT% --fqbn esp32:esp32:XIAO_ESP32C6:CDCOnBoot=cdc --library R:\Seeed-mmWave-library R:\Seeed-mmWave-library\examples\passthrough_mode
if errorlevel 1 exit /b %errorlevel%

pushd "%~dp0tools\MR60BHA2_GUI\Seeed Studio mmWave Sensor GUI EN"
start "" "new_gui_clean.exe"
popd
