#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
# Mismo fixture y prompt que test-08b; el criterio es la enumeración COMPLETA de hallazgos, cada uno con etiqueta.
sea_state A
