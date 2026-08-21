@echo off
setlocal
set "RADAR_PORT=%~1"
if "%RADAR_PORT%"=="" set "RADAR_PORT=COM4"

call "%~dp0arduino-env.cmd" compile --upload --port %RADAR_PORT% --fqbn esp32:esp32:XIAO_ESP32C6:CDCOnBoot=cdc --library R:\Seeed-mmWave-library R:\Seeed-mmWave-library\examples\passthrough_mode
if errorlevel 1 exit /b %errorlevel%

set "OTA_DIR=%~dp0tools\MR60BHA2_OTA"
set "OTA_EXE=%OTA_DIR%\Seeed OTA.exe"
if not exist "%OTA_EXE%" (
  echo OTA tool not found: "%OTA_EXE%" 1>&2
  exit /b 1
)

start "" /D "%OTA_DIR%" "%OTA_EXE%"
echo Select %RADAR_PORT%, set 115200 baud, choose OTA Mode, and click CONNECT.
echo Use GET RADAR INFO before REQUEST UPDATE.
