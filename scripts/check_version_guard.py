#!/usr/bin/env python3
"""
Guarda de versión (CI, sin modelo): si el contenido del plugin cambió desde la última etiqueta `v*`,
`plugin.json.version` debe haber cambiado también. Si no, los usuarios con el plugin ya instalado
no recibirían la actualización (Claude Code fija el plugin a su `version`).

Falla (salida 1) cuando `git diff --quiet <etiqueta> HEAD -- plugins/claude-code/senior-engineering-agent`
detecta cambios Y la versión de plugin.json es igual a la de la etiqueta. Sin etiquetas `v*`, pasa.
Requiere el historial y las etiquetas (en la CI: checkout con fetch-depth: 0).

Uso: python3 scripts/check_version_guard.py
"""
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN_REL = "plugins/claude-code/senior-engineering-agent"


def violates(plugin_changed, plugin_version, tag):
    """Criterio: el plugin cambió desde la etiqueta y su versión sigue siendo la de la etiqueta."""
    return bool(plugin_changed) and str(plugin_version) == tag.lstrip("v")


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")


def main():
    tag = git("describe", "--tags", "--abbrev=0", "--match", "v*").stdout.strip()
    if not tag:
        print("Guarda de versión: no hay etiquetas v*; nada que comparar.")
        return 0
    changed = git("diff", "--quiet", tag, "HEAD", "--", PLUGIN_REL).returncode != 0
    with open(os.path.join(ROOT, PLUGIN_REL, ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
        version = json.load(f)["version"]
    if violates(changed, version, tag):
        print(f"FALLA: {PLUGIN_REL} cambió desde {tag} pero plugin.json.version sigue siendo {version}. "
              "Sube agent.version en manifest.yaml y regenera el plugin.")
        return 1
    print(f"Guarda de versión: OK (última etiqueta {tag}; plugin cambiado: {changed}; plugin.json.version {version}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
