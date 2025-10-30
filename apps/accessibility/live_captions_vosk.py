import sys, json
try:
    import vosk
except Exception:
    print("STT extra not installed. Run: CITL_EXTRAS=stt bash scripts/quickstart_wsl.sh")
    sys.exit(0)

import subprocess, os

MODEL_DIR = "assets/vosk/en-small"
if not os.path.isdir(MODEL_DIR):
    print("Vosk model missing. Run: CITL_ASSETS=vosk_en_small bash scripts/quickstart_wsl.sh")
    sys.exit(0)

model = vosk.Model(MODEL_DIR)

# Record 16k mono from default mic via arecord (WSL mic passthrough requires Windows mic access)
proc = subprocess.Popen(["arecord","-f","S16_LE","-r","16000","-c","1","-t","raw"], stdout=subprocess.PIPE)
rec  = vosk.KaldiRecognizer(model, 16000)

print("Capturing (Ctrl+C to stop)...")
try:
    while True:
        data = proc.stdout.read(4000)
        if len(data) == 0: break
        if rec.AcceptWaveform(data):
            res = json.loads(rec.Result())
            print(res.get("text","").strip())
        else:
            part = json.loads(rec.PartialResult())
            # Optional: show partials
except KeyboardInterrupt:
    pass
finally:
    proc.terminate()
