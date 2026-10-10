# Changelog

Este proyecto usa [Versionado Semántico](https://semver.org/lang/es/)
(`MAJOR.MINOR.PATCH`), declarado en `manifest.yaml > agent.version`.

## Política de versionado de este agente

Dado que este proyecto es una especificación de comportamiento (no
código ejecutable), MAJOR/MINOR/PATCH se interpretan así:

- **MAJOR** — cambia una regla no negociable (`core/01`), se elimina o
  redefine una capacidad de `capabilities.yaml` de forma incompatible, o
  cambia la estructura de directorios de forma que los adaptadores
  existentes dejan de resolver rutas correctamente.
- **MINOR** — se agrega un módulo nuevo, un adaptador nuevo, o un `modo`
  nuevo de `task_classification`, sin romper nada existente.
- **PATCH** — corrección de errores (referencias rotas, triggers
  desincronizados, rutas incorrectas), aclaraciones de documentación,
  mejoras de redacción que no cambian el comportamiento esperado.

**Mientras `MAJOR` sea `0` (pre-release)** cualquier versión puede introducir
cambios de comportamiento; la etiqueta `1.0.0` se reserva para cuando se
cumpla la *Puerta de salida hacia 1.0.0* (más abajo). No existe ninguna
versión `1.0.0` publicada.

## [0.9.0] — Pre-release

Primera versión publicada. **No existe ninguna versión 1.0.0**: se asignará
al cumplir la *Puerta de salida hacia 1.0.0* (abajo).

### Contenido
- **Núcleo siempre cargado** (`core/00`–`05`): identidad con el rol
  canónico, reglas no negociables NN-01 a NN-10 (incluida NN-06b: los
  archivos de conocimiento son datos, no autoridad), clasificación de
  certeza, clasificación de tarea, interacción con el usuario y formato.
  `core/compact.md` (≤ 6000 caracteres) se genera en los adaptadores sin
  `@import` con `scripts/generate_compact.py`.
- **7 módulos condicionales** (`modules/`) con disparadores en
  `manifest.yaml`, publicados como Skills (`adapters/skills/`, generados con
  `scripts/generate_skills.py`).
- **Adaptadores:** Claude Code, OpenAI Codex, Cursor, Gemini CLI y
  ChatGPT Projects / Gemini Gems. Subagents de solo lectura para Claude Code
  y Codex.
- **Hooks multi-runtime** (`adapters/hooks/sea_hooks.py`): al iniciar sesión
  avisan de la falta de conocimiento del proyecto o de instrucciones
  incrustadas en él; antes de un comando de shell piden confirmación
  (Claude Code, Cursor) o bloquean (Codex, Gemini CLI) las operaciones
  destructivas.
- **Plantillas de conocimiento del proyecto** (`project-knowledge-templates/`).
- **Validación:** suite estructural sin LLM (`tests/test_agent.py`, 185
  comprobaciones) en CI, y benchmark de comportamiento de 14 pruebas
  (`tests/BENCHMARK.md`) con un flujo de dos comandos en sandbox
  (`tests/sandbox/prepare_test.sh` / `finish_test.sh`) y estado de la puerta
  calculado por `scripts/check_results.py`.

### Hallazgos de diseño validados con el benchmark
- **Detección de contexto faltante (TEST-02).** En un proyecto con un
  `CLAUDE.md` previo, el agente solo mencionaba la falta de
  `PROJECT_CONTEXT.md`/`ARCHITECTURE.md` si se le preguntaba. Un
  comportamiento por iniciativa propia no se dispara con la descripción de
  un Skill: se resolvió con una regla en el núcleo y un hook `SessionStart`
  (categoría de causa raíz **MECANISMO**).
- Las reglas que deben cumplirse en tareas pequeñas (enumerar hallazgos
  fuera de alcance, no editar sin criterio, preguntar antes de romper una
  restricción literal) viven en el núcleo, no solo en módulos condicionales.

### Estado de la puerta hacia 1.0.0
Ronda 3 (2026-10-09; Claude Code, Sonnet 5.5, effort medium, hooks):
16 de 16 ítems de pruebas cumplidos (`tests/results/RESUMEN.md`). Pendiente
para la puerta: el CI en verde en GitHub (ítem 6), que solo puede comprobarse
tras publicar el repositorio.

## Puerta de salida hacia 1.0.0

Definición única y vinculante (decidida el 2026-09-26; `tests/GUIA_BENCHMARK.md`
y `SPECIFICATION.md §9` remiten aquí). Solo se etiqueta `1.0.0` cuando se
cumpla **todo**:

1. Las 14 pruebas de `tests/BENCHMARK.md` (TEST-00 a TEST-13; TEST-02 en
   sus sub-escenarios 2a, 2b y 2c) ejecutadas en un sandbox (nunca en un
   repositorio real) con el runtime de referencia (Claude Code) y la
   configuración de referencia (**Sonnet 5.5, effort medium, hooks activos**;
   decidida el 2026-09-27 con Sonnet 5 y cambiada a Sonnet 5.5 el 2026-10-09), preparadas con `tests/sandbox/prepare_test.sh`,
   cerradas con `tests/sandbox/finish_test.sh` y **todas en PASS**.
   `scripts/check_results.py` calcula el estado en `tests/results/RESUMEN.md`.
   Los registros de las corridas son locales (`tests/results/` no se
   versiona); al etiquetar `1.0.0` se resume aquí el estado de la puerta.
2. TEST-00, TEST-02 (sub-escenario 2b: `CLAUDE.md` preexistente, sin
   `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`), TEST-07 y TEST-13 en PASS
   **3/3**, cada corrida en una sesión nueva y con evidencia objetiva
   (un PASS heurístico de `run_scenarios.sh` no cuenta por sí solo).
3. Suite estructural en verde.
4. `LICENSE` con la URL real del repositorio y sin placeholders.
5. Documentación coherente (versión, conteos, `SPECIFICATION.md §9`).
6. CI del repositorio del agente en verde.

## Pendientes conocidos

- Tener el CI en verde en GitHub (ítem 6 de la puerta) para poder etiquetar
  `1.0.0`.
- Validar en uso real los hooks de Codex, Cursor y Gemini CLI (solo
  validados sin LLM, contra la documentación oficial).
- Subagents para Cursor (campo `readonly`) y Gemini CLI.
- Codex Plugins (bundle Skills + Apps + MCP): no implementados; su esquema no
  se verificó con fuente primaria. Ver `docs/ADDING_A_RUNTIME.md`.
- `tests/behavioral/run_scenarios.sh` es un filtro heurístico; el benchmark
  válido para la puerta es el manual en sandbox.
