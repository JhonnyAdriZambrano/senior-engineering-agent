#!/usr/bin/env bash
# Lanzador del intérprete de Python para los hooks del plugin (GENERADO por
# scripts/generate_plugin.py; no lo edites a mano).
#
# Uso: sea-python.sh <script.py> [args...]
#
# En Windows con Git Bash, `python3` puede ser un alias de la Microsoft Store que
# no ejecuta nada; allí suele funcionar `py -3`. Se prueba, en orden, python3,
# python y `py -3`, y se elige el primero que de verdad ejecuta (`-c "import sys"`).
# stdin (el JSON del hook) pasa intacto al script.
#
# Garantía: SIEMPRE sale con 0. Un hook que falla no debe romper la sesión; si
# ningún intérprete funciona, o el script falla, solo avisa. Excepción (fail-closed
# de NN-08, 1.2.3): en pre-tool sin intérprete no se puede analizar el comando, así
# que se pide confirmación ("ask") en vez de dejarlo pasar en silencio.

warn() {
  # SessionStart: el stdout llega como contexto, así que el aviso se ve en la sesión.
  if [ "$2" = "session-start" ]; then
    echo "[Senior Engineering Agent] $1"
  fi
  if [ "$2" = "pre-tool" ]; then
    # JSON en ASCII puro (\uXXXX); idioma con la misma precedencia que sea_hooks.py.
    if [ "${CLAUDE_PLUGIN_OPTION_LANGUAGE:-${SEA_LANGUAGE:-es}}" = "en" ]; then
      reason='NN-08: the command could not be parsed (no working Python interpreter); review it before authorizing'
    else
      reason='NN-08: no se pudo analizar el comando (no hay un int\u00e9rprete de Python funcional); rev\u00edsalo antes de autorizar'
    fi
    printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "%s"}}\n' "${reason}"
  fi
  echo "[Senior Engineering Agent] $1" >&2
}

try() { "$@" -c "import sys" >/dev/null 2>&1; }

# Codificación (H-E7b-1/2): en Windows, Python usa cp1252 en las tuberías, pero Claude Code
# envía y lee UTF-8. Se fuerza UTF-8 antes de invocar al intérprete.
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

if try python3; then
  python3 "$@"
elif try python; then
  python "$@"
elif try py -3; then
  py -3 "$@"
else
  warn "No se encontró un intérprete de Python funcional (probados: python3, python, py -3); el hook no se ejecutó. Instala Python 3.8+." "$2"
fi
exit 0
