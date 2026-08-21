#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLI="$PROJECT_ROOT/arduino-cli/arduino-cli"
CONFIG="$PROJECT_ROOT/arduino-cli-linux.yaml"

if [[ ! -x "$CLI" ]]; then
  echo "Arduino CLI is not installed. Run: bash setup-linux.sh" >&2
  exit 1
fi

cd "$PROJECT_ROOT"
exec "$CLI" "$@" --config-file "$CONFIG"
