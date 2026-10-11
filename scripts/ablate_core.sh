#!/usr/bin/env bash
# Ablación del núcleo (D-17, E3d): mide qué aporta cada archivo de core/02…05 quitándolo del arranque.
# Documentación oficial de las evaluaciones: https://code.claude.com/docs/en/plugin-evals
#
# Uso:
#   bash scripts/ablate_core.sh <completo|sin-02|sin-03|sin-04|sin-05> [--runs N] [--max-cost-usd USD] [--out DIR] [--prepare-only]
#
#   completo    línea base: el plugin generado sin quitar nada.
#   sin-0X      quita de hooks/hooks.json (matchers startup, clear y compact) SOLO la entrada que inyecta core/0X-*.md
#               (la que hace `cat …/core/0X-….md`); el archivo sigue en el plugin y no se toca nada más.
#   --runs N    corridas por caso (defecto 3).
#   --max-cost-usd / ABLATE_MAX_COST_USD   tope de coste de ESTA variante (defecto 2.6 = 13 USD / 5 variantes); sale con 2 y resultados parciales.
#   --prepare-only   solo prepara la copia temporal, imprime la orden y no llama al modelo (coste 0; lo usa tests/test_agent.py).
#
# Qué hace:
#   1. Copia el plugin generado (plugins/claude-code/senior-engineering-agent) a un directorio temporal.
#   2. En la copia deja en evals/ SOLO estos 11 casos (y _shared): c1-rol-exacto, c3-titulos-nucleo, test-00-instalacion,
#      test-02a-contexto-faltante, test-02b-claude-md-previo, test-03-user-interaction, test-07-inyeccion, test-08-alcance,
#      test-08b-alcance-autorizado, test-09-regresion, test-13-destructivo.
#   3. Aplica la variante a hooks/hooks.json de la copia.
#   4. Ejecuta `claude plugin eval <copia> --ablation none --runs N` con las mismas opciones que scripts/eval.sh
#      (--model claude-sonnet-5-5, --trust-plugin, --no-publish, --scaffold, --keep-temp, --allow-tools = unión de las herramientas
#      no de solo lectura de esos 11 casos, --json) y recoge las transcripciones.
#   --ablation none: solo brazo con plugin (la comparación se hace entre variantes, no contra «sin plugin»).
# Salida (no se versiona): tests/results/evals/ablation-<variante>-<fecha>/ con result.json, command.txt, stderr.txt, traces/.
# Intérprete: python3, python o `py -3` (el primero que funcione); si ninguno, error y salida 2. --prepare-only funciona en Windows (Git Bash).
# Las cinco variantes deben ejecutarse en la misma sesión y con el mismo modelo para que sean comparables.
# Aviso: cada corrida es una llamada real al modelo con tus credenciales (consume plan o API).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN="${ROOT}/plugins/claude-code/senior-engineering-agent"
MODEL="claude-sonnet-5-5"
CASES=(c1-rol-exacto c3-titulos-nucleo test-00-instalacion test-02a-contexto-faltante test-02b-claude-md-previo test-03-user-interaction
       test-07-inyeccion test-08-alcance test-08b-alcance-autorizado test-09-regresion test-13-destructivo)
VARIANT="${1:-}"; [ $# -gt 0 ] && shift
RUNS=3; MAXCOST="${ABLATE_MAX_COST_USD:-2.6}"; OUT=""; PREPARE_ONLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="$2"; shift ;;
    --max-cost-usd) MAXCOST="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --prepare-only) PREPARE_ONLY=1 ;;
    *) echo "Argumento desconocido: $1" >&2; exit 2 ;;
  esac
  shift
done
case "${VARIANT}" in
  completo) DROP="" ;;
  sin-02|sin-03|sin-04|sin-05) DROP="core/0${VARIANT#sin-0}-" ;;
  *) echo "Uso: $0 <completo|sin-02|sin-03|sin-04|sin-05> [--runs N] [--max-cost-usd USD] [--out DIR] [--prepare-only]" >&2; exit 2 ;;
esac
[[ "${MAXCOST}" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "--max-cost-usd debe ser un número (USD)." >&2; exit 2; }
[[ "${RUNS}" =~ ^[0-9]+$ ]] || { echo "--runs debe ser un entero." >&2; exit 2; }

# --- Intérprete de Python: el mismo criterio que el lanzador del plugin (scripts/sea-python.sh) ---
# En Windows (Git Bash) `python3` puede ser un alias de la Microsoft Store que no ejecuta nada; allí suele funcionar `py -3`.
# Se prueba, en orden, python3, python y `py -3`, y se elige el primero que de verdad ejecuta (`-c "import sys"`).
try() { "$@" -c "import sys" >/dev/null 2>&1; }
export PYTHONUTF8=1 PYTHONIOENCODING=utf-8   # en Windows Python usaría cp1252 en las tuberías
if try python3; then PY=(python3)
elif try python; then PY=(python)
elif try py -3; then PY=(py -3)
else
  echo "ERROR: no se encontró un intérprete de Python funcional (probados: python3, python, py -3). Instala Python 3.8+." >&2
  exit 2
fi

if [ "${PREPARE_ONLY}" -eq 0 ]; then
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) echo "ABORTADO: Windows nativo no tiene backend de sandbox y los casos conceden Bash. Ejecuta desde WSL2." >&2; exit 2 ;;
  esac
  command -v claude >/dev/null || { echo "Falta el CLI claude (v2.1.269 o posterior)." >&2; exit 2; }
  command -v git >/dev/null || { echo "Falta git (2.31 o posterior)." >&2; exit 2; }
  for tool in bwrap socat; do
    command -v "${tool}" >/dev/null || [ "$(uname -s)" = Darwin ] || { echo "ABORTADO: falta ${tool} (sandbox de Bash)." >&2; exit 2; }
  done
  "${PY[@]}" -m pytest --version >/dev/null 2>&1 || echo "AVISO: python3 sin pytest; test-09-regresion no podrá ejecutar los tests del fixture." >&2
