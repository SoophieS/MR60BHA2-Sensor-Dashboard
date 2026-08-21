#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PORT="${1:-}"

"$PROJECT_ROOT/restore-robot-probe.sh" "$PORT"
exec "$PROJECT_ROOT/start-demo.sh"
