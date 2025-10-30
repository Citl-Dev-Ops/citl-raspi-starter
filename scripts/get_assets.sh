#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# --- TinyLlama GGUF (auto-pick a Q4_K_M file from TheBloke repo) ---
python - <<'PY'
import os, shutil
from huggingface_hub import HfApi, hf_hub_download
os.makedirs("assets", exist_ok=True)
api = HfApi()
repo_id = "TheBloke/TinyLlama-1.1B-Chat-GGUF"
files = api.list_repo_files(repo_id=repo_id)
cands = [f for f in files if f.lower().endswith(".gguf") and "q4_k_m" in f.lower()]
assert cands, f"No *Q4_K_M.gguf found in {repo_id}"
# deterministic pick
cands.sort()
target = cands[0]
out = hf_hub_download(repo_id=repo_id, filename=target, local_dir="assets")
dst = "assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf"
if os.path.abspath(out) != os.path.abspath(dst):
    shutil.copy2(out, dst)
print("TinyLlama model ->", dst)
PY

# --- Piper voice (Amy en_US medium) ---
python - <<'PY'
from huggingface_hub import hf_hub_download
hf_hub_download("rhasspy/piper-voices","en/en_US/amy/medium/en_US-amy-medium.onnx",       local_dir="assets/piper")
hf_hub_download("rhasspy/piper-voices","en/en_US/amy/medium/en_US-amy-medium.onnx.json", local_dir="assets/piper")
print("Piper voice -> assets/piper/en/en_US/amy/medium")
PY

# --- Vosk small EN-US STT model ---
mkdir -p assets
cd assets
if [ ! -d "vosk-model-small-en-us-0.15" ]; then
  curl -L --retry 3 -o vosk-model-small-en-us-0.15.zip "https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip"
  unzip -o vosk-model-small-en-us-0.15.zip
  rm -f vosk-model-small-en-us-0.15.zip
fi
echo "Assets ready."
