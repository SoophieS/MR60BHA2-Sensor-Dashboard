# Optional Seeed desktop tools

Large third-party GUI and OTA binaries are intentionally excluded from this
repository. Download them from the official Seeed MR60BHA2 documentation:

https://wiki.seeedstudio.com/getting_started_with_mr60bha2_mmwave_kit/#resources

To use `start-radar-gui.cmd`, extract the official GUI so the executable is at:

```text
tools/MR60BHA2_GUI/Seeed Studio mmWave Sensor GUI EN/new_gui_clean.exe
```

The adjacent `res/` directory must remain beside the executable. Do not use the
OTA tool's **Request Update** action unless a deliberate radar firmware upgrade
and recovery plan have been prepared.

For a deliberate MR60BHA2 radar-module update, place `Seeed OTA.exe` at
`tools/MR60BHA2_OTA/Seeed OTA.exe`, then run:

```powershell
.\start-radar-ota.cmd COM4
```

This flashes the XIAO UART passthrough sketch and launches the OTA tool. Select
the same COM port, `115200` baud, and `OTA Mode`. Connect and use **GET RADAR
INFO** before **REQUEST UPDATE**. Only flash firmware for MR60BHA2; MR60FDA2
firmware is incompatible and can brick the module. Restore the dashboard probe
after finishing with `restore-robot-probe.cmd COM4`.
