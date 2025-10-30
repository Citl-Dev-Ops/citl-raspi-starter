cat > scripts/one_time_setup.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y curl unzip libsndfile1 tesseract-ocr
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip wheel
pip install -r python/requirements.txt
pip install -r python/requirements-llm.txt
pip install -r python/requirements-tts.txt
pip install -r python/requirements-stt.txt
pip install -r python/requirements-trans.txt
pip install -U huggingface_hub
bash scripts/get_assets.sh
echo "Setup complete. Activate with:  . .venv/bin/activate"
EOF