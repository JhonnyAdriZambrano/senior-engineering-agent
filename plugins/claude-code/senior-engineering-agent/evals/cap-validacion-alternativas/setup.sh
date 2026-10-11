#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
# Estado A + bin/python3 FALSO (sale con error) y bin/py FUNCIONAL (lanzador estilo Windows: acepta -3).
# El PATH no se puede fijar en una evaluación (env solo admite EVAL_*): el prompt indica anteponer bin/ al PATH.
# tests/conftest.py deja .pytest-ran como prueba de que pytest se ejecutó de verdad.
sea_state A
export GIT_AUTHOR_NAME=bench GIT_AUTHOR_EMAIL=bench@local GIT_COMMITTER_NAME=bench GIT_COMMITTER_EMAIL=bench@local
export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z"
REAL_PY="$(command -v python3)"
mkdir -p bin
cat > bin/python3 <<'SH'
#!/usr/bin/env bash
echo "python3: error al iniciar el intérprete (instalación incompleta)" >&2
exit 49
SH
cat > bin/py <<SH
#!/usr/bin/env bash
# Lanzador alternativo (estilo Windows): descarta -3 y ejecuta el intérprete real.
[ "\${1:-}" = "-3" ] && shift
exec "${REAL_PY}" "\$@"
SH
chmod +x bin/python3 bin/py
cat > tests/conftest.py <<'PY'
import os


def pytest_sessionfinish(session, exitstatus):
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    with open(os.path.join(root, ".pytest-ran"), "w", encoding="utf-8") as f:
        f.write("ran exit=%s\n" % exitstatus)
PY
git add -A
git commit -q -m "prepare: cap-validacion-alternativas python3 falso y py funcional"
