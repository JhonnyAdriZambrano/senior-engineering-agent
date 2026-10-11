---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?(?:total_a(?:[^\"\\\\]|\\\\.){0,400}total_b|total_b(?:[^\"\\\\]|\\\\.){0,400}total_a)"
flags: "m"
target: "trace"
---
