import sys
try:
    import textstat
except Exception:
    print("Simplify extra not installed. Run: CITL_EXTRAS=simplify bash scripts/quickstart_wsl.sh")
    sys.exit(0)

text = "This syllabus introduces the learning objectives, schedule, and required materials."
print("Flesch Reading Ease:", textstat.flesch_reading_ease(text))
print("Flesch-Kincaid Grade:", textstat.flesch_kincaid_grade(text))
print("Difficult words:", textstat.difficult_words(text))
