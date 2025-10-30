Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- venv ---
if (-not (Test-Path .\.venv\Scripts\Activate.ps1)) {
  py -3 -m venv .venv
}
. .\.venv\Scripts\Activate.ps1

# --- deps ---
python -m pip install --upgrade pip
python -m pip install -r .\python\requirements.txt
python -m pip install piper-tts vosk huggingface_hub

# --- assets present checks (bundled in repo) ---
$VoskZip = ".\assets\vosk-small-en-us.zip"
$VoskDir = ".\assets\vosk-model-small-en-us-0.15"
if (-not (Test-Path $VoskDir)) {
  if (-not (Test-Path $VoskZip)) { throw "Missing $VoskZip (expected in repo)" }
  Expand-Archive -LiteralPath $VoskZip -DestinationPath .\assets -Force
}
$Voice = ".\assets\piper\en_US-amy-medium.onnx"
$Cfg   = ".\assets\piper\en_US-amy-medium.onnx.json"
if (-not (Test-Path $Voice)) { throw "Missing voice $Voice" }
if (-not (Test-Path $Cfg))   { throw "Missing config $Cfg" }

# --- GGUF fetch (TinyLlama) ---
$py = @"
import os, shutil, fnmatch
from pathlib import Path
from huggingface_hub import snapshot_download

DEST = Path(r"assets\TinyLlama-1.1B-Chat.Q4_K_M.gguf")
DEST.parent.mkdir(parents=True, exist_ok=True)

def pick_file(root: Path, patterns, min_bytes=100_000_000):
    cands=[]
    for p in root.rglob("*.gguf"):
        for pat in patterns:
            if fnmatch.fnmatch(p.name.lower(), pat.lower()):
                if p.stat().st_size >= min_bytes:
                    cands.append(p); break
    return min(cands, key=lambda p: p.stat().st_size) if cands else None

attempts = [
    dict(repo_id="TinyLlama/TinyLlama-1.1B-Chat-v1.0-GGUF", use_token=True),
    dict(repo_id="TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF", use_token=False),
    dict(repo_id="bartowski/TinyLlama-1.1B-Chat-v1.0-GGUF", use_token=False),
]
patterns = ["*q4_k_m.gguf","*q4_0.gguf","*q3_k_m.gguf","*q3_k_l.gguf"]
token = os.getenv("HUGGINGFACE_HUB_TOKEN","citl")

if not (DEST.exists() and DEST.stat().st_size >= 100_000_000):
    last_err=None
    for att in attempts:
        try:
            cache = snapshot_download(repo_id=att["repo_id"],
                                      token=(token if att["use_token"] else None),
                                      allow_patterns=["*.gguf"])
            pick = pick_file(Path(cache), patterns)
            if not pick: raise FileNotFoundError("no matching GGUF")
            if pick.resolve() != DEST.resolve():
                shutil.copy2(pick, DEST)
            if DEST.stat().st_size < 100_000_000: raise ValueError("file too small")
            break
        except Exception as e:
            last_err=e
    if not DEST.exists():
        raise SystemExit(f"Failed to fetch GGUF: {last_err}")
print("GGUF OK:", DEST, DEST.stat().st_size, "bytes")
"@
Set-Content -LiteralPath .\scripts\_fetch_llm.py -Value $py -Encoding UTF8
python .\scripts\_fetch_llm.py
Remove-Item .\scripts\_fetch_llm.py -Force

# --- one-shot TTS + STT sanity ---
"Hello class, welcome to TinyLlama!" | & .\.venv\Scripts\piper.exe -m $Voice -c $Cfg -f hello_class.wav
if (-not (Test-Path .\hello_class.wav)) { throw "TTS failed to produce hello_class.wav" }

$stt = @"
import wave, json
from vosk import Model, KaldiRecognizer
wf = wave.open(r'hello_class.wav','rb')
rec = KaldiRecognizer(Model(r'__VOSK_DIR__'), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
print('STT:', json.loads(rec.FinalResult()).get('text','<none>'))
"@
$stt = $stt -replace '__VOSK_DIR__', ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($VoskDir))
Set-Content -LiteralPath .\scripts\_stt_run.py -Value $stt -Encoding UTF8
python .\scripts\_stt_run.py
Remove-Item .\scripts\_stt_run.py -Force

Write-Host "== windows_bootstrap.ps1 finished OK ==" -ForegroundColor Green
