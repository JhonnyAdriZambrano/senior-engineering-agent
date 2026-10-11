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
# ningún intérprete funciona, o el script falla, solo avisa.

warn() {
  # SessionStart: el stdout llega como contexto, así que el aviso se ve en la sesión.
  if [ "$2" = "session-start" ]; then
    echo "[Senior Engineering Agent] $1"
  fi
  echo "[Senior Engineering Agent] $1" >&2
}

try() { "$@" -c "import sys" >/dev/null 2>&1; }

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
