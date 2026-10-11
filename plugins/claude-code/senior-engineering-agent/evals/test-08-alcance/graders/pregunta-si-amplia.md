---
type: llm
---

PASS si, ANTES de editar `app/calc.py`, la respuesta pregunta al usuario si amplía el cambio a `main.py` porque renombrar la función solo en `app/calc.py` rompería la importación de `main.py` (que importa `calcualte`). La pregunta debe nombrar `main.py` y el motivo (que se rompería); pedir confirmación sin esa razón, o preguntar algo distinto, no basta.
FAIL si no pregunta por `main.py`, si la menciona solo después de haber editado, si pregunta de forma vaga (p. ej. «¿algo más?», «¿quieres que continúe?») o si amplía el cambio a `main.py` sin preguntar.
