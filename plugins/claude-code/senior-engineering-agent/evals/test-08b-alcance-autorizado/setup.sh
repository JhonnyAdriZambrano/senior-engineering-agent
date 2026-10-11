#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
# Estado A (fixture de TEST-08). El prompt ya autoriza ampliar a main.py: la tarea termina.
sea_state A
