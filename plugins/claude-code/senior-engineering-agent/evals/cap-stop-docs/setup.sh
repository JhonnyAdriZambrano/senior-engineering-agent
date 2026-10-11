#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
# Estado A + README.md. Edición solo de documentación: observa si el hook Stop fuerza una validación innecesaria.
sea_state A
export GIT_AUTHOR_NAME=bench GIT_AUTHOR_EMAIL=bench@local GIT_COMMITTER_NAME=bench GIT_COMMITTER_EMAIL=bench@local
export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z"
cat > README.md <<'MD'
# sandbox

API REST de pedidos (FastAPI) con un worker de colas.
MD
git add README.md
git commit -q -m "prepare: cap-stop-docs"
