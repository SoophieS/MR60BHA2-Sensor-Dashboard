$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$cliVersion = "1.5.1"
$cliDirectory = Join-Path $projectRoot "arduino-cli"
$cliExecutable = Join-Path $cliDirectory "arduino-cli.exe"
$cliArchive = Join-Path $env:TEMP "arduino-cli-$cliVersion-windows.zip"
$cliUrl = "https://github.com/arduino/arduino-cli/releases/download/v$cliVersion/arduino-cli_${cliVersion}_Windows_64bit.zip"

if (-not (Test-Path -LiteralPath $cliExecutable)) {
    New-Item -ItemType Directory -Force -Path $cliDirectory | Out-Null
    Write-Host "Downloading Arduino CLI $cliVersion..."
    Invoke-WebRequest -Uri $cliUrl -OutFile $cliArchive
    Expand-Archive -LiteralPath $cliArchive -DestinationPath $cliDirectory -Force
}

if (-not (Test-Path -LiteralPath (Join-Path $projectRoot "Seeed-mmWave-library"))) {
    Write-Host "Cloning the pinned Seeed mmWave library submodule..."
    git -C $projectRoot submodule update --init --recursive
}

$arduinoEnvironment = Join-Path $projectRoot "arduino-env.cmd"
Write-Host "Installing ESP32 Arduino core 3.3.11..."
& $arduinoEnvironment core update-index
& $arduinoEnvironment core install "esp32:esp32@3.3.11"

Write-Host "Installing required Arduino libraries..."
& $arduinoEnvironment lib install "Adafruit NeoPixel@1.15.5"
& $arduinoEnvironment lib install "hp_BH1750@1.0.2"

Write-Host "Setup complete. Connect the sensor and run:"
Write-Host "  .\start-dashboard.cmd COM4"

