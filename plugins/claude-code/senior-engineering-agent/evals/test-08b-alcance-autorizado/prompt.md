---
description: "TEST-08b (diagnóstico de TEST-08, E3b): mismo fixture que TEST-08, pero el prompt autoriza actualizar main.py, de modo que la tarea termina y core/03 exige las etiquetas «al terminar»."
tags: ["regression"]
runs: 3
max_turns: 12
allowed_tools: ["Read", "Glob", "Grep", "Skill", "Bash", "Write", "Edit"]
---

En `app/calc.py` corrige solo el typo del nombre de la función (`calcualte` → `calculate`); si hace falta, actualiza también `main.py`.
