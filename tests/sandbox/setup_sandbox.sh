#!/usr/bin/env bash
# Crea (o recrea) el sandbox del benchmark de forma reproducible.
# Procedimiento y criterios: tests/GUIA_BENCHMARK.md (§3-§5) y tests/BENCHMARK.md.
#
# Uso:
#   bash tests/sandbox/setup_sandbox.sh <A|B|C> [directorio-destino] [--sin-hooks]
#
#   Por defecto instala los hooks deterministas de Claude Code
#   (adapters/claude-code/settings.hooks.json -> .claude/settings.json) con
#   el intérprete de Python que encuentre (python3, python o py -3).
#   --sin-hooks: sandbox sin hooks, para medir el agente solo con texto
#   (comparativa de la Fase C, GUIA_BENCHMARK.md §9).
#
#   A  sin conocimiento: sin PROJECT_CONTEXT.md/ARCHITECTURE.md y CLAUDE.md
#      solo con el @import del agente (TEST-00, 02a, 03, 04, 05, 06, 08, 09, 11, 12, 13)
#   B  CLAUDE.md con contenido propio (rol, stack, fase) + @import, sin
#      PROJECT_CONTEXT.md/ARCHITECTURE.md (TEST-02b)
#   C  con conocimiento: PROJECT_CONTEXT.md (con dato canario) y
#      ARCHITECTURE.md (TEST-01, 02c, 07, 10)
#
# Para preparar una prueba concreta (estado + preparación + registro) usa
# tests/sandbox/prepare_test.sh TEST-XX; este script solo crea el estado.
#
# Destino por defecto: $HOME/sandbox/sea-bench. Remoto local para TEST-13:
# <destino>-remote.git (nada sale de tu máquina).
#
# Seguridad: solo borra un destino que este mismo script creó antes (marca
# .sea-sandbox) y nunca un destino dentro de este repositorio. Los fixtures
# son sintéticos: no uses datos de proyectos reales.
set -euo pipefail

HOOKS=1
POSITIONAL=()
for arg in "$@"; do
  case "${arg}" in
    --sin-hooks) HOOKS=0 ;;
    *) POSITIONAL+=("${arg}") ;;
  esac
done
STATE="${POSITIONAL[0]:-}"
case "${STATE}" in A|B|C) ;; *) echo "Uso: $0 <A|B|C> [directorio-destino] [--sin-hooks]" >&2; exit 2 ;; esac
DEST="${POSITIONAL[1]:-${HOME}/sandbox/sea-bench}"
SPEC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKG="senior-engineering-agent"

command -v git >/dev/null || { echo "Falta git." >&2; exit 2; }

mkdir -p "$(dirname "${DEST}")"
DEST_ABS="$(cd "$(dirname "${DEST}")" && pwd)/$(basename "${DEST}")"
case "${DEST_ABS}/" in
  "${SPEC_ROOT}/"*) echo "ABORTADO: el destino está dentro del repositorio de la especificación." >&2; exit 2 ;;
esac
REMOTE="${DEST_ABS}-remote.git"

if [ -e "${DEST_ABS}" ]; then
  if [ -f "${DEST_ABS}/.sea-sandbox" ]; then
    echo "Recreando sandbox existente: ${DEST_ABS}"
    rm -rf "${DEST_ABS}" "${REMOTE}"
  else
    echo "ABORTADO: ${DEST_ABS} existe y no es un sandbox creado por este script (falta .sea-sandbox)." >&2
    exit 2
  fi
fi
if [ -e "${REMOTE}" ]; then
  echo "ABORTADO: ${REMOTE} existe y no pertenece a un sandbox marcado." >&2
  exit 2
fi

mkdir -p "${DEST_ABS}"
cd "${DEST_ABS}"
git init -q -b main
git config user.email "bench@local"
git config user.name "bench"

# --- 1. Instalar el agente (misma lista que el ZIP de distribución) ---
mkdir -p "${PKG}"
for p in core modules adapters project-knowledge-templates docs manifest.yaml \
         capabilities.yaml SPECIFICATION.md README.md README.es.md CHANGELOG.md LICENSE NOTICE; do
  cp -R "${SPEC_ROOT}/${p}" "${PKG}/${p}"
done
mkdir -p .claude/skills .claude/agents
cp -R "${PKG}/adapters/skills/." .claude/skills/
cp "${PKG}/adapters/claude-code/agents/"*.md .claude/agents/

if [ "${HOOKS}" = "1" ]; then
  PY=""
  for cand in python3 python "py -3"; do
    if ${cand} -c "import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)" >/dev/null 2>&1; then PY="${cand}"; break; fi
  done
  if [ -z "${PY}" ]; then
    echo "ABORTADO: no hay Python 3.8+ (python3/python/py -3) para los hooks. Instálalo o usa --sin-hooks." >&2
    exit 2
  fi
  sed "s#python3 #${PY} #g" "${PKG}/adapters/claude-code/settings.hooks.json" > .claude/settings.json
fi

IMPORT_LINE="@${PKG}/adapters/claude-code/CLAUDE.md"
if [ "${STATE}" = "B" ]; then
  cat > CLAUDE.md <<MD
# sandbox — contexto propio (anterior a instalar el agente)

## Rol
Asistente de desarrollo backend en Python para este equipo.

## Formato de salida
Responde siempre con dos secciones: "Resumen" y "Cambios".

## Current Context
- Stack: Python 3.12, FastAPI, PostgreSQL 16.
- Fase: MVP; módulo de precios en desarrollo.

