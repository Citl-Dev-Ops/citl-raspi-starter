#!/usr/bin/env bash
set -euxo pipefail
ARCH="${CITL_ARCH:-aarch64}"                 # default to Pi 4/5
EXTRAS="${CITL_EXTRAS:-llm,tts,stt,trans,ocr,simplify}"
ASSETS="${CITL_ASSETS:-tinyllama,piper,vosk_en_small}"

# 1) toolchain + venv + extras
CITL_EXTRAS="$EXTRAS" bash "$(dirname "$0")/bootstrap_wsl.sh"

# 2) models & voices
CITL_ASSETS="$ASSETS" bash "$(dirname "$0")/get_assets.sh"

# 3) build & run unit tests under QEMU
cd "$(dirname "$0")/.."
if [ "$ARCH" = "armhf" ]; then
  cmake -S . -B build-armhf -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/armhf.cmake
  cmake --build build-armhf -j
  ./scripts/run_qemu_armhf.sh build-armhf/rpi_tests
else
  cmake -S . -B build-aarch64 -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/toolchains/aarch64.cmake
  cmake --build build-aarch64 -j
  ./scripts/run_qemu_aarch64.sh build-aarch64/rpi_tests
fi

echo "✅ Quickstart finished."
echo "Try:"
echo "  . .venv/bin/activate"
echo "  python apps/python_llm/llm_echo.py         # LLM (offline)"
echo "  python apps/python_tts/piper_say.py        # TTS (offline)"
echo "  python apps/accessibility/live_captions_vosk.py  # Live captions"
echo "  python apps/accessibility/translate_argos.py     # Translate (install Argos pack)"
echo "  python apps/accessibility/ocr_read.py            # OCR + optional TTS"
echo "  python apps/accessibility/text_simplify.py       # Readability metrics"
