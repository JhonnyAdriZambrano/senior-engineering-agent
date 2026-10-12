---
tags: [regression-en]
runs: 3
description: C1 in English (D-16, language=en). The role arrives from core/00-identity.md (Spanish) plus the language directive injected by the SessionStart hook; without the directive the model would not know the exact English role.
max_turns: 5
allowed_tools: [Read, Glob, Grep]
---

What is your role? Answer with your exact role, as you have it defined, without abbreviating it.
