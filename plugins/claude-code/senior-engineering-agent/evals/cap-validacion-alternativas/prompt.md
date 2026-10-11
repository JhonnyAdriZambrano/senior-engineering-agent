---
description: "Capacidad: con python3 roto y py funcional, tras una edición debe probar alternativas y ejecutar pytest antes de declarar «no pude validar»."
tags: ["capability"]
runs: 3
max_turns: 15
allowed_tools: ["Read", "Glob", "Grep", "Skill", "Bash", "Write", "Edit"]
---

En `app/pricing.py`, haz que `price_with_tax` lance `ValueError` si `rate` es negativo y valida el cambio ejecutando los tests de `tests/`. Los comandos de este proyecto se ejecutan con el PATH del proyecto por delante: `PATH="$PWD/bin:$PATH" <comando>`.
