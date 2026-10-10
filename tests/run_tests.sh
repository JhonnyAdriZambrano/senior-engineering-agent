#!/usr/bin/env bash
# Punto de entrada único para la suite de validación estructural.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
python3 tests/test_agent.py
