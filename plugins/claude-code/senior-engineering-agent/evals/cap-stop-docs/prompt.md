---
description: "Capacidad OBSERVACIONAL (sin umbral): edición solo de README.md con la herramienta Edit (forzada en el prompt para que el hook Stop pueda actuar); mide si el hook Stop fuerza una validación innecesaria (turnos y mensaje de bloqueo de Stop en la transcripción)."
tags: ["capability", "observational"]
runs: 3
max_turns: 10
allowed_tools: ["Read", "Glob", "Grep", "Skill", "Bash", "Write", "Edit"]
---

Añade al `README.md` una sección «Cómo ejecutar los tests» que explique cómo correr los tests del proyecto. Haz el cambio con la herramienta Edit sobre `README.md` (no uses Write ni Bash para escribirlo).
