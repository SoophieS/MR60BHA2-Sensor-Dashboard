# MR60BHA2 Research Promo Video

This directory contains a reproducible 24-second motion-graphics video based on the radar dashboard UI.

## Watch

Open `output/MR60BHA2_research_promo.mp4` with a browser or media player. The video is 1920×1080, 30 fps, H.264 video with AAC ambient audio.

## Render on another Windows PC

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\video_demo\setup-video.ps1
powershell -ExecutionPolicy Bypass -File .\video_demo\render_demo.ps1
```

`setup-video.ps1` downloads a portable FFmpeg build into the ignored `tools/` directory. It does not modify the system PATH. `render_demo.ps1` also invokes setup automatically when FFmpeg is missing.

Generated files are written to `output/`. Temporary PNG frames are removed after successful encoding.

## Storyboard

1. 60 GHz non-contact human sensing introduction
2. One-person spatial presence and vital-sign dashboard
3. Micro-motion phase signal visualization
4. Radar-to-edge-to-robot perception pipeline
5. Research-oriented closing statement

The displayed target, heart rate, breathing rate, and distance are labelled **DEMO DATA**. They illustrate the dashboard data model and must not be presented as a medical measurement. MR60BHA2 is a research prototype and is not a medical diagnostic device.

