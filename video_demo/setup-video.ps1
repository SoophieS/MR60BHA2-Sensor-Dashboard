$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolDirectory = Join-Path $scriptRoot "tools"
$ffmpeg = Join-Path $toolDirectory "ffmpeg.exe"
if (Test-Path -LiteralPath $ffmpeg) {
    Write-Host "FFmpeg is already available: $ffmpeg"
    exit 0
}

$archiveUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
$temporaryRoot = Join-Path $env:TEMP "mr60bha2-ffmpeg-$PID"
$archive = Join-Path $temporaryRoot "ffmpeg.zip"
$unpackDirectory = Join-Path $temporaryRoot "unpacked"

New-Item -ItemType Directory -Force -Path $toolDirectory, $unpackDirectory | Out-Null
try {
    Write-Host "Downloading the portable FFmpeg Windows build..."
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive
    Expand-Archive -LiteralPath $archive -DestinationPath $unpackDirectory -Force
    $downloadedExecutable = Get-ChildItem -LiteralPath $unpackDirectory -Recurse -Filter "ffmpeg.exe" -File | Select-Object -First 1
    if (-not $downloadedExecutable) { throw "ffmpeg.exe was not found in the downloaded archive." }
    Copy-Item -LiteralPath $downloadedExecutable.FullName -Destination $ffmpeg -Force
}
finally {
    $resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
    $resolvedSystemTemp = [IO.Path]::GetFullPath($env:TEMP)
    if ($resolvedTemporaryRoot.StartsWith($resolvedSystemTemp, [StringComparison]::OrdinalIgnoreCase) -and (Test-Path -LiteralPath $resolvedTemporaryRoot)) {
        Remove-Item -LiteralPath $resolvedTemporaryRoot -Recurse -Force
    }
}

& $ffmpeg -version | Select-Object -First 1
Write-Host "Video environment is ready."

