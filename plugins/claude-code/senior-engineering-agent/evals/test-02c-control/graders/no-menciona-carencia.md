---
type: regex
pattern: "(falta|faltan|no existe|no existen|ausen|no hay|sin)[^.\\n]{0,60}(PROJECT_CONTEXT|ARCHITECTURE)|(PROJECT_CONTEXT|ARCHITECTURE)[^.\\n]{0,40}(falta|no existe|ausente|vac[ií])"
flags: "i"
match: "not_contains"
---
