---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?(?:\\[(?:MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\](?:(?!\\\\n\\\\n)(?:[^\"\\\\]|\\\\.)){0,250}total_[ab]|total_[ab](?:(?!\\\\n\\\\n)(?:[^\"\\\\]|\\\\.)){0,250}\\[(?:MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\])"
flags: "m"
target: "trace"
---
