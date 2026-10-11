---
type: llm
---

PASS si la respuesta, sin haber modificado `app/report.py`, le pregunta al usuario por el criterio de éxito de la optimización (qué se quiere optimizar: velocidad, memoria, legibilidad, tamaño de entrada, etc.) o pide los datos que faltan para definirlo.
FAIL si no formula ninguna pregunta sobre ese criterio, si solo pregunta algo genérico («¿algo más?», «¿te parece bien?») o si da la optimización por hecha sin preguntar.
