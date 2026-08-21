#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CLI_VERSION="1.5.1"
ESP32_VERSION="3.3.11"
CLI_DIR="$PROJECT_ROOT/arduino-cli"
CLI="$CLI_DIR/arduino-cli"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script supports native Linux only." >&2
  exit 1
fi

for command_name in git curl tar sha256sum; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 1
  fi
done

if [[ ! -f "$PROJECT_ROOT/Seeed-mmWave-library/library.properties" ]]; then
  echo "Initializing the pinned Seeed mmWave library submodule..."
  git -C "$PROJECT_ROOT" submodule update --init --recursive
fi

case "$(uname -m)" in
  x86_64|amd64) CLI_PLATFORM="Linux_64bit" ;;
  aarch64|arm64) CLI_PLATFORM="Linux_ARM64" ;;
  armv7l|armv7) CLI_PLATFORM="Linux_ARMv7" ;;
  *)
    echo "Unsupported Linux architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

if [[ ! -x "$CLI" ]]; then
  archive="arduino-cli_${CLI_VERSION}_${CLI_PLATFORM}.tar.gz"
  release_url="https://github.com/arduino/arduino-cli/releases/download/v${CLI_VERSION}"
  temp_dir="$(mktemp -d)"
  trap 'rm -rf -- "$temp_dir"' EXIT

  echo "Downloading Arduino CLI $CLI_VERSION for $CLI_PLATFORM..."
  curl --fail --location --retry 3 --output "$temp_dir/$archive" "$release_url/$archive"
  curl --fail --location --retry 3 --output "$temp_dir/checksums.txt" "$release_url/${CLI_VERSION}-checksums.txt"
  grep "  $archive\$" "$temp_dir/checksums.txt" > "$temp_dir/selected-checksum.txt"
  (cd "$temp_dir" && sha256sum --check selected-checksum.txt)

  mkdir -p "$CLI_DIR"
  tar -xzf "$temp_dir/$archive" -C "$CLI_DIR"
  chmod +x "$CLI"
fi

chmod +x "$PROJECT_ROOT/arduino-env.sh" "$PROJECT_ROOT/start-demo.sh" \
  "$PROJECT_ROOT/start-dashboard.sh" "$PROJECT_ROOT/restore-robot-probe.sh"

echo "Installing ESP32 Arduino Core $ESP32_VERSION..."
"$PROJECT_ROOT/arduino-env.sh" core update-index
"$PROJECT_ROOT/arduino-env.sh" core install "esp32:esp32@$ESP32_VERSION"

echo "Installing pinned Arduino libraries..."
"$PROJECT_ROOT/arduino-env.sh" lib install "Adafruit NeoPixel@1.15.5"
"$PROJECT_ROOT/arduino-env.sh" lib install "hp_BH1750@1.0.2"

echo
echo "Linux setup complete. Connect the XIAO data USB port, then run:"
echo "  ./arduino-env.sh board list"
echo "  ./start-dashboard.sh /dev/ttyACM0"
