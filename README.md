Windows dev → CanaKit deployment guide (TinyLlama + Piper TTS + Vosk STT)
A. One-time: get the repo & Visual Studio set up
A1) Clone the repo

Use one of these (pick just one).

Option 1 — GitHub Desktop

Open GitHub Desktop → File → Clone repository…

URL: https://github.com/Citl-Dev-Ops/citl-raspi-starter.git

Choose a local folder → Clone.

Option 2 — Visual Studio 2022

Launch Visual Studio 2022.

Start Window → Clone a repository.

Repository location: https://github.com/Citl-Dev-Ops/citl-raspi-starter.git

Clone.

Option 3 — PowerShell

git clone https://github.com/Citl-Dev-Ops/citl-raspi-starter.git
cd citl-raspi-starter

A2) Visual Studio workloads (for C/C++ apps)

Install once (skip if already done):

Start Menu → Visual Studio Installer → Modify your VS 2022 install.

Check:

Desktop development with C++

C++ CMake tools for Windows

Modify → Let it finish.

B. Windows: bootstrap the Python stack (venv, TTS, STT, GGUF)

Do this from the repo root in PowerShell (not CMD). These create a .venv, install deps, verify TTS/STT, and fetch a TinyLlama GGUF.

B1) Create the scripts (one paste)
# From repo root
New-Item -ItemType Directory -Force -Path .\scripts | Out-Null

@'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- venv ---
if (-not (Test-Path .\.venv\Scripts\Activate.ps1)) { py -3 -m venv .venv }
. .\.venv\Scripts\Activate.ps1

# --- deps ---
python -m pip install --upgrade pip
python -m pip install -r .\python\requirements.txt
python -m pip install piper-tts vosk huggingface_hub llama-cpp-python

# --- assets present checks (bundled) ---
$VoskZip = ".\assets\vosk-small-en-us.zip"
$VoskDir = ".\assets\vosk-model-small-en-us-0.15"
if (-not (Test-Path $VoskDir)) {
  if (-not (Test-Path $VoskZip)) { throw "Missing $VoskZip" }
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
'@ | Set-Content .\scripts\windows_bootstrap.ps1 -Encoding UTF8

@'
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. .\.venv\Scripts\Activate.ps1

$Voice = ".\assets\piper\en_US-amy-medium.onnx"
$Cfg   = ".\assets\piper\en_US-amy-medium.onnx.json"
$VoskDir = ".\assets\vosk-model-small-en-us-0.15"

"Test line for smoke check." | & .\.venv\Scripts\piper.exe -m $Voice -c $Cfg -f hello_class.wav
(Get-Item .\hello_class.wav | Select-Object Name,Length,LastWriteTime) | Format-List

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

Write-Host "== windows_smoke.ps1 finished OK ==" -ForegroundColor Green
'@ | Set-Content .\scripts\windows_smoke.ps1 -Encoding UTF8

B2) Run the bootstrap
Set-ExecutionPolicy -Scope Process Bypass -Force
.\scripts\windows_bootstrap.ps1

B3) Re-run smoke any time
.\scripts\windows_smoke.ps1

C. Where to start coding (pick your stack)
C1) Python — TTS (Piper)
. .\.venv\Scripts\Activate.ps1
python apps\python_tts\piper_say.py


Edit apps/python_tts/piper_say.py to change the text/voice (the voice files already live in assets/piper/).

C2) Python — Live captions (Vosk)
. .\.venv\Scripts\Activate.ps1
python apps\accessibility\live_captions_vosk.py


Starts microphone STT. Tweak model path or chunk sizes inside the script if you like.

C3) Python — TinyLlama local LLM
. .\.venv\Scripts\Activate.ps1
python - << 'PY'
from llama_cpp import Llama
llm = Llama(model_path="assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf", n_ctx=512, n_threads=4, verbose=False)
out = llm("Hello class! Brief greeting:", max_tokens=32, temperature=0.6)
print(out["choices"][0]["text"].strip())
PY


Use as a building block for chat/assist features.

C4) Python — Translate (offline, Argos)
. .\.venv\Scripts\Activate.ps1
python apps\accessibility\translate_argos.py


If a model download is prompted the first run, follow the command-line prompt in that script (it’s prepared for Argos Translate).

C5) C/C++ — build & run in Visual Studio

Visual Studio → File → Open → Folder… and select the repo root.

Wait for “CMake generation finished”.

Build toolbar:

Configure Preset: windows-default (or whatever VS offers by default)

Build → Build All

Run target rpi_demo from CMake Targets view.

If you prefer command-line CMake later: install CMake, then:

cmake -S . -B build
cmake --build build -j
.\build\rpi_demo.exe

D. Sample “complete stacks” your team can demo today
D1) Text → Speech → Transcript (TTS + STT)
. .\.venv\Scripts\Activate.ps1
"Stakeholder demo: this is a round trip." | & .\.venv\Scripts\piper.exe -m .\assets\piper\en_US-amy-medium.onnx -c .\assets\piper\en_US-amy-medium.onnx.json -f out.wav

