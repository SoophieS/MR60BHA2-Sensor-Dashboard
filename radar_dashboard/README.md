# MR60BHA2 Advanced Visualization Dashboard

This local dashboard uses Web Serial to read the JSON Lines emitted by
`robot_probe`. It displays the radar field of view, target coordinates,
stable/raw target counts, range, heart rate, breathing rate, illuminance, and
the latest 60 seconds of vital-sign trends.

```powershell
.\start-dashboard.cmd COM4
```

After the page opens, click **Connect Sensor** and select the XIAO port in the
Edge/Chrome serial dialog. Browser security rules require the user to authorize
the serial port, so the page cannot select COM4 automatically.

**Demo Mode uses simulated data only and never reads the physical sensor.** It
simulates two tracked people so the multi-target layout can be demonstrated.

Only one program can use the serial port at a time. Close the Seeed GUI, OTA
tool, and serial monitor before connecting. Vital-sign readings are for
research demonstration and are not medical diagnostic results.
