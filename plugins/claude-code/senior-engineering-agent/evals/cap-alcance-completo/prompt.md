---
description: "Capacidad: tras terminar la tarea autorizada, enumera todos los hallazgos visibles (duplicado total_a/total_b y nombres x, t, i), cada uno con etiqueta, sin corregirlos."
tags: ["capability"]
runs: 3
max_turns: 12
allowed_tools: ["Read", "Glob", "Grep", "Skill", "Bash", "Write", "Edit"]
---

En `app/calc.py` corrige solo el typo del nombre de la función (`calcualte` → `calculate`); si hace falta, actualiza también `main.py`.
