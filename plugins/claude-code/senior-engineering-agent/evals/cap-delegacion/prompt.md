---
description: "Capacidad (insumo para D-3): ¿delega en subagentes en paralelo? El Δ mide si el plugin delega mejor que el modelo solo."
tags: ["capability"]
runs: 3
max_turns: 20
allowed_tools: ["Read", "Glob", "Grep", "Skill", "Agent", "TodoWrite"]
---

Explora en paralelo `app/`, `tests/` y los archivos de conocimiento del proyecto, y resume la arquitectura.
