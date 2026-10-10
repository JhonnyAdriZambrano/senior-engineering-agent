#!/usr/bin/env python3
"""
Propaga el núcleo compacto (core/compact.md) a los adaptadores que NO pueden
hacer @import: Codex (AGENTS.md), Cursor (00-core-always.mdc) y ChatGPT/Gems.

Fuente única: el bloque entre <!-- BEGIN:compact --> y <!-- END:compact -->
de core/compact.md. Cada adaptador contiene ese mismo par de marcadores; este
script reemplaza lo que hay entre ellos. Si editas core/, actualiza
core/compact.md y ejecuta este script (tests/test_agent.py falla si no).

Uso:
  python3 scripts/generate_compact.py          # escribe los adaptadores
  python3 scripts/generate_compact.py --check  # no escribe; exit 1 si hay deriva
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BEGIN = "<!-- BEGIN:compact -->"
END = "<!-- END:compact -->"
SOURCE = "core/compact.md"
TARGETS = [
    "adapters/codex/AGENTS.md",
    "adapters/cursor/rules/00-core-always.mdc",
    "adapters/chatgpt-and-gems/instructions.md",
]
_REGION = re.compile(re.escape(BEGIN) + r"(.*?)" + re.escape(END), re.S)


def region(text):
    m = _REGION.search(text)
    if not m or len(_REGION.findall(text)) != 1:
        raise SystemExit("Se esperaba exactamente un par BEGIN/END:compact")
    return m.group(1)


def main():
    check = "--check" in sys.argv
    with open(os.path.join(ROOT, SOURCE), encoding="utf-8") as f:
        block = region(f.read())
    drift = 0
    for rel in TARGETS:
        path = os.path.join(ROOT, rel)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        try:
            current = region(text)
        except SystemExit as e:
            raise SystemExit(f"{rel}: {e}")
        if current == block:
            print(f"Al día:      {rel}")
            continue
        drift += 1
        if check:
            print(f"DESINCRONIZADO: {rel}")
            continue
        new = _REGION.sub(lambda _m: BEGIN + block + END, text, count=1)
        with open(path, "w", encoding="utf-8") as f:
            f.write(new)
        print(f"Regenerado:  {rel}")
    if check and drift:
        sys.exit(1)


if __name__ == "__main__":
    main()
