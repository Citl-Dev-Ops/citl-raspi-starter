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
