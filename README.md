citl-raspi-starter

Offline, classroom-ready AI on a Raspberry Pi (CanaKit) using TinyLlama + Vosk + Piper.
This repo gives you a consistent, reproducible way to build small, real-world assistive apps (TTS, captions, translation, Q&A) that run fully on-device.

Why this kit (in plain English)

CanaKit? A boxed Raspberry Pi bundle with the board, power, case/cooling, microSD, and cables. Same parts every time → fewer “works on my machine” headaches.

OS we target: Raspberry Pi OS 64-bit (Bookworm) — the official arm64 distro with the best hardware support.

Why TinyLlama: A ~1.1B parameter instruction-tuned model that actually runs well on CPU when quantized (GGUF). It’s fast enough, small enough, and private (offline).

The offline stack:
Vosk (STT) → TinyLlama (LLM) → Piper (TTS) = low-latency, no cloud, classroom-safe.

What you can build (finished examples you can demo)

Live Captions on the Pi: microphone → Vosk captions in a terminal or on a kiosk screen.

“Ask the Lab” voice assistant: speak a question → TinyLlama answers → Piper speaks back.

Simple on-device translation: speak English → text → translate (Argos) → Piper speaks Spanish.

Reading aid / text simplifier: take a paragraph → simplify wording → read aloud via Piper.

How we measure success (program-friendly):

Time to first successful TTS and STT (<10 minutes on a fresh kit).

End-to-end latency (mic → voice reply) under ~4 seconds for short prompts.

Completely offline operation (disconnect Wi-Fi and still run).

Uptime in a 30–60 minute classroom block without overheating (with CanaKit cooling).

Hardware you’ll see in the CanaKit

Raspberry Pi 4 (4–8 GB) or 5 (4–8 GB)

Case + fan/heat sinks, 5V power supply

32–128 GB microSD

HDMI cable; optional USB mic/speaker

Tip: USB speakerphone “all-in-one” units make classroom audio painless.

Architecture (one glance)
Mic  -->  Vosk (STT)   -->  TinyLlama (LLM)  -->  Piper (TTS)  --> Speaker
           text out             text in           speech out

Verify your Pi’s OS (on the device)
cat /etc/os-release         # Expect Debian Bookworm
uname -m                    # Expect aarch64 (64-bit)


If you see armv7l, reflash with Raspberry Pi OS (64-bit).

Quick Start — Windows (PowerShell)

These steps assume you’ll use Python from Microsoft Store (domain-friendly) and PowerShell. No SSH. Copy/paste exactly.

# 1) Get the code (HTTPS only)
git clone https://github.com/Citl-Dev-Ops/citl-raspi-starter.git
cd citl-raspi-starter

# 2) Create and activate a virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 3) Install baseline Python deps
python -m pip install --upgrade pip
python -m pip install -r .\python\requirements.txt

# 4) Install runtime pieces into THIS venv (TTS, STT, model hub tools)
python -m pip install piper-tts vosk huggingface_hub llama-cpp-python

# 5) (First-run only) Expand the bundled Vosk model if the folder isn't present
if (-not (Test-Path .\assets\vosk-model-small-en-us-0.15) -and (Test-Path .\assets\vosk-small-en-us.zip)) {
  Expand-Archive -LiteralPath .\assets\vosk-small-en-us.zip -DestinationPath .\assets -Force
}

# 6) Generate a WAV with Piper (sanity check TTS)
$voice = ".\assets\piper\en_US-amy-medium.onnx"
$cfg   = ".\assets\piper\en_US-amy-medium.onnx.json"
"Hello class, welcome to TinyLlama!" | & .\.venv\Scripts\piper.exe -m $voice -c $cfg -f hello_class.wav
Get-Item .\hello_class.wav | Format-List Name,Length,LastWriteTime

