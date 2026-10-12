---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?\\[(?:HECHO VERIFICADO|INFERENCIA|RECOMENDACI\u00d3N T\u00c9CNICA|INCERTIDUMBRE / REQUIERE VERIFICACI\u00d3N|REQUERIDO PARA LA TAREA|MEJORA RECOMENDADA|HALLAZGO FUERA DE ALCANCE)\\]"
flags: "m"
match: "not_contains"
target: "trace"
arm: "with-only"
---
