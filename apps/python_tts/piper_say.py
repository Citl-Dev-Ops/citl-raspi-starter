import os, subprocess, sys
voice_dir = os.path.join("assets","piper")
voice = os.path.join(voice_dir,"en_US-amy-medium.onnx")
cfg   = os.path.join(voice_dir,"en_US-amy-medium.onnx.json")
if not (os.path.exists(voice) and os.path.exists(cfg)):
    print("Piper voice not found. Get it with: CITL_ASSETS=piper bash scripts/quickstart_wsl.sh")
    sys.exit(0)

text = "Welcome to CITL. Let's build accessible tools together."
p = subprocess.Popen(["piper", "-m", voice, "-c", cfg, "-f", "out.wav"], stdin=subprocess.PIPE)
p.communicate(input=text.encode("utf-8"))
print("Saved TTS to out.wav")
