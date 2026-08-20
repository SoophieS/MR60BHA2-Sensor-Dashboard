$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliVersion = "1.5.1"
$esp32Version = "3.3.11"
$cliDirectory = Join-Path $projectRoot "arduino-cli"
$cliExecutable = Join-Path $cliDirectory "arduino-cli.exe"
$cliArchive = Join-Path $env:TEMP "arduino-cli-$cliVersion-windows.zip"
$cliUrl = "https://github.com/arduino/arduino-cli/releases/download/v$cliVersion/arduino-cli_${cliVersion}_Windows_64bit.zip"
$libraryMarker = Join-Path $projectRoot "Seeed-mmWave-library\library.properties"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found. Install Git for Windows, reopen PowerShell, and retry."
}

if (-not (Test-Path -LiteralPath $libraryMarker)) {
    Write-Host "Initializing the pinned Seeed mmWave library submodule..."
    & git -C $projectRoot submodule update --init --recursive
    if ($LASTEXITCODE -ne 0) { throw "Git submodule initialization failed." }
}

if (-not (Test-Path -LiteralPath $cliExecutable)) {
    New-Item -ItemType Directory -Force -Path $cliDirectory | Out-Null
    Write-Host "Downloading Arduino CLI $cliVersion..."
    Invoke-WebRequest -Uri $cliUrl -OutFile $cliArchive
    Expand-Archive -LiteralPath $cliArchive -DestinationPath $cliDirectory -Force
    Remove-Item -LiteralPath $cliArchive -Force -ErrorAction SilentlyContinue
}

$arduinoEnvironment = Join-Path $projectRoot "arduino-env.cmd"
Write-Host "Installing ESP32 Arduino core $esp32Version..."
& $arduinoEnvironment core update-index
if ($LASTEXITCODE -ne 0) { throw "Arduino package index update failed." }
& $arduinoEnvironment core install "esp32:esp32@$esp32Version"
if ($LASTEXITCODE -ne 0) { throw "ESP32 core installation failed." }

Write-Host "Installing required Arduino libraries..."
& $arduinoEnvironment lib install "Adafruit NeoPixel@1.15.5"
if ($LASTEXITCODE -ne 0) { throw "Adafruit NeoPixel installation failed." }
& $arduinoEnvironment lib install "hp_BH1750@1.0.2"
if ($LASTEXITCODE -ne 0) { throw "hp_BH1750 installation failed." }

if (-not (Get-Command py -ErrorAction SilentlyContinue) -and -not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Warning "Python 3 was not found. Install it before running start-demo.cmd."
}

Write-Host ""
Write-Host "Setup complete. Connect the sensor and identify its port:"
Write-Host "  .\arduino-env.cmd board list"
Write-Host "Then replace COMx with the detected XIAO port:"
Write-Host "  .\start-dashboard.cmd COMx"

