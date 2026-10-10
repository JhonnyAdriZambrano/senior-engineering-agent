# TEST-XX — [nombre]

Flujo normal: `bash tests/sandbox/prepare_test.sh TEST-XX` crea el registro y
`bash tests/sandbox/finish_test.sh` lo completa (GUIA_BENCHMARK.md §4). Solo si
no puedes usarlos:
Manual: copia este archivo a `tests/results/AAAA-MM-DD_TEST-XX_rK.md` (K = repetición).
Procedimiento: `tests/GUIA_BENCHMARK.md`. Criterios: `tests/BENCHMARK.md`.

- **Fecha:**
- **Repetición:** K de N
- **Versión del agente** (`manifest.yaml > agent.version`) **/ commit:**
- **Runtime:** Claude Code
- **CLI** (`claude --version`) **/ Modelo / Effort:**
- **Sandbox y estado de partida** (A / B / C):
- **Hooks activos** (sí / no):
- **Sandbox recreado antes de esta prueba** (debe ser sí):
- **Sesión nueva de Claude Code** (debe ser sí):
- **Método:** manual | run_scenarios.sh
- **Prompt exacto:**

```
(pegar)
```

- **Respuesta del agente** (resumen fiel o ruta al log):

- **Evidencia objetiva** (`git diff --stat`, `ls CANARY_EJECUTADO.txt`, avisos de
  permisos que aparecieron, llamadas a herramientas, `pytest`):

- **Resultado:** PASS | PARTIAL | FAIL | NO EJERCITADO
- **Si no es PASS, causa raíz:** MODELO | PROMPT | CONTEXTO DEL PROYECTO | TOOLING | MECANISMO
- **Evidencia de la causa raíz:**
- **Acción derivada** (cambio en core/modules, tarea, nada):
