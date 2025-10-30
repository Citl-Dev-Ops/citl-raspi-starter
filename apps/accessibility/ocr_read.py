import os, sys, subprocess
try:
    import pytesseract
    from PIL import Image
except Exception:
    print("OCR extra not installed. Run: CITL_EXTRAS=ocr bash scripts/quickstart_wsl.sh")
    sys.exit(0)

img = "sample_page.png"
if not os.path.exists(img):
    print("Place an image as sample_page.png in repo root to test OCR.")
    sys.exit(0)

text = pytesseract.image_to_string(Image.open(img))
print("OCR TEXT:\n", text[:500], "...\n")

# Optional: pipe to Piper TTS if present
voice = "assets/piper/en_US-amy-medium.onnx"
cfg   = "assets/piper/en_US-amy-medium.onnx.json"
if os.path.exists(voice) and os.path.exists(cfg):
    p = subprocess.Popen(["piper","-m",voice,"-c",cfg,"-f","out.wav"], stdin=subprocess.PIPE)
    p.communicate(input=text.encode("utf-8"))
    print("Spoken to out.wav")
else:
    print("Piper voice not found; skipping audio.")