# 7) Transcribe that WAV with Vosk (sanity check STT)
$VoskDir = ".\assets\vosk-model-small-en-us-0.15"
@'
import wave, json
from vosk import Model, KaldiRecognizer
wf = wave.open("hello_class.wav","rb")
rec = KaldiRecognizer(Model(r"""__VOSK_DIR__"""), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
print("STT:", json.loads(rec.FinalResult()).get("text","<none>"))
'@ -replace '__VOSK_DIR__', ($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($VoskDir)) |
Set-Content _stt_run.py -Encoding UTF8
python .\_stt_run.py
Remove-Item .\_stt_run.py -Force

# 8) (Optional first run) Fetch a TinyLlama GGUF automatically when apps ask for it
# The code will try public mirrors; if you set a token, it will use it.
$env:HUGGINGFACE_HUB_TOKEN = "citl"   # literal 'citl' is accepted by our scripts


Where to put your own code (Windows):

Python apps: apps/python_* (see examples inside the repo)

Your first demo script example is included: apps/python_hello/hello_stakeholders.py

Run them with:

python .\apps\python_hello\hello_stakeholders.py

Quick Start — Raspberry Pi (bookworm, 64-bit)
# 0) System packages
sudo apt-get update
sudo apt-get install -y python3-venv git cmake alsa-utils

# 1) Code + venv
git clone https://github.com/Citl-Dev-Ops/citl-raspi-starter.git
cd citl-raspi-starter
python3 -m venv .venv
source .venv/bin/activate

# 2) Python deps (baseline + runtime)
python -m pip install --upgrade pip
python -m pip install -r python/requirements.txt
python -m pip install piper-tts vosk huggingface_hub llama-cpp-python

# 3) (First run) audio devices
arecord -l
aplay -l

# 4) Smoke tests
python apps/python_tts/piper_say.py          # generates a WAV via Piper
python apps/accessibility/live_captions_vosk.py  # live captions in terminal
python apps/python_llm/llm_echo.py           # TinyLlama test (fetches GGUF if needed)


The repo’s helper (scripts/fix_all.sh) can also fetch a GGUF automatically on Linux/WSL. On Windows, the PowerShell steps above are clearer for domain machines.

Developing your first app
A. Python: “voice in → answer → voice out”

Use apps/python_llm/llm_echo.py and apps/python_tts/piper_say.py as references. A minimal skeleton:

# apps/python_llm/my_voice_assistant.py
import json, wave, sys
from vosk import Model, KaldiRecognizer
from llama_cpp import Llama
import subprocess, os

VOSK_DIR = "assets/vosk-model-small-en-us-0.15"
GGUF    = "assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf"
VOICE   = "assets/piper/en_US-amy-medium.onnx"
CFG     = "assets/piper/en_US-amy-medium.onnx.json"

# 1) capture/ingest speech (for a quick demo, reuse hello_class.wav)
wf  = wave.open("hello_class.wav","rb")
rec = KaldiRecognizer(Model(VOSK_DIR), wf.getframerate()); rec.SetWords(True)
while True:
    d = wf.readframes(4000)
    if not d: break
    rec.AcceptWaveform(d)
user_text = json.loads(rec.FinalResult()).get("text","").strip() or "say a greeting to our class"
print("USER:", user_text)

# 2) run TinyLlama
llm = Llama(model_path=GGUF, n_ctx=512, n_threads=4, verbose=False)
resp = llm(f"Brief, friendly, K-12 safe answer: {user_text}", max_tokens=64, temperature=0.6)
bot_text = resp["choices"][0]["text"].strip()
print("BOT :", bot_text)

# 3) speak with Piper
p = subprocess.Popen(
    ["piper", "-m", VOICE, "-c", CFG, "-f", "reply.wav"],
    stdin=subprocess.PIPE, text=True
)
p.communicate(bot_text)
print("WAV : reply.wav")


Run it:

# Windows (PowerShell)
.\.venv\Scripts\Activate.ps1
python .\apps\python_llm\my_voice_assistant.py

# Pi / Linux
source .venv/bin/activate
python apps/python_llm/my_voice_assistant.py

B. C (optional): build & run
# Pi / WSL bash only (CMake)
mkdir -p build
cmake -S . -B build
cmake --build build -j
./build/rpi_demo


On native Windows cmd/PowerShell (without MSYS/CMake), stick to Python apps.

Models & assets (what lives where)

Vosk model (offline STT): assets/vosk-model-small-en-us-0.15/
(A zip assets/vosk-small-en-us.zip is included for machines that need to expand it.)

Piper voice + config (offline TTS):
assets/piper/en_US-amy-medium.onnx and .json

TinyLlama GGUF (offline LLM): fetched on first LLM run to
assets/TinyLlama-1.1B-Chat.Q4_K_M.gguf
(Our fetcher tries public mirrors; if you export HUGGINGFACE_HUB_TOKEN=citl, it will attempt the official path first.)

Troubleshooting (fast)

PowerShell prints Python code errors: You pasted Python into PS. Save to a .py file (see STT block above) then python file.py.

piper.exe not found: Ensure you installed piper-tts inside your venv and ran .\.venv\Scripts\Activate.ps1.

Windows Defender pop-up: First-run executable (e.g., piper.exe) triggered Smartscreen. Choose Allow for the signed package you installed via pip.

No audio devices: On Pi, check arecord -l and aplay -l. On Windows, use USB mic/speaker or set default device in Sound Settings.

STT path error (“Folder … not found”): Use the absolute path to assets/vosk-model-small-en-us-0.15 (the STT helper snippet does this automatically).

CMake not found in PowerShell: Build C samples on Pi/WSL; Windows Python apps need no CMake.

What counts as “done” for a cohort demo

You can run:

python apps/python_tts/piper_say.py → produces a WAV.

The STT snippet → prints “STT: …” for your WAV.

python apps/python_llm/llm_echo.py → returns a TinyLlama response.

Your custom script (e.g., my_voice_assistant.py) produces a spoken reply.

It keeps working offline for an entire class block without thermal throttling.

Hand-off to the classroom Pi

Push your app code to GitHub (this repo or fork).

On the Pi, clone/pull, activate the venv, and install deps as in Quick Start — Raspberry Pi.

Plug in mic/speaker, verify audio, run your app.

For kiosk use, add your app’s launch command to a systemd user service or LXDE autostart.

Contributing

Keep additions fully offline and CPU-friendly.

Place new Python demos under apps/python_*.

Use the existing assets folder structure.

One-liner smoke tests (Windows & Pi)

Windows (PowerShell):

# From repo root
.\.venv\Scripts\Activate.ps1
"Hello from Piper!" | & .\.venv\Scripts\piper.exe -m .\assets\piper\en_US-amy-medium.onnx -c .\assets\piper\en_US-amy-medium.onnx.json -f hello_class.wav


Raspberry Pi (bash):

# From repo root
source .venv/bin/activate
python apps/accessibility/live_captions_vosk.py


License & Acknowledgments
This starter integrates the great work of the Vosk (STT), Piper (TTS), and TinyLlama communities, packaged for predictable classroom deployments on Raspberry Pi.
