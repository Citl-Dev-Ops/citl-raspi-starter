#!/usr/bin/env bash
set -euxo pipefail
EXTRAS="${CITL_EXTRAS:-core}"  # comma-list: core,llm,tts,stt,trans,ocr,simplify

sudo apt-get update
sudo apt-get install -y \
  build-essential cmake ninja-build git pkg-config \
  gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
  gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
  qemu-user-static python3 python3-pip python3-venv curl

# Audio/ocr tools when needed
case ",$EXTRAS," in
  *,tts,*) sudo apt-get install -y libsndfile1 ;;  # for audio handling
esac
case ",$EXTRAS," in
  *,ocr,*) sudo apt-get install -y tesseract-ocr ;;  # OCR engine
esac

cd "$(dirname "$0")/.."
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip wheel
pip install -r python/requirements.txt

case ",$EXTRAS," in
  *,llm,*)      pip install -r python/requirements-llm.txt ;;
esac
case ",$EXTRAS," in
  *,tts,*)      pip install -r python/requirements-tts.txt ;;
esac
case ",$EXTRAS," in
  *,stt,*)      pip install -r python/requirements-stt.txt ;;
esac
case ",$EXTRAS," in
  *,trans,*)    pip install -r python/requirements-trans.txt ;;
esac
case ",$EXTRAS," in
  *,ocr,*)      pip install -r python/requirements-ocr.txt ;;
esac
case ",$EXTRAS," in
  *,simplify,*) pip install -r python/requirements-simplify.txt ;;
esac
