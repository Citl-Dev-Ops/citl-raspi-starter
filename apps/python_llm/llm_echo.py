import os, sys
try:
    from llama_cpp import Llama
except Exception:
    print("LLM extra not installed. Run: CITL_EXTRAS=llm bash scripts/quickstart_wsl.sh")
    sys.exit(0)

MODEL = os.path.join("assets","TinyLlama-1.1B-Chat.Q4_K_M.gguf")
if not os.path.exists(MODEL):
    print("Model not found at", MODEL)
    print('Download it via: CITL_ASSETS=tinyllama bash scripts/quickstart_wsl.sh')
    sys.exit(0)

ll = Llama(model_path=MODEL, n_ctx=1024, n_threads=4, seed=42)
resp = ll("Say a friendly one-line greeting for ESL learners.", max_tokens=48, temperature=0.7)
print(resp["choices"][0]["text"].strip())