fi

# Rutas hacia programas nativos (Python, claude) y las que imprimimos: en Windows (Git Bash) mktemp y pwd dan rutas POSIX de MSYS (/tmp/…, /d/a/…)
# que el Python nativo no puede abrir; con `cygpath -m` salen en forma mixta (C:/Users/…/Temp/…). En Linux/macOS (sin cygpath) no cambian.
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

# --- 1-3. Copia temporal con 11 casos y la variante aplicada ---
WORK="$(mktemp -d "${TMPDIR:-/tmp}/sea-ablate-XXXXXX")"
COPY="${WORK}/senior-engineering-agent"
COPY_N="$(native "${COPY}")"   # ruta nativa: la que se imprime y la que reciben Python y claude
cp -a "${PLUGIN}" "${COPY}"
rm -rf "${COPY}/evals/results"
find "${COPY}/evals" -mindepth 1 -maxdepth 1 ! -name _shared ! -name README.md -exec rm -rf {} +
for c in "${CASES[@]}"; do cp -a "${PLUGIN}/evals/${c}" "${COPY}/evals/${c}"; done
"${PY[@]}" - "${COPY_N}/hooks/hooks.json" "${DROP}" <<'PY'
import json, sys
path, drop = sys.argv[1], sys.argv[2]
cfg = json.load(open(path, encoding="utf-8"))
if drop:
    removed = 0
    for entry in cfg["hooks"]["SessionStart"]:                # startup, clear y compact
        before = len(entry["hooks"])
        entry["hooks"] = [h for h in entry["hooks"] if f"/{drop}" not in h.get("command", "") or "cat " not in h.get("command", "")]
        removed += before - len(entry["hooks"])
    if removed != len(cfg["hooks"]["SessionStart"]):
        sys.exit(f"ERROR: se esperaba quitar 1 entrada por matcher ({len(cfg['hooks']['SessionStart'])}), se quitaron {removed}")
json.dump(cfg, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
PY
echo "Copia preparada: ${COPY_N} (variante ${VARIANT}; $(find "${COPY}/evals" -mindepth 1 -maxdepth 1 -type d ! -name _shared | wc -l) casos)"

# --- Herramientas a conceder: unión de las no de solo lectura que piden los 11 casos ---
mapfile -t GRANTS < <("${PY[@]}" - "${COPY_N}/evals" <<'PY'
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
[ ${#GRANTS[@]} -eq 0 ] || GRANTS=("${GRANTS[@]//$'\r'/}")   # Python en Windows termina las líneas con CRLF

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="${OUT:-${ROOT}/tests/results/evals/ablation-${VARIANT}-${STAMP}}"
mkdir -p "${OUT}"
CMD=(claude plugin eval "${COPY_N}" --ablation none --runs "${RUNS}" --model "${MODEL}" --trust-plugin --no-publish
     --scaffold --keep-temp --max-cost-usd "${MAXCOST}" --output-dir "${OUT}" --json "${OUT}/result.json")
[ ${#GRANTS[@]} -eq 0 ] || CMD+=(--allow-tools "${GRANTS[@]}")
echo "== ablación ${VARIANT}: ${CMD[*]}" | tee "${OUT}/command.txt"
if [ "${PREPARE_ONLY}" -eq 1 ]; then
  echo "(--prepare-only) copia en ${COPY_N}; no se ejecutó el modelo."
  exit 0
fi

set +e
"${CMD[@]}" 2>"${OUT}/stderr.txt"
CODE=$?
set -e
if grep -q "cannot pass with the granted tools" "${OUT}/stderr.txt"; then
  echo "ERROR: algún grader exige una herramienta que no se concedió (resultado NO válido); ver ${OUT}/stderr.txt" >&2
  CODE=3
fi
"${PY[@]}" "$(native "${ROOT}")/scripts/eval_report.py" "$(native "${OUT}")/result.json" --collect-traces "$(native "${OUT}")/traces" || true
rm -rf "${WORK}"
echo "Resultados (no se versionan): ${OUT}"
[ "${CODE}" -eq 0 ] || echo "claude plugin eval terminó con código ${CODE} (1 = algún caso bajo el umbral; 2 = parcial por coste/credenciales)." >&2
exit "${CODE}"
