---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?\\[(?:MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\]"
flags: "m"
target: "trace"
---
