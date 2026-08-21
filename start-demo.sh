#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "Python 3 was not found. Activate the biosensor Conda environment." >&2
  exit 1
fi

url="http://127.0.0.1:8765"
echo "Dashboard: $url"
echo "Press Ctrl+C to stop the local server."

if command -v xdg-open >/dev/null 2>&1; then
  (sleep 1 && xdg-open "$url" >/dev/null 2>&1) &
fi

exec "$PYTHON_BIN" -m http.server 8765 --bind 127.0.0.1 \
  --directory "$PROJECT_ROOT/radar_dashboard"
