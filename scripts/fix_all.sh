#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== Using HUGGINGFACE_HUB_TOKEN (defaulting to literal 'citl') =="
: "${HUGGINGFACE_HUB_TOKEN:=citl}"
echo "Token in use: ${HUGGINGFACE_HUB_TOKEN}"

# 0) ensure assets dir
mkdir -p assets

# 1) fetch GGUF (try TinyLlama with the provided token 'citl'; fallback to public Qwen if 401/forbidden)
python - <<'PY'
import os, shutil
from huggingface_hub import hf_hub_download

def try_fetch(repo_id, filename, dst, token=None):
    try:
        path = hf_hub_download(
            repo_id=repo_id,
            filename=filename,
            token=token,
            local_dir="assets",
            local_dir_use_symlinks=False,
            force_download=True,
        )
        if os.path.abspath(path) != os.path.abspath(dst):
            shutil.copy2(path, dst)
        sz = os.path.getsize(dst)
        print(f"DOWNLOADED: {dst}  bytes={sz}")
        return sz
    except Exception as e:
        print("DOWNLOAD FAILED:", type(e).__name__, e)
        return 0

dst = "assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf"
# nuke stub if present
if os.path.exists(dst) and os.path.getsize(dst) < 100_000_000:
    os.remove(dst)

if not (os.path.exists(dst) and os.path.getsize(dst) > 100_000_000):
    # attempt with your token (literal 'citl' if that's what was exported)
    token = os.getenv("HUGGINGFACE_HUB_TOKEN", "citl")
    sz = try_fetch(
        "TinyLlama/TinyLlama-1.1B-Chat-v1.0-GGUF",
        "tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf",
        dst,
        token=token
    )
    if sz <= 100_000_000:
        print("FALLBACK: Fetching a public GGUF (no token required).")
        sz = try_fetch(
            "Qwen/Qwen2.5-0.5B-Instruct-GGUF",
            "Qwen2.5-0.5B-Instruct-Q4_K_M.gguf",
            dst,
            token=None
        )
        if sz <= 100_000_000:
            raise SystemExit("ERROR: Could not obtain a valid GGUF (>100MB).")

print("GGUF ready at", dst, "bytes=", os.path.getsize(dst))
PY

# 2) llama.cpp-python smoketest
python - <<'PY'
from llama_cpp import Llama
llm = Llama(model_path="assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf", n_ctx=512, n_threads=4, verbose=False)
out = llm("Hello class! Brief greeting:", max_tokens=24, temperature=0.6)
print("LLM OUTPUT:", out["choices"][0]["text"].strip())
PY

# 3) Piper TTS — you already have these files; MUST pass -c config
echo "Hello class, welcome to TinyLlama!" \
| piper -m assets/piper/en_US-amy-medium.onnx \
        -c assets/piper/en_US-amy-medium.onnx.json \
        -f hello_class.wav
ls -lh hello_class.wav

# 4) Vosk STT on the generated WAV
python - <<'PY'
import wave, json
from vosk import Model, KaldiRecognizer
wf = wave.open("hello_class.wav","rb")
model = Model("assets/vosk-model-small-en-us-0.15")
rec = KaldiRecognizer(model, wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
print("STT:", json.loads(rec.FinalResult()).get("text","<none>"))
PY
