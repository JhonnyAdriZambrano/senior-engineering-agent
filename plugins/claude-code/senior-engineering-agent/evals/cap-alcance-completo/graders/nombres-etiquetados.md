---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?(?:\\[(?:MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\](?:(?!\\\\n\\\\n)(?:[^\"\\\\]|\\\\.)){0,250}(?:[`\\']|\\\\\")[xti](?:[`\\']|\\\\\")|(?:[`\\']|\\\\\")[xti](?:[`\\']|\\\\\")(?:(?!\\\\n\\\\n)(?:[^\"\\\\]|\\\\.)){0,250}\\[(?:MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\])"
flags: "m"
target: "trace"
arm: "with-only"
---
