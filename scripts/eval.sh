#!/usr/bin/env bash
# Evaluación automatizada del plugin con `claude plugin eval` (sustituye a tests/behavioral/run_scenarios.sh).
# Casos: plugins/claude-code/senior-engineering-agent/evals/ (README.md de esa carpeta: criterio → grader).
# Documentación oficial: https://code.claude.com/docs/en/plugin-evals
#
# Uso:
#   bash scripts/eval.sh <smoke|regression|capability|all> [--runs N] [--max-cost-usd USD] [--out DIR]
#
#   smoke       casos con etiqueta `critical`, 3 corridas, sin línea base (--ablation none).
#   regression  casos con etiqueta `regression` (todos), con línea base (--ablation with-without).
#               Las corridas salen de `runs:` de cada caso (3 en todos desde E3b).
#   capability  casos con etiqueta `capability` (cap-*), con línea base; miden capacidades, no regresiones.
#   all         todos los casos, sin filtrar por etiqueta; igual que regression en lo demás.
#   --runs N    fuerza N corridas por caso y brazo (sustituye a `runs:`).
#   --max-cost-usd / EVAL_MAX_COST_USD   tope de coste estimado (defecto 20; sale con 2 y resultados parciales).
#
# Siempre: --model claude-sonnet-5-5 --trust-plugin --no-publish --json --scaffold --keep-temp.
#   --scaffold: los casos preparan su workspace con setup.sh (scripts escritos en este repositorio).
#   --allow-tools: unión de las herramientas no de solo lectura que listan los casos en `allowed_tools`
#   (los graders `max: 0` sobre una herramienta no concedida pasarían sin comprobar nada).
# Salida (no se versiona): tests/results/evals/<modo>-<fecha>/ con result.json, report.html y traces/.
# Aviso: cada corrida es una llamada real al modelo con tus credenciales (consume plan o API).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="${ROOT}/plugins/claude-code/senior-engineering-agent"
MODEL="claude-sonnet-5-5"
MODE="${1:-}"; [ $# -gt 0 ] && shift
RUNS=""; MAXCOST="${EVAL_MAX_COST_USD:-20}"; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="$2"; shift ;;
    --max-cost-usd) MAXCOST="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
  shift
done
case "${MODE}" in
  smoke) TAGARGS=(--tag critical); ABL=none; [ -n "${RUNS}" ] || RUNS=3 ;;
  regression) TAGARGS=(--tag regression); ABL=with-without ;;
  capability) TAGARGS=(--tag capability); ABL=with-without ;;
  all) TAGARGS=(); ABL=with-without ;;
  *) echo "Uso: $0 <smoke|regression|capability|all> [--runs N] [--max-cost-usd USD] [--out DIR]" >&2; exit 2 ;;
esac
[[ "${MAXCOST}" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-cost-usd debe ser un número (USD)." >&2; exit 2; }
[ -z "${RUNS}" ] || [[ "${RUNS}" =~ ^[0-9]+$ ]] || { echo "--runs debe ser un entero." >&2; exit 2; }

# --- Requisitos ---
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "ABORTADO: Windows nativo no tiene backend de sandbox y los casos conceden Bash. Ejecuta este script desde WSL2." >&2; exit 2 ;;
esac
command -v claude >/dev/null || { echo "Falta el CLI claude (v2.1.269 o posterior)." >&2; exit 2; }
command -v python3 >/dev/null || { echo "Falta python3." >&2; exit 2; }
command -v git >/dev/null || { echo "Falta git (2.31 o posterior)." >&2; exit 2; }
MISSING=()
for tool in bwrap socat; do command -v "${tool}" >/dev/null || MISSING+=("$([ "${tool}" = bwrap ] && echo bubblewrap || echo "${tool}")"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ABORTADO: faltan ${MISSING[*]} (sandbox de Bash). Linux/WSL2: sudo apt install ${MISSING[*]}  ·  macOS no los necesita." >&2
  [ "$(uname -s)" = Darwin ] || exit 2
fi
python3 -m pytest --version >/dev/null 2>&1 || echo "AVISO: python3 sin pytest; test-09-regresion no podrá ejecutar los tests del fixture (pip install pytest)." >&2

# --- Herramientas a conceder: unión de las no de solo lectura que piden los casos ---
mapfile -t GRANTS < <(python3 - "${PLUGIN}/evals" <<'PY'
import glob, os, re, sys
READ_ONLY = {"Read","Glob","Grep","NotebookRead","Skill","AskUserQuestion","Agent","Task","TodoWrite","TaskCreate","TaskGet","TaskList","TaskUpdate","TaskStop"}
found = set()
for p in glob.glob(os.path.join(sys.argv[1], "*", "prompt.md")):
    m = re.search(r"^allowed_tools:\s*\[(.*?)\]", open(p, encoding="utf-8").read(), re.M)
    if m:
        found |= {t.strip().strip("\"'") for t in m.group(1).split(",") if t.strip()} - READ_ONLY
print("\n".join(sorted(found)))
PY
)

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUT:-${ROOT}/tests/results/evals/${MODE}-${STAMP}}"
mkdir -p "${OUT}"
CMD=(claude plugin eval "${PLUGIN}" "${TAGARGS[@]}" --ablation "${ABL}" --model "${MODEL}" --trust-plugin --no-publish
     --scaffold --keep-temp --max-cost-usd "${MAXCOST}" --output-dir "${OUT}" --json "${OUT}/result.json")
[ -z "${RUNS}" ] || CMD+=(--runs "${RUNS}")
[ ${#GRANTS[@]} -eq 0 ] || CMD+=(--allow-tools "${GRANTS[@]}")
echo "== eval ${MODE}: ${CMD[*]}" | tee "${OUT}/command.txt"

set +e
"${CMD[@]}" 2>"${OUT}/stderr.txt"
CODE=$?
set -e
if grep -q "cannot pass with the granted tools" "${OUT}/stderr.txt"; then
  echo "ERROR: algún grader exige una herramienta que no se concedió (resultado NO válido); ver ${OUT}/stderr.txt" >&2
  grep "cannot pass with the granted tools" "${OUT}/stderr.txt" >&2
  CODE=3
fi
python3 "${ROOT}/scripts/eval_report.py" "${OUT}/result.json" --collect-traces "${OUT}/traces" || true
echo "Resultados (no se versionan): ${OUT}"
[ "${CODE}" -eq 0 ] || echo "claude plugin eval terminó con código ${CODE} (1 = algún caso bajo el umbral; 2 = parcial por coste/credenciales)." >&2
exit "${CODE}"
