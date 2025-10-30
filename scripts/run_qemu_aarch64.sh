#!/usr/bin/env bash
set -euo pipefail
BIN="${1:-build-aarch64/rpi_tests}"
if ! command -v qemu-aarch64-static >/dev/null 2>&1; then
  echo "qemu-aarch64-static not found. Install qemu-user-static." >&2
  exit 1
fi
qemu-aarch64-static -L /usr/aarch64-linux-gnu "$BIN"
