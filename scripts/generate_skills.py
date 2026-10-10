#!/usr/bin/env python3
"""
Regenera las Skills (formato abierto Agent Skills, SKILL.md) a partir de
modules/*.md, en un único directorio compartido: adapters/skills/.

Ese mismo juego de Skills se instala en:
  - Claude Code  -> .claude/skills/<nombre>/SKILL.md
  - Codex, Cursor y Gemini CLI -> .agents/skills/<nombre>/SKILL.md
(rutas de descubrimiento confirmadas en la documentación oficial de cada
runtime; ver SPECIFICATION.md §7).

Fuentes de verdad (nada se escribe a mano en este script):
  - Lista de módulos: manifest.yaml > conditional_modules (id -> nombre).
  - Descripción: línea «Descripción de Skill:» de la cabecera del módulo.
  - Cuerpo: el módulo sin su cabecera (título + párrafo de activación).

Los SKILL.md son una vista derivada, no una segunda fuente de verdad: si
editas un módulo, corre este script (tests/test_agent.py sección 7 detecta
la deriva). Con --check no escribe nada y sale con 1 si hay deriva.

Uso: python3 scripts/generate_skills.py [--check]
"""
import os
import re
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "adapters", "skills")

# Nota que se antepone al cuerpo: una Skill instalada vive en .claude/skills/
# o .agents/skills/, lejos del paquete, y el módulo cita rutas del paquete.
PATH_NOTE = (
    "> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): "
    "relativas a la carpeta `senior-engineering-agent/` instalada en la raíz "
    "del proyecto.\n\n"
)

DESC_RE = re.compile(r"^Descripción de Skill: (.+)$", re.M)


def strip_module_header(text):
    """Quita el primer párrafo (título, descripción y 'Activar cuando')."""
    lines = text.split("\n")
    idx = 1
    while idx < len(lines) and lines[idx].strip() != "":
        idx += 1
    return "\n".join(lines[idx:]).lstrip("\n")


def module_description(text, path):
    m = DESC_RE.search(text.split("\n\n", 1)[0])
    if not m:
        raise SystemExit(f"{path}: falta la línea 'Descripción de Skill:' en la cabecera")
    return m.group(1).strip()


def render(mod):
    with open(os.path.join(ROOT, mod["path"]), encoding="utf-8") as f:
        text = f.read()
    desc = module_description(text, mod["path"])
    frontmatter = yaml.safe_dump(
        {"name": mod["id"], "description": desc},
        allow_unicode=True, sort_keys=False, width=100000,
    )
    return f"---\n{frontmatter}---\n\n" + PATH_NOTE + strip_module_header(text)


def main():
    check = "--check" in sys.argv
    with open(os.path.join(ROOT, "manifest.yaml"), encoding="utf-8") as f:
        manifest = yaml.safe_load(f)
    drift = 0
    for mod in manifest["conditional_modules"]:
        out_path = os.path.join(OUT_DIR, mod["id"], "SKILL.md")
        content = render(mod)
        current = open(out_path, encoding="utf-8").read() if os.path.exists(out_path) else None
        rel = os.path.relpath(out_path, ROOT)
        if current == content:
            print(f"Al día:         {rel}")
            continue
        drift += 1
        if check:
            print(f"DESINCRONIZADO: {rel}")
            continue
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "w", encoding="utf-8", newline="") as f:
            f.write(content)
        print(f"Regenerado:     {rel}")
    if check and drift:
        sys.exit(1)


if __name__ == "__main__":
    main()
