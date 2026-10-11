#!/usr/bin/env bash
# Aceptación práctica de los hooks (E7c) — SIN coste de modelo, compatible con Git Bash en Windows.
#
# Ejecuta el LANZADOR REAL del plugin (scripts/sea-python.sh) con el intérprete real del equipo sobre
# entradas JSON del hook PreToolUse, y comprueba que cada salida sea UTF-8/JSON válido y que el motivo
# de NN-08 diga «operación» con la tilde intacta (H-E7b-1, H-E7b-2).
#
# Uso:  bash tests/acceptance/hooks_practice.sh
# Salida: tabla PASS/FAIL; el SCRIPT sale con 1 si algún caso falla (el hook, en cambio, sale siempre con 0).
# Obligatoria en el PC del usuario antes de cada etiqueta (tests/GUIA_BENCHMARK.md, «Aceptación práctica»).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN="$HERE/../../plugins/claude-code/senior-engineering-agent"
LAUNCHER="$PLUGIN/scripts/sea-python.sh"
SEA="$PLUGIN/adapters/hooks/sea_hooks.py"
unset PYTHONUTF8 PYTHONIOENCODING   # el lanzador debe fijarlos él; no se heredan del entorno de prueba

# Intérprete propio del script (solo para validar las salidas): mismo orden que el lanzador.
PY=()
for cand in "python3" "python" "py -3"; do
  # shellcheck disable=SC2086
  if $cand -c "import sys" >/dev/null 2>&1; then read -r -a PY <<<"$cand"; break; fi
done
if [ ${#PY[@]} -eq 0 ]; then echo "FAIL: no hay un intérprete de Python funcional (python3, python, py -3)"; exit 1; fi
[ -f "$LAUNCHER" ] || { echo "FAIL: no existe el lanzador $LAUNCHER"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
VALIDATOR="$TMP/validate.py"
cat >"$VALIDATOR" <<'PYEOF'
import json, sys
# argv: <archivo de salida> <ask|none>
raw = open(sys.argv[1], "rb").read()
want = sys.argv[2]
if want == "none":
    sys.exit(0 if raw.strip() == b"" else "se esperaba SIN salida y hay: %r" % raw[:120])
try:
    text = raw.decode("utf-8")
except UnicodeDecodeError as e:
    sys.exit("la salida no es UTF-8 válido: %s" % e)
try:
    out = json.loads(text)
except ValueError as e:
    sys.exit("la salida no es JSON válido: %s" % e)
h = out.get("hookSpecificOutput") or {}
if h.get("permissionDecision") != "ask":
    sys.exit("decisión %r (se esperaba 'ask')" % h.get("permissionDecision"))
reason = h.get("permissionDecisionReason", "")
if "operación" not in reason or "�" in reason:
    sys.exit("el motivo no contiene «operación» legible: %r" % reason[:120])
PYEOF

FAILS=0; ROWS=()
run_case() {  # nombre, herramienta, comando, esperado (ask|none)
  local name="$1" tool="$2" cmd="$3" want="$4" out="$TMP/out.bin" input msg
  input="$("${PY[@]}" -c 'import json,sys; sys.stdout.buffer.write(json.dumps({"tool_name": sys.argv[1], "tool_input": {"command": sys.argv[2]}}, ensure_ascii=False).encode("utf-8"))' "$tool" "$cmd")"
  printf '%s' "$input" | bash "$LAUNCHER" "$SEA" pre-tool --runtime claude-code >"$out" 2>"$TMP/err.txt"
  if msg="$("${PY[@]}" "$VALIDATOR" "$out" "$want" 2>&1)"; then
    ROWS+=("PASS|$name|$want|")
  else
    ROWS+=("FAIL|$name|$want|$msg"); FAILS=$((FAILS + 1))
  fi
}

run_case 'Bash: git reset --hard HEAD~1'                 Bash       'git reset --hard HEAD~1' ask
run_case 'PowerShell: git reset --hard HEAD~1'           PowerShell 'git reset --hard HEAD~1' ask
run_case 'PowerShell: reset + echo "Índice" (no cp1252)' PowerShell 'git reset --hard HEAD~1; echo "Índice"' ask
run_case 'PowerShell: Remove-Item -Recurse -Force x'     PowerShell 'Remove-Item -Recurse -Force x' ask
run_case 'PowerShell: Get-ChildItem'                     PowerShell 'Get-ChildItem' none

echo "Aceptación práctica de hooks — lanzador real: ${LAUNCHER#"$HERE"/../../}"
echo "Intérprete de validación: ${PY[*]}"
printf '%-6s %-52s %-9s\n' RESULT CASO ESPERADO
for row in "${ROWS[@]}"; do
  IFS='|' read -r res name want msg <<<"$row"
  printf '%-6s %-52s %-9s\n' "$res" "$name" "$want"
  [ -n "$msg" ] && echo "         -> $msg"
done
if [ "$FAILS" -ne 0 ]; then echo "RESULTADO: $FAILS caso(s) FAIL"; exit 1; fi
echo "RESULTADO: ${#ROWS[@]} casos PASS"
