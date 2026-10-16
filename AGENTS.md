# Instrucciones para agentes que trabajan en ESTE repositorio

Este archivo es para quien **desarrolla** el Senior Engineering Agent (Codex, Cursor, Claude Code y
cualquier agente que lea `AGENTS.md`). No es el adaptador que se instala en proyectos destino: ese es
`adapters/codex/AGENTS.md`.

## Antes de empezar y al terminar

1. Lee `docs/internal/ESTADO_SESION.md`: qué se está haciendo, decisiones pendientes y registro de sesiones.
2. Al terminar, actualízalo: estado actual, siguiente paso y una fila en el registro (fecha, agente, qué hiciste, archivos versionados tocados).

`docs/internal/` es local y no se versiona: si el archivo no existe en tu copia, créalo con esas tres
secciones («Ahora mismo», «Siguiente paso recomendado», «Registro de sesiones»).

## Reglas del repositorio

- Fuente de verdad: `core/`, `modules/`, `manifest.yaml` y `capabilities.yaml`. El plugin
  (`plugins/claude-code/…`), las Skills (`adapters/skills/`) y el núcleo compacto son vistas generadas:
  se regeneran con `scripts/generate_plugin.py`, `scripts/generate_skills.py` y `scripts/generate_compact.py`;
  nunca se editan a mano.
- Validación mínima antes de dar algo por hecho: `python3 tests/test_agent.py` (en Windows, `py -3`) y los tres
  generadores con `--check`.
- Si cambia algo dentro del plugin, sube `manifest.yaml > agent.version` y regenera: la guarda de versión de la CI lo exige.
- Las etiquetas `v*` y las Releases las crea el propietario al cumplir la puerta de salida de `CHANGELOG.md`.
- No borres ramas, etiquetas ni `tests/results/` sin confirmación del propietario.
