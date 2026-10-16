#!/usr/bin/env bash
# Evaluación automatizada del plugin con `claude plugin eval`.
# Casos: plugins/claude-code/senior-engineering-agent/evals/ (README.md de esa carpeta: criterio → grader).
# Documentación oficial: https://code.claude.com/docs/en/plugin-evals
#
# Uso:
#   bash scripts/eval.sh <smoke|regression|capability|regression-en|all> [--runs N] [--max-cost-usd USD] [--case GLOB] [--with-only] [--exclude-strict] [--out DIR]
#
#   smoke       casos con etiqueta `critical`, 3 corridas, sin línea base (--ablation none).
#   regression  casos con etiqueta `regression` (todos), con línea base (--ablation with-without).
#               Las corridas salen de `runs:` de cada caso (3 en todos desde E3b).
#   capability  casos con etiqueta `capability` (cap-*), con línea base; miden capacidades, no regresiones.
#   regression-en  casos con etiqueta `regression-en` (carpetas en-*: c1, test-00, test-07 y test-13 con prompts y graders en inglés),
#               evaluados sobre una COPIA temporal del plugin con el idioma "en" (D-16). Una evaluación no puede fijar un valor de
#               `userConfig`: `env:` solo admite claves EVAL_* y `claude plugin eval` no lee los ajustes del usuario (pluginConfigs);
#               [HECHO VERIFICADO, CLI 2.1.296] un hook de plugin recibe CLAUDE_PLUGIN_OPTION_LANGUAGE solo si el valor está guardado
#               en pluginConfigs (el `default` NO se exporta). Por eso la copia antepone `CLAUDE_PLUGIN_OPTION_LANGUAGE=en` a los
#               comandos de sea_hooks.py de hooks.json: sea_hooks.py lee la MISMA variable que recibe de Claude Code. El plugin
#               original no se modifica. Como regression: línea base con-sin plugin salvo --with-only.
#   all         todos los casos, sin filtrar por etiqueta; igual que regression en lo demás.
#   --runs N    fuerza N corridas por caso y brazo (sustituye a `runs:`).
#   --case GLOB filtra los casos por nombre (glob de `claude plugin eval --case`, p. ej. --case 'test-09*'); se suma al filtro por etiqueta.
#               Solo admite `*` y `?` [HECHO VERIFICADO, CLI 2.1.296]: --case 'test-0[389]*' no encuentra ningún caso; usa una invocación por caso.
#   --with-only solo el brazo CON plugin (`--ablation none`, sin W/OUT): mide una vez y a la mitad de coste cuando la línea base ya se conoce.
#               Con `--ablation none` el evaluador cuenta también los graders `arm: with-only`; usa scripts/eval_summary.py para excluirlos.
#   --max-cost-usd / EVAL_MAX_COST_USD   tope de coste estimado (defecto 20; sale con 2 y resultados parciales).
#   --exclude-strict  evalúa una COPIA temporal del plugin sin los casos `strict-tools` que la concesión invalidaría (ver abajo);
#               esos casos se miden aparte con --case <nombre>.
#
# Siempre: --model claude-sonnet-5-5 --trust-plugin --no-publish --json --scaffold --keep-temp.
#   --scaffold: los casos preparan su workspace con setup.sh (scripts escritos en este repositorio).
#   --allow-tools: unión de las herramientas no de solo lectura que listan los casos seleccionados (etiqueta y --case) en `allowed_tools`
#   (los graders `max: 0` sobre una herramienta no concedida pasarían sin comprobar nada). La concesión vale para TODOS los casos de la
#   corrida: un caso con la etiqueta `strict-tools` (conjunto cerrado a propósito, p. ej. cap-certeza-sin-ejecutar sin Bash) que recibiría
#   una herramienta que no declara invalida la medición, así que el script ABORTA (auditoría M6, 1.2.3) salvo --exclude-strict. Cálculo:
#   scripts/eval_grants.py.
# Salida (no se versiona): tests/results/evals/<modo>-<fecha>/ con result.json, report.html y traces/.
# Aviso: cada corrida es una llamada real al modelo con tus credenciales (consume plan o API).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="${ROOT}/plugins/claude-code/senior-engineering-agent"
MODEL="claude-sonnet-5-5"
MODE="${1:-}"; [ $# -gt 0 ] && shift
RUNS=""; MAXCOST="${EVAL_MAX_COST_USD:-20}"; OUT=""; CASE=""; WITHONLY=0; EXCLUDE_STRICT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="$2"; shift ;;
    --max-cost-usd) MAXCOST="$2"; shift ;;
    --case) CASE="$2"; shift ;;
    --with-only) WITHONLY=1 ;;
    --exclude-strict) EXCLUDE_STRICT=1 ;;
    --out) OUT="$2"; shift ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
  shift
