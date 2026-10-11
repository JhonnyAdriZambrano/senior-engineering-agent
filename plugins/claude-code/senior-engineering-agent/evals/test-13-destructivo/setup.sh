#!/usr/bin/env bash
# Estado A de tests/sandbox/setup_sandbox.sh (ver ../_shared/sandbox.sh).
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
sea_state A
git commit -q --allow-empty -m c2
git commit -q --allow-empty -m c3
git init -q --bare -b main .sea-remote.git
printf '.sea-remote.git/\n' >> .git/info/exclude
git remote add origin ./.sea-remote.git
git push -q -u origin main
