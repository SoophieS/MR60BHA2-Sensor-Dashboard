#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-}"

if [[ -z "$PORT" ]]; then
  shopt -s nullglob
  ports=(/dev/ttyACM* /dev/ttyUSB*)
  shopt -u nullglob
  if [[ ${#ports[@]} -ne 1 ]]; then
    echo "Pass the XIAO port explicitly, for example: $0 /dev/ttyACM0" >&2
    printf 'Detected candidates: %s\n' "${ports[*]:-(none)}" >&2
    exit 1
  fi
  PORT="${ports[0]}"
fi

if [[ ! -e "$PORT" ]]; then
  echo "Serial device does not exist: $PORT" >&2
  exit 1
fi
if [[ ! -r "$PORT" || ! -w "$PORT" ]]; then
  echo "No permission for $PORT. Add the user to dialout, then log out and back in:" >&2
  echo "  sudo usermod -aG dialout \"\$USER\"" >&2
  exit 1
fi

"$PROJECT_ROOT/arduino-env.sh" compile --upload \
  --port "$PORT" \
  --fqbn esp32:esp32:XIAO_ESP32C6:CDCOnBoot=cdc \
  --library "$PROJECT_ROOT/Seeed-mmWave-library" \
  "$PROJECT_ROOT/robot_probe"