done
case "${MODE}" in
  smoke) TAGARGS=(--tag critical); ABL=none; [ -n "${RUNS}" ] || RUNS=3 ;;
  regression) TAGARGS=(--tag regression); ABL=with-without ;;
  capability) TAGARGS=(--tag capability); ABL=with-without ;;
  regression-en) TAGARGS=(--tag regression-en); ABL=with-without; [ -n "${CASE}" ] || CASE="en-*" ;;
  all) TAGARGS=(); ABL=with-without ;;
  *) echo "Uso: $0 <smoke|regression|capability|regression-en|all> [--runs N] [--max-cost-usd USD] [--case GLOB] [--with-only] [--exclude-strict] [--out DIR]" >&2; exit 2 ;;
esac
[ "${WITHONLY}" -eq 0 ] || ABL=none
[[ "${MAXCOST}" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-cost-usd debe ser un número (USD)." >&2; exit 2; }
[ -z "${RUNS}" ] || [[ "${RUNS}" =~ ^[0-9]+$ ]] || { echo "--runs debe ser un entero." >&2; exit 2; }

# --- Requisitos ---
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    echo "ABORTADO: Windows nativo no tiene backend de sandbox y los casos conceden Bash. Ejecuta este script desde WSL2." >&2; exit 2 ;;
esac
command -v claude >/dev/null || { echo "Falta el CLI claude (v2.1.269 o posterior)." >&2; exit 2; }
# Intérprete de Python: el mismo criterio que el lanzador del plugin (python3, python, `py -3`; cada uno con `-c "import sys"`).
try() { "$@" -c "import sys" >/dev/null 2>&1; }
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8
if try python3; then PY=(python3)
elif try python; then PY=(python)
elif try py -3; then PY=(py -3)
else echo "Falta un intérprete de Python funcional (probados: python3, python, py -3)." >&2; exit 2
fi
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }   # ruta nativa para Python y claude
command -v git >/dev/null || { echo "Falta git (2.31 o posterior)." >&2; exit 2; }
MISSING=()
for tool in bwrap socat; do command -v "${tool}" >/dev/null || MISSING+=("$([ "${tool}" = bwrap ] && echo bubblewrap || echo "${tool}")"); done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "ABORTADO: faltan ${MISSING[*]} (sandbox de Bash). Linux/WSL2: sudo apt install ${MISSING[*]}  ·  macOS no los necesita." >&2
  [ "$(uname -s)" = Darwin ] || exit 2
fi
"${PY[@]}" -m pytest --version >/dev/null 2>&1 || echo "AVISO: ${PY[*]} sin pytest; test-09-regresion no podrá ejecutar los tests del fixture (pip install pytest)." >&2

# --- Herramientas a conceder (scripts/eval_grants.py): unión de las no de solo lectura que piden los casos de la corrida ---
GARGS=(); [ -z "${CASE}" ] || GARGS+=(--case "${CASE}"); [ ${#TAGARGS[@]} -eq 0 ] || GARGS+=("${TAGARGS[@]}")
grants_json() { "${PY[@]}" "$(native "${ROOT}")/scripts/eval_grants.py" "$(native "${PLUGIN}")/evals" ${GARGS[@]+"${GARGS[@]}"} "$@"; }
# Una lista del JSON, un elemento por línea (sin CR de Windows ni la línea vacía de una lista vacía).
jlist() { "${PY[@]}" -c 'import json,sys; print("\n".join(json.load(sys.stdin)[sys.argv[1]]))' "$1" | tr -d '\r' | sed '/^$/d'; }
G="$(grants_json)"
mapfile -t CONFLICTS < <(printf '%s' "${G}" | jlist strict_conflicts)
EXCLUDE=()
if [ ${#CONFLICTS[@]} -gt 0 ]; then
  if [ "${EXCLUDE_STRICT}" -eq 0 ]; then
    echo "ABORTADO: la concesión de la corrida ($(printf '%s' "${G}" | jlist grants | paste -sd' ' -)) invalidaría los casos strict-tools: ${CONFLICTS[*]}." >&2
    echo "  Mídelos aparte (bash scripts/eval.sh ${MODE} --case <nombre>) y repite esta corrida con --exclude-strict." >&2
    exit 2
  fi
  EXCLUDE=("${CONFLICTS[@]}")
  EXARGS=(); for c in "${EXCLUDE[@]}"; do EXARGS+=(--exclude "${c}"); done
  G="$(grants_json "${EXARGS[@]}")"
  echo "Excluidos de esta corrida (strict-tools; mídelos con --case): ${EXCLUDE[*]}"
fi
[ -n "$(printf '%s' "${G}" | jlist cases)" ] || { echo "ABORTADO: ningún caso seleccionado." >&2; exit 2; }
mapfile -t GRANTS < <(printf '%s' "${G}" | jlist grants)

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUT:-${ROOT}/tests/results/evals/${MODE}-${STAMP}}"
mkdir -p "${OUT}"
TARGET="${PLUGIN}"
if [ "${MODE}" = "regression-en" ] || [ ${#EXCLUDE[@]} -gt 0 ]; then
  # Copia temporal del plugin: sin los casos excluidos y, en regression-en, con CLAUDE_PLUGIN_OPTION_LANGUAGE=en delante de los
  # comandos de sea_hooks.py (ver la cabecera). El plugin original no se modifica.
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/sea-eval-XXXXXX")"
  cp -a "${PLUGIN}" "${WORK}/senior-engineering-agent"
  rm -rf "${WORK}/senior-engineering-agent/evals/results"
  for c in ${EXCLUDE[@]+"${EXCLUDE[@]}"}; do rm -rf "${WORK}/senior-engineering-agent/evals/${c}"; done
  TARGET="$(native "${WORK}/senior-engineering-agent")"
fi
if [ "${MODE}" = "regression-en" ]; then
  "${PY[@]}" - "${TARGET}/hooks/hooks.json" <<'PY'
import json, sys
path = sys.argv[1]
cfg = json.load(open(path, encoding="utf-8"))
n = 0
for entries in cfg["hooks"].values():
    for entry in entries:
        for h in entry["hooks"]:
            if "sea_hooks.py" in h.get("command", ""):
                h["command"] = "CLAUDE_PLUGIN_OPTION_LANGUAGE=en " + h["command"]
                n += 1
if n == 0:
    sys.exit("ERROR: no se encontró ningún comando de sea_hooks.py en hooks.json")
json.dump(cfg, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
print(f"Copia con idioma «en»: {n} comandos de sea_hooks.py con CLAUDE_PLUGIN_OPTION_LANGUAGE=en")
PY
fi
CMD=(claude plugin eval "${TARGET}" "${TAGARGS[@]}" --ablation "${ABL}" --model "${MODEL}" --trust-plugin --no-publish
     --scaffold --keep-temp --max-cost-usd "${MAXCOST}" --output-dir "${OUT}" --json "${OUT}/result.json")
[ -z "${RUNS}" ] || CMD+=(--runs "${RUNS}")
[ -z "${CASE}" ] || CMD+=(--case "${CASE}")
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
"${PY[@]}" "$(native "${ROOT}")/scripts/eval_report.py" "$(native "${OUT}")/result.json" --collect-traces "$(native "${OUT}")/traces" || true
[ -z "${WORK:-}" ] || rm -rf "${WORK}"
echo "Resultados (no se versionan): ${OUT}"
[ "${CODE}" -eq 0 ] || echo "claude plugin eval terminó con código ${CODE} (1 = algún caso bajo el umbral; 2 = parcial por coste/credenciales)." >&2
exit "${CODE}"
