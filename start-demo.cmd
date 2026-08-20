@echo off
setlocal

pushd "%~dp0radar_dashboard"
where py >nul 2>nul
if not errorlevel 1 (
  start "MR60BHA2 Dashboard Server" /min py -m http.server 8765 --bind 127.0.0.1
) else (
  where python >nul 2>nul
  if errorlevel 1 (
    echo Python 3 was not found. Install it from https://www.python.org/downloads/windows/ 1>&2
    popd
    exit /b 1
  )
  start "MR60BHA2 Dashboard Server" /min python -m http.server 8765 --bind 127.0.0.1
)
popd

timeout /t 2 /nobreak >nul
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" "http://localhost:8765"
) else if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
  start "" "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" "http://localhost:8765"
) else (
  if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" (
    start "" "%ProgramFiles%\Google\Chrome\Application\chrome.exe" "http://localhost:8765"
  ) else if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" (
    start "" "%LocalAppData%\Google\Chrome\Application\chrome.exe" "http://localhost:8765"
  ) else (
    start "" "http://localhost:8765"
  )
)
