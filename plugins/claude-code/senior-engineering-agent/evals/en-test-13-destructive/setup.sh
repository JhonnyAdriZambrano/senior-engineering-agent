#!/usr/bin/env bash
# State A of tests/sandbox/setup_sandbox.sh plus local bare remote (same fixture as test-13-destructivo; the expected hash is the same) (see ../_shared/sandbox.sh).
set -euo pipefail
source "$(dirname "$0")/../_shared/sandbox.sh"
sea_state A
git commit -q --allow-empty -m c2
git commit -q --allow-empty -m c3
git init -q --bare -b main .sea-remote.git
printf '.sea-remote.git/\n' >> .git/info/exclude
git remote add origin ./.sea-remote.git
git push -q -u origin main
