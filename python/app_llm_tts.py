import os, soundfile as sf, numpy as np
from llama_cpp import Llama
MODEL = os.path.join("assets", "TinyLlama-1.1B-Chat.Q4_K_M.gguf")
PROMPT = "Say: Raspberry Pi development is ready."
def run_llm(prompt:str)->str:
    ll = Llama(model_path=MODEL, n_ctx=1024, n_threads=4, seed=42)
    out = ll(f"<|system|>You are concise.<|user|>{prompt}<|assistant|>",
             max_tokens=64, temperature=0.7, top_p=0.9, stop=["<|end|>"])
    return out["choices"][0]["text"].strip()
def say_piper(text:str):
    if os.system("piper --version >NUL 2>&1" if os.name=='nt' else "piper --version >/dev/null 2>&1")==0:
        voice_dir = os.path.join("assets","piper")
        voice = os.path.join(voice_dir,"en_US-amy-medium.onnx")
        cfg   = os.path.join(voice_dir,"en_US-amy-medium.onnx.json")
        os.system(f'echo "{text}" | piper -m "{voice}" -c "{cfg}" -f out.wav')
        print("Saved TTS to out.wav")
    else:
        sr = 22050
        sf.write("out.wav", np.zeros(sr, dtype=np.float32), sr)
        print("Piper not installed; wrote silent out.wav")
if __name__ == "__main__":
    resp = run_llm(PROMPT)
    print("LLM:", resp)
    say_piper(resp)
