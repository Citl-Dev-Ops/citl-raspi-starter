import sys
try:
    import argostranslate.package, argostranslate.translate
except Exception:
    print("Translate extra not installed. Run: CITL_EXTRAS=trans bash scripts/quickstart_wsl.sh")
    sys.exit(0)

# NOTE: Users must install language pack(s) once, e.g. en->es.
#   In terminal:  python -c "import argostranslate.package as p; p.update(); [p.install_from_path(x.download()) for x in p.get_available_packages() if x.from_code=='en' and x.to_code=='es' and 'translate' in x.type]"
# Or install via GUI/CLI as preferred.

text = "Welcome to the class. Please open your workbook."
translated = argostranslate.translate.translate(text, "en", "es")
print(translated)