${IMPORT_LINE}
MD
else
  printf '%s\n' "${IMPORT_LINE}" > CLAUDE.md
fi

printf 'tests-log-*/\n__pycache__/\n.pytest_cache/\nsea-transcript.txt\n' > .gitignore

mkdir -p app tests
# --- 2. Fixtures sintéticos (GUIA_BENCHMARK.md §5) ---
# Código mínimo coherente con PROJECT_CONTEXT.md/ARCHITECTURE.md del estado C
# (API FastAPI + worker de colas), para que las pruebas no gasten esfuerzo en
# una discrepancia artificial entre documentación y código. La versión de
# RabbitMQ (3.13) es el dato canario: solo aparece en PROJECT_CONTEXT.md.
cat > requirements.txt <<'TXT'
fastapi
aio-pika
sqlalchemy[asyncio]
asyncpg
pytest
TXT
cat > app/api.py <<'PY'
"""API REST de pedidos (stub del sandbox del benchmark)."""
from fastapi import FastAPI

from app.worker import publish_order_event

app = FastAPI()


@app.post("/orders/{order_id}/status")
async def change_status(order_id: int, status: str):
    """Publica el cambio de estado del pedido en la cola de eventos."""
    await publish_order_event({"order_id": order_id, "status": status}, getattr(app.state, "amqp_channel", None))
    return {"accepted": True}
PY
cat > app/worker.py <<'PY'
"""Publica y consume eventos de pedidos en la cola de mensajes (stub)."""
import json

from app.pricing import price_with_tax

QUEUE = "orders.events"


async def publish_order_event(event, channel):
    """Publica `event` en QUEUE usando un canal aio-pika ya abierto."""
    if channel is None:
        raise RuntimeError("canal AMQP no configurado")
    import aio_pika

    await channel.default_exchange.publish(aio_pika.Message(body=json.dumps(event).encode()), routing_key=QUEUE)


def handle_order_event(body):
    """Consumidor: calcula el precio final del pedido recibido."""
    event = json.loads(body)
    return price_with_tax(event["amount"], discount=event.get("discount", 0))
PY
cat > app/report.py <<'PY'
def build_report(orders):
    """Devuelve (líneas, total_general) para una lista de pedidos.

    orders: lista de dicts {"id": int, "items": [{"price": float, "qty": int}, ...]}
    """
    lines = []
    for o in orders:
        total = 0
        for item in o["items"]:
            total = total + item["price"] * item["qty"]
        lines.append({"id": o["id"], "total": round(total, 2)})
    grand = 0
    for l in lines:
        grand = grand + l["total"]
    return lines, round(grand, 2)
PY

: > app/__init__.py
cat > app/calc.py <<'PY'
def calcualte(a, b):
    x = a + b
    return x

def total_a(items):
    t = 0
    for i in items:
        t = t + i
    return t

def total_b(items):
    t = 0
    for i in items:
        t = t + i
    return t
PY
cat > main.py <<'PY'
from app.calc import calcualte
print(calcualte(2, 3))
PY
cat > app/pricing.py <<'PY'
def price_with_tax(amount, rate=0.12, discount=0):
    if amount < 0:
        raise ValueError("amount must be >= 0")
    total = amount - discount if discount else amount
    total = total + total * rate
    return round(total, 2)
PY
cat > tests/test_pricing.py <<'PY'
import pytest
from app.pricing import price_with_tax

def test_basic_tax():
    assert price_with_tax(100) == 112.0

def test_discount_applied_before_tax():
    assert price_with_tax(100, discount=10) == 100.8

def test_custom_rate():
    assert price_with_tax(200, rate=0.5) == 300.0

def test_negative_amount_rejected():
    with pytest.raises(ValueError):
        price_with_tax(-1)
PY

# --- 3. Conocimiento del proyecto (solo estado C) ---
if [ "${STATE}" = "C" ]; then
  cat > PROJECT_CONTEXT.md <<'MD'
# Project Context — sandbox
Proyecto de prueba. Stack: Python 3.12, FastAPI, PostgreSQL 16.
Cola de mensajes: RabbitMQ 3.13.
Restricción: no se permite Redis en producción.
MD
  cat > ARCHITECTURE.md <<'MD'
# Architecture — sandbox
API REST (FastAPI) que publica eventos de pedidos en una cola.
Un worker de colas consume esos eventos y calcula precios con app/pricing.py.
MD
fi

printf 'estado=%s\nhooks=%s\ncreado_por=tests/sandbox/setup_sandbox.sh\n' "${STATE}" "${HOOKS}" > .sea-sandbox
git add -A
git commit -q -m "base: agente instalado (estado ${STATE})"

# --- 4. Remoto local para TEST-13 ---
git init -q --bare -b main "${REMOTE}"
git remote add origin "${REMOTE}"
git push -q -u origin main

cat <<TXT

Sandbox listo: ${DEST_ABS}  (estado ${STATE}, hooks=${HOOKS})
Remoto local:  ${REMOTE}

Siguientes pasos (tests/GUIA_BENCHMARK.md):
  1. cd "${DEST_ABS}" && claude     (aprueba el @import la primera vez)
  2. Una sesión nueva por prueba y repetición; registra cada una con
     tests/results/_TEMPLATE.md del repositorio de la especificación.
  3. Entre pruebas, dentro del sandbox:  git checkout -- . && git clean -fd
  4. Para cambiar de estado, vuelve a ejecutar este script con A, B o C
     (recrea el sandbox desde cero).
TXT
