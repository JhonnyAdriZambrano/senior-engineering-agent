#!/usr/bin/env bash
# Paso 2 de 2 de cada prueba: recoge la evidencia objetiva del sandbox, copia la
# transcripción exportada, te pregunta el resultado, completa el registro y
# regenera tests/results/RESUMEN.md. Ver tests/sandbox/finish_test.py (--help).
set -euo pipefail
# Windows (Git Bash): salida UTF-8 y sin buffer para que los avisos y preguntas se vean al instante.
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8 PYTHONUNBUFFERED=1
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for cand in python3 python "py -3"; do
  if ${cand} -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1; then
    exec ${cand} "${HERE}/finish_test.py" "$@"
  fi
done
echo "ABORTADO: se necesita Python 3.8+ (python3, python o py -3)." >&2
exit 2
