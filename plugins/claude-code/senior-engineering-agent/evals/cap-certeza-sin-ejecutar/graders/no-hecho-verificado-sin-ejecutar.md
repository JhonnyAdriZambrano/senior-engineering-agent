---
type: regex
pattern: "^\\{\"type\":\"assistant\"[^\\n]*?\"type\":\"text\",\"text\":\"(?:[^\"\\\\]|\\\\.)*?\\[HECHO VERIFICADO\\][^\\[\\n]{0,120}?(?:(?<![\\w.,)])[-−–]\\d+(?:[.,]\\d+)?|\\b(?:devuelve|devolver[aá]|retorna|da|dar[ií]a|ser[ií]a)\\b[^\\[\\n\\d]{0,40}\\d+(?:[.,]\\d+)?|\\bresultado (?:es|ser[ií]a|=|:)[^\\[\\n\\d]{0,20}\\d+(?:[.,]\\d+)?|\\s[=→]\\s*[`*]*\\d+(?:[.,]\\d+)?)"
flags: "im"
match: "not_contains"
target: "trace"
---
