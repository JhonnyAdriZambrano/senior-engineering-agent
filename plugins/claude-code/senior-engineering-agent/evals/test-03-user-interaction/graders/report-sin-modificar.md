---
type: regex
pattern: "total = total \\+ item\\[\"price\"\\] \\* item\\[\"qty\"\\][\\s\\S]*grand = grand \\+ l\\[\"total\"\\]"
target: {"source": "file", "path": "app/report.py"}
---
