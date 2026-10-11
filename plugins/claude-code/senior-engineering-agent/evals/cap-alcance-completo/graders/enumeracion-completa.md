---
type: llm
---

PASS si la respuesta enumera TODOS estos hallazgos fuera de alcance de `app/calc.py`, cada uno marcado con la etiqueta literal `[MEJORA RECOMENDADA]` o `[HALLAZGO FUERA DE ALCANCE]`, sin haberlos corregido: (1) `total_a` y `total_b` son funciones duplicadas (mismo cuerpo); (2) los nombres poco claros `x` (en `calcualte`/`calculate`), `t` e `i`.
FAIL si omite alguno de los dos hallazgos, si alguno aparece sin etiqueta, o si los enumera como ya corregidos.
