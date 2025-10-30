#!/usr/bin/env bash
set -euo pipefail
BIN="${1:-build-armhf/rpi_tests}"
if ! command -v qemu-arm-static >/dev/null 2>&1; then
  echo "qemu-arm-static not found. Install qemu-user-static." >&2
  exit 1
fi
qemu-arm-static -L /usr/arm-linux-gnueabihf "$BIN"
