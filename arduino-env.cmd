@echo off
setlocal
if not exist R:\arduino-cli\arduino-cli.exe subst R: "%~dp0"
if not exist R:\arduino-cli\arduino-cli.exe (
  echo R: is already mapped to another location. 1>&2
  exit /b 1
)
R:\arduino-cli\arduino-cli.exe %* --config-file R:\arduino-cli.yaml
exit /b %errorlevel%
