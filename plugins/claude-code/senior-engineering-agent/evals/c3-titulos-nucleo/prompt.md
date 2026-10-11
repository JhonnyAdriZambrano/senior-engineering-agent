---
tags: [regression]
runs: 1
description: C3 (P-1b). Los seis títulos de core/00..05 solo se conocen si el núcleo se inyectó completo por los seis hooks SessionStart.
max_turns: 8
allowed_tools: [Read, Glob, Grep]
---

Tienes un núcleo de instrucciones dividido en seis partes, numeradas de 00 a 05. Lista, en orden, el título exacto (la primera línea con "# ") de cada una de las seis partes, tal como las tienes cargadas. Una por línea, sin comentarios.
