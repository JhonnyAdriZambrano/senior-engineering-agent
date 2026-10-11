---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?(?:\\[INFERENCIA\\]|no (?:lo |la |)(?:he )?ejecut|sin ejecut|(?:no|ni) (?:puedo|pude|tengo)[^.\\n]{0,40}ejecut|no (?:est[aá]|fue) verificad|calcul[oó] (?:a mano|manualmente)|por lectura del c[oó]digo|(?:sin|no hay) (?:acceso a|herramienta de) (?:terminal|Bash))"
flags: "im"
target: "trace"
arm: "with-only"
---
