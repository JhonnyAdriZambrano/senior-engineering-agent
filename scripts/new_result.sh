#!/usr/bin/env bash
# Crea el registro de una corrida del benchmark ya prellenado.
# Normalmente lo llama tests/sandbox/prepare_test.sh; también puede usarse solo.
#
# Uso: bash scripts/new_result.sh TEST-XX [ruta-del-sandbox]
#   ruta-del-sandbox: por defecto $HOME/sandbox/sea-bench. Se niega si no es un
#   sandbox marcado (.sea-sandbox): una corrida fuera del sandbox no cuenta
#   para la puerta hacia 1.0.0 (CHANGELOG.md).
#
# Lee el estado y los hooks de <sandbox>/.sea-sandbox y, si la prueba se
# preparó con prepare_test.sh, el sub-escenario y el commit base de
# <sandbox>/.git/sea-test.env. Imprime en la última línea la ruta del registro.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="${1:-}"
SANDBOX="${2:-${HOME}/sandbox/sea-bench}"
NUM="$(printf '%s' "${RAW}" | sed -E 's/^(TEST-)?([0-9]{1,2})$/\2/')"
[[ "${NUM}" =~ ^[0-9]{1,2}$ ]] || { echo "Uso: $0 TEST-XX [ruta-del-sandbox]" >&2; exit 2; }
ID="$(printf 'TEST-%02d' "$((10#${NUM}))")"

TITLE="$(grep -m1 -E "^## ${ID} — " "${ROOT}/tests/BENCHMARK.md" | sed -E "s/^## ${ID} — //; s/ \(.*$//")" || true
[ -n "${TITLE}" ] || { echo "ABORTADO: ${ID} no existe en tests/BENCHMARK.md." >&2; exit 2; }

MARK="${SANDBOX}/.sea-sandbox"
[ -f "${MARK}" ] || { echo "ABORTADO: ${SANDBOX} no es un sandbox de tests/sandbox/setup_sandbox.sh (falta .sea-sandbox)." >&2; exit 2; }
STATE="$(sed -n 's/^estado=//p' "${MARK}")"
HOOKS="$(sed -n 's/^hooks=//p' "${MARK}")"
case "${HOOKS}" in 1) HOOKS_TXT="sí (configuración de hooks del adaptador)";; 0) HOOKS_TXT="no (--sin-hooks)";; *) HOOKS_TXT="desconocido";; esac

TESTENV="${SANDBOX}/.git/sea-test.env"
SUB=""; BASE=""; PREPARED=""
if [ -f "${TESTENV}" ]; then
  SUB="$(sed -n 's/^sub=//p' "${TESTENV}")"
  BASE="$(sed -n 's/^base_commit=//p' "${TESTENV}")"
  PREPARED="$(sed -n 's/^test=//p' "${TESTENV}")"
fi
if [ "${PREPARED}" = "${ID}" ]; then
  RECREATED="sí (tests/sandbox/prepare_test.sh; commit base ${BASE:0:7})"
else
  RECREATED="(sí / no — debe ser sí; usa tests/sandbox/prepare_test.sh)"
fi

VERSION="$(sed -n -E 's/^[[:space:]]*version:[[:space:]]*"?([0-9][^" #]*)"?.*/\1/p' "${ROOT}/manifest.yaml" | head -1)"
COMMIT="$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null)" || \
  COMMIT="sin commit ($(git -C "${ROOT}" rev-parse --short HEAD 2>&1 | head -1 | tr -d '\r' | cut -c1-90))"
CLI="$(claude --version 2>/dev/null | head -1 || true)"; CLI="${CLI:-no detectado — anótalo}"
DATE="$(date +%F)"

TAG="${ID}${SUB#2}"   # TEST-02 + sub "2b" -> TEST-02b
N=1
while ls "${ROOT}/tests/results/"*"_${TAG}_r${N}.md" >/dev/null 2>&1; do N=$((N+1)); done
OUT="${ROOT}/tests/results/${DATE}_${TAG}_r${N}.md"
[ ! -e "${OUT}" ] || { echo "ABORTADO: ${OUT} ya existe." >&2; exit 2; }

PROMPT="$(awk -v id="### ${ID} " 'index($0,id)==1{f=1;next} /^### /{f=0} f' "${ROOT}/tests/GUIA_BENCHMARK.md" \
  | grep -o '«[^»]*»' | head -1 | sed 's/^«//; s/»$//' || true)"
PROMPT="${PROMPT:-(pegar el prompt exacto)}"
SUBTXT=""; [ -n "${SUB}" ] && SUBTXT=" (sub-escenario ${SUB})"

cat > "${OUT}" <<MD
# ${ID} — ${TITLE}${SUBTXT}

Procedimiento: \`tests/GUIA_BENCHMARK.md\`. Criterios: \`tests/BENCHMARK.md\`.
Creado con \`scripts/new_result.sh\`; \`tests/sandbox/finish_test.sh\` completa la evidencia y el resultado.

- **Fecha:** ${DATE}
- **Repetición:** r${N}
- **Versión del agente / commit:** ${VERSION} / ${COMMIT}
- **Runtime:** Claude Code
- **CLI / Modelo / Effort:** ${CLI} / (modelo) / (effort)
- **Sandbox y estado de partida:** ${SANDBOX} — estado ${STATE}${SUBTXT}
- **Hooks activos:** ${HOOKS_TXT}
- **Sandbox recreado antes de esta prueba:** ${RECREATED}
- **Sesión nueva de Claude Code:** (sí / no — debe ser sí)
- **Método:** manual
- **Prompt exacto** (sugerido por la guía; corrígelo si pegaste otro):

\`\`\`
${PROMPT}
\`\`\`

- **Transcripción:** (la añade finish_test.sh desde /export)
- **Observaciones del evaluador:**

- **Resultado:** PASS | PARTIAL | FAIL | NO EJERCITADO
- **Si no es PASS, causa raíz:** MODELO | PROMPT | CONTEXTO DEL PROYECTO | TOOLING | MECANISMO
- **Acción derivada:**
MD
echo "${OUT}"