python - << 'PY'
import wave, json
from vosk import Model, KaldiRecognizer
wf = wave.open("out.wav","rb")
rec = KaldiRecognizer(Model(r"assets/vosk-model-small-en-us-0.15"), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
print("TRANSCRIPT:", json.loads(rec.FinalResult()).get("text","<none>"))
PY

D2) Live captions + TinyLlama “prompt assist”
. .\.venv\Scripts\Activate.ps1
python - << 'PY'
import wave, sys, json
from vosk import Model, KaldiRecognizer
from llama_cpp import Llama

llm = Llama(model_path="assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf", n_ctx=512, n_threads=4, verbose=False)

# simple: transcribe an existing WAV then summarize with LLM
wf = wave.open("hello_class.wav","rb")
rec = KaldiRecognizer(Model(r"assets/vosk-model-small-en-us-0.15"), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
text = json.loads(rec.FinalResult()).get("text","<none>")
print("ASR:", text)
summary = llm(f"Summarize in one sentence: {text}", max_tokens=48, temperature=0.2)["choices"][0]["text"].strip()
print("LLM summary:", summary)
PY

D3) “Hello, stakeholders!” minimal demo app (Python)
. .\.venv\Scripts\Activate.ps1
mkdir -Force apps\python_hello | Out-Null
@'
from datetime import datetime
print("Hello, stakeholders!")
print("Timestamp:", datetime.now().isoformat(timespec="seconds"))
'@ | Set-Content apps\python_hello\hello_stakeholders.py
python apps\python_hello\hello_stakeholders.py

E. Move your project to the CanaKit Raspberry Pi

Two reliable paths: (1) Git pull on the Pi (recommended), or (2) copy over via scp.

E1) On the Pi — first-time setup

SSH into the Pi (replace hostname/ip):

ssh pi@raspberrypi.local
# or: ssh pi@<pi-ip-address>


Then:

sudo apt-get update
sudo apt-get install -y git python3-venv python3-pip
git clone https://github.com/Citl-Dev-Ops/citl-raspi-starter.git
cd citl-raspi-starter
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -r python/requirements.txt
python -m pip install piper-tts vosk huggingface_hub llama-cpp-python
# expand the bundled Vosk model if not already expanded
if [ -f assets/vosk-small-en-us.zip ] && [ ! -d assets/vosk-model-small-en-us-0.15 ]; then
  python - <<'PY'
import zipfile, os
z="assets/vosk-small-en-us.zip"
with zipfile.ZipFile(z) as zf:
    zf.extractall("assets")
print("Vosk extracted")
PY
fi
# Fetch TinyLlama GGUF (same logic as Windows; token optional)
export HUGGINGFACE_HUB_TOKEN=citl
python - <<'PY'
import os, shutil, fnmatch
from pathlib import Path
from huggingface_hub import snapshot_download

DEST = Path("assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf")
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
PY

Quick Pi smoke
. .venv/bin/activate
echo "Hello Pi from Piper." | piper -m assets/piper/en_US-amy-medium.onnx -c assets/piper/en_US-amy-medium.onnx.json -f hello_pi.wav
python - <<'PY'
import wave, json
from vosk import Model, KaldiRecognizer
wf = wave.open("hello_pi.wav","rb")
rec = KaldiRecognizer(Model("assets/vosk-model-small-en-us-0.15"), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
print("Pi TRANSCRIPT:", json.loads(rec.FinalResult()).get("text","<none>"))
PY

E2) Keep Pi in sync (choose one)

Option A — Pull from GitHub on the Pi

cd ~/citl-raspi-starter
git pull
. .venv/bin/activate
python -m pip install -r python/requirements.txt


Option B — Copy from Windows to Pi (scp)

# From Windows PowerShell, repo root:
scp -r * pi@raspberrypi.local:~/citl-raspi-starter/

F. What staff should open/edit

Python apps → apps/python_tts/, apps/accessibility/, apps/python_hello/

LLM usage → import llama_cpp.Llama and point model_path to assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf

C/C++ apps → source in src/ and apps/c_hello/; build with Visual Studio CMake integration.

G. Daily workflow (Windows)
# 1) Pull latest
git pull

# 2) Activate venv
. .\.venv\Scripts\Activate.ps1

# 3) (Only if requirements changed)
python -m pip install -r .\python\requirements.txt

# 4) Run your app(s)
python apps\python_tts\piper_say.py
python apps\accessibility\live_captions_vosk.py
python apps\python_hello\hello_stakeholders.py

# 5) Commit and push
git add -A
git commit -m "Work in progress: <your message>"
git push

H. Common fixes

Execution policy error → run:

Set-ExecutionPolicy -Scope Process Bypass -Force


Piper not found → you’re not in the venv. Run:

. .\.venv\Scripts\Activate.ps1


Vosk “model not found” → ensure the folder exists:

Test-Path .\assets\vosk-model-small-en-us-0.15


TinyLlama GGUF missing → rerun:

$env:HUGGINGFACE_HUB_TOKEN="citl"   # or leave unset
.\scripts\windows_bootstrap.ps1
