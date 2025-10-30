# citl-raspi-starter

One-liner smoke test (downloads a usable GGUF, runs Piper TTS & Vosk STT):

```bash
export HUGGINGFACE_HUB_TOKEN=citl   # optional; script will fall back to public mirrors
bash scripts/fix_all.sh

