# MR60BHA2 local test environment

This directory contains a project-local Arduino CLI environment for the Seeed
MR60BHA2 + XIAO ESP32C6 kit. It does not change the machine-wide Arduino
configuration.

## Quick start on a new Windows PC

Clone this repository with its pinned Seeed library dependency, then run the
setup script in PowerShell:

```powershell
git clone --recurse-submodules <repository-url>
cd <repository-directory>
.\setup-windows.ps1
.\start-dashboard.cmd COM4
```

If the repository was cloned without `--recurse-submodules`, initialize the
dependency with `git submodule update --init --recursive`. Replace `COM4` with
the XIAO port reported by `.\arduino-env.cmd board list`.

## Layout

- `Seeed-mmWave-library/`: upstream library cloned from the requested GitHub repository.
- `arduino-cli/arduino-cli.exe`: project-local stable Arduino CLI.
- `arduino-cli.yaml`: project-local board/package/cache configuration.
- `robot_probe/robot_probe.ino`: JSON Lines probe for radar, targets, firmware, and light.

## Commands (PowerShell, from this directory)

```powershell
.\arduino-env.cmd board list
.\arduino-env.cmd compile --fqbn 'esp32:esp32:XIAO_ESP32C6:CDCOnBoot=cdc' --library 'R:\Seeed-mmWave-library' 'R:\robot_probe'

# Replace COMx only after `board list` identifies the XIAO board.
.\arduino-env.cmd compile --upload --port COMx --fqbn 'esp32:esp32:XIAO_ESP32C6:CDCOnBoot=cdc' --library 'R:\Seeed-mmWave-library' 'R:\robot_probe'
.\arduino-env.cmd monitor --port COMx --config baudrate=115200
```

`arduino-env.cmd` creates the temporary `R:` mapping required to avoid a
Windows ESP32 linker bug with non-ASCII workspace paths, then runs Arduino CLI.

Do not use COM3 on this computer unless it is later identified as the XIAO;
the initial check showed COM3 is Intel Active Management Technology SOL.

The probe emits one JSON object per line. Event kinds include `phase`,
`breath_rate`, `heart_rate`, `distance`, `presence`, `targets`, `firmware`,
`illuminance`, and `status`.

`distance.cm` is the vital-sign ranging field in centimetres. Target `x_m`
and `y_m` coordinates are in metres, and `speed_cm_s` is centimetres/second.

## Official radar GUI

The official Seeed GUI and OTA packages are under `tools/`. The GUI needs the
XIAO to run the upstream `passthrough_mode` sketch, because it expects raw
TinyFrame bytes rather than the JSON output from `robot_probe`.

```powershell
# Flash passthrough mode and launch the Seeed GUI (COM4 is the default).
.\start-radar-gui.cmd COM4

# Restore the JSON Lines robot probe afterwards.
.\restore-robot-probe.cmd COM4
```

In the GUI select `COM4`, baud `115200`, then connect/start acquisition. Do not
use the separate OTA application's `Request Update` button unless a deliberate
radar firmware upgrade has been planned. Both downloaded executables are
unsigned, although the ZIP files came directly from Seeed's official server.

## Advanced local dashboard

`radar_dashboard/` is a presentation-oriented local dashboard with a radar
field-of-view plot, targets, stable/raw counts, vital-sign cards, and a
60-second trend chart. It reads `robot_probe` JSON Lines with Edge/Chrome Web
Serial.

```powershell
.\start-dashboard.cmd COM4
```

After the browser opens, click **连接传感器** and select the XIAO serial port.
The dashboard also has a hardware-free demo mode.
