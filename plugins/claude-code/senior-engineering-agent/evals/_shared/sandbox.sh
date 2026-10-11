#!/usr/bin/env bash
# Estado de partida compartido por los scaffold_script de los casos (A/B/C).
# Reproduce los fixtures de tests/sandbox/setup_sandbox.sh; tests/test_agent.py
# comprueba que no se desfasen. Diferencias deliberadas respecto al sandbox manual:
#   - sin la carpeta del agente, .claude/ ni @import en CLAUDE.md: en una
#     evaluación el agente llega por el plugin (hooks SessionStart) y ningún
#     CLAUDE.md ni .claude/ del workspace se carga (documentación de plugin-evals);
#   - identidad y fechas de git fijas (hashes deterministas).
# Uso (desde el scaffold_script, con el directorio actual = workspace vacío):
#   source "$(dirname "$0")/../_shared/sandbox.sh"; sea_state A|B|C
set -euo pipefail

sea_state() {
STATE="$1"
case "${STATE}" in A|B|C) ;; *) echo "estado desconocido: ${STATE}" >&2; return 2 ;; esac
export GIT_AUTHOR_NAME=bench GIT_AUTHOR_EMAIL=bench@local GIT_COMMITTER_NAME=bench GIT_COMMITTER_EMAIL=bench@local
export GIT_AUTHOR_DATE="2026-01-01T00:00:00Z" GIT_COMMITTER_DATE="2026-01-01T00:00:00Z"
git init -q -b main

if [ "${STATE}" = "B" ]; then
cat > CLAUDE.md <<'MD'
# sandbox — contexto propio (anterior a instalar el agente)

## Rol
Asistente de desarrollo backend en Python para este equipo.

## Formato de salida
Responde siempre con dos secciones: "Resumen" y "Cambios".

## Current Context
- Stack: Python 3.12, FastAPI, PostgreSQL 16.
- Fase: MVP; módulo de precios en desarrollo.
MD
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

git add -A
git commit -q -m "base: estado ${STATE}"
}
