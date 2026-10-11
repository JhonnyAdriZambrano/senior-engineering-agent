#!/usr/bin/env python3
"""
Genera el plugin de Claude Code en plugins/claude-code/senior-engineering-agent/
como VISTA DERIVADA de la fuente única (core/, adapters/, project-knowledge-
templates/ y manifest.yaml). Mismo patrón que generate_skills.py: con --check
no escribe nada y sale con 1 si hay deriva.

Qué genera (documentación oficial: code.claude.com/docs/en/plugins-reference):
  .claude-plugin/plugin.json   name, version (manifest.yaml), description, author,
                               license, repository
  skills/                      copia de adapters/skills/
  agents/                      copia de adapters/claude-code/agents/
  core/                        copia de manifest.yaml > core_modules (sin compact.md)
  adapters/hooks/sea_hooks.py  y project-knowledge-templates/ con la MISMA ruta
                               relativa: sea_hooks.py localiza las plantillas tres
                               niveles por encima de sí mismo
  LICENSE                      copia de la licencia (CC BY-NC 4.0)
  scripts/sea-python.sh        lanzador del intérprete de Python (python3, python,
                               py -3); si ninguno funciona, avisa y sale con 0
  hooks/hooks.json             un hook SessionStart POR ARCHIVO del núcleo (cat +
                               cabecera de parte) y los hooks de sea_hooks.py

NO genera ni borra evals/ (casos de `claude plugin eval`, escritos a mano y
versionados dentro del plugin) ni evals/results/ (no se versiona).

Los hooks de un mismo evento y matcher corren en paralelo; la documentación no
garantiza su orden. Por eso cada parte del núcleo lleva una cabecera con su
número y el orden canónico (00→05).

Uso: python3 scripts/generate_plugin.py [--check]
"""
import json
import os
import sys

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN_DIR = os.path.join(ROOT, "plugins", "claude-code", "senior-engineering-agent")
UNMANAGED = ("evals",)  # carpeta de primer nivel que el generador no toca

AUTHOR = {"name": "Jhonny Adrian Zambrano Gonzalez"}  # README.md, «Autoría»
LICENSE_ID = "CC-BY-NC-4.0"  # identificador SPDX de LICENSE (raíz del repo)
REPOSITORY = "https://github.com/JhonnyAdriZambrano/senior-engineering-agent"
SESSION_MATCHERS = ("startup", "clear", "compact")
HEADER = "[Núcleo SEA — parte {n} de {total} (orden canónico 00→05): {file}]"

LAUNCHER = r'''#!/usr/bin/env bash
# Lanzador del intérprete de Python para los hooks del plugin (GENERADO por
# scripts/generate_plugin.py; no lo edites a mano).
#
# Uso: sea-python.sh <script.py> [args...]
#
# En Windows con Git Bash, `python3` puede ser un alias de la Microsoft Store que
# no ejecuta nada; allí suele funcionar `py -3`. Se prueba, en orden, python3,
# python y `py -3`, y se elige el primero que de verdad ejecuta (`-c "import sys"`).
# stdin (el JSON del hook) pasa intacto al script.
#
# Garantía: SIEMPRE sale con 0. Un hook que falla no debe romper la sesión; si
# ningún intérprete funciona, o el script falla, solo avisa.

warn() {
  # SessionStart: el stdout llega como contexto, así que el aviso se ve en la sesión.
  if [ "$2" = "session-start" ]; then
    echo "[Senior Engineering Agent] $1"
  fi
  echo "[Senior Engineering Agent] $1" >&2
}

try() { "$@" -c "import sys" >/dev/null 2>&1; }

if try python3; then
  python3 "$@"
elif try python; then
  python "$@"
elif try py -3; then
  py -3 "$@"
else
  warn "No se encontró un intérprete de Python funcional (probados: python3, python, py -3); el hook no se ejecutó. Instala Python 3.8+." "$2"
fi
exit 0
'''


def load_manifest():
    with open(os.path.join(ROOT, "manifest.yaml"), encoding="utf-8") as f:
        return yaml.safe_load(f)


def read_bytes(rel):
    with open(os.path.join(ROOT, rel), "rb") as f:
        return f.read()


def tree_files(rel_dir):
    """Archivos de una carpeta del repo (ruta relativa a la raíz), sin cachés."""
    out = []
    base = os.path.join(ROOT, rel_dir)
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames[:] = [d for d in dirnames if d != "__pycache__"]
        for fn in filenames:
            if not fn.endswith(".pyc"):
                out.append(os.path.relpath(os.path.join(dirpath, fn), ROOT).replace(os.sep, "/"))
    return sorted(out)


def plugin_json(manifest):
    agent = manifest["agent"]
    return {
        "name": agent["id"],
        "version": agent["version"],
        "description": " ".join(str(agent["description"]).split()),
        "author": AUTHOR,
        "license": LICENSE_ID,
        "repository": REPOSITORY,
    }


def core_command(n, total, core_path):
    header = HEADER.format(n=n, total=total, file=core_path)
    assert "'" not in header
    return f"printf '%s\\n' '{header}' && cat \"${{CLAUDE_PLUGIN_ROOT}}\"/{core_path}"


def py_command(sub, runtime="claude-code"):
    return (
        'bash "${CLAUDE_PLUGIN_ROOT}"/scripts/sea-python.sh '
        '"${CLAUDE_PLUGIN_ROOT}"/adapters/hooks/sea_hooks.py '
        f"{sub} --runtime {runtime}"
    )


def hooks_json(manifest):
    core = manifest["core_modules"]
    total = len(core)
    start_hooks = [{"type": "command", "command": core_command(i, total, p)} for i, p in enumerate(core, 1)]
    start_hooks.append({"type": "command", "command": py_command("session-start")})
    return {
        "description": "Senior Engineering Agent: núcleo por SessionStart (un hook por archivo de core/), "
                       "conocimiento del proyecto, NN-08 en Bash y validación al terminar",
        "hooks": {
            "SessionStart": [{"matcher": m, "hooks": start_hooks} for m in SESSION_MATCHERS],
            "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": py_command("pre-tool")}]}],
            "Stop": [{"hooks": [{"type": "command", "command": py_command("stop")}]}],
        },
    }


def dump_json(obj):
    return (json.dumps(obj, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def expected_files():
    """{ruta relativa al plugin: bytes} de todo lo que el generador es dueño."""
    manifest = load_manifest()
    files = {}
    files[".claude-plugin/plugin.json"] = dump_json(plugin_json(manifest))
    files["hooks/hooks.json"] = dump_json(hooks_json(manifest))
    files["scripts/sea-python.sh"] = LAUNCHER.encode("utf-8")
    for src in tree_files("adapters/skills"):
        files["skills/" + src[len("adapters/skills/"):]] = read_bytes(src)
    for src in tree_files("adapters/claude-code/agents"):
        files["agents/" + src[len("adapters/claude-code/agents/"):]] = read_bytes(src)
    for core_path in manifest["core_modules"]:
        files[core_path] = read_bytes(core_path)
    files["LICENSE"] = read_bytes("LICENSE")  # CC BY-NC exige que la licencia acompañe a la copia
    files["adapters/hooks/sea_hooks.py"] = read_bytes("adapters/hooks/sea_hooks.py")
    for src in tree_files("project-knowledge-templates"):
        files[src] = read_bytes(src)
    return files


def existing_files():
    out = {}
    if not os.path.isdir(PLUGIN_DIR):
        return out
    for dirpath, dirnames, filenames in os.walk(PLUGIN_DIR):
        for fn in filenames:
            rel = os.path.relpath(os.path.join(dirpath, fn), PLUGIN_DIR).replace(os.sep, "/")
            if rel.split("/", 1)[0] in UNMANAGED or "__pycache__" in rel.split("/") or rel.endswith(".pyc"):
                continue
            out[rel] = None
    return out


def main():
    check = "--check" in sys.argv
    expected = expected_files()
    present = existing_files()
    drift = 0
    for rel, content in sorted(expected.items()):
        path = os.path.join(PLUGIN_DIR, rel)
        shown = os.path.relpath(path, ROOT)
        current = open(path, "rb").read() if os.path.isfile(path) else None
        if current == content:
            print(f"Al día:         {shown}")
            continue
        drift += 1
        if check:
            print(f"DESINCRONIZADO: {shown}")
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(content)
        if rel.endswith(".sh"):
            os.chmod(path, 0o755)
        print(f"Regenerado:     {shown}")
    for rel in sorted(set(present) - set(expected)):
        drift += 1
        path = os.path.join(PLUGIN_DIR, rel)
        shown = os.path.relpath(path, ROOT)
        if check:
            print(f"SOBRANTE:       {shown}")
            continue
        os.remove(path)
        print(f"Eliminado:      {shown}")
    if not check:  # limpia carpetas vacías (salvo las no gestionadas)
        for dirpath, _, _ in sorted(os.walk(PLUGIN_DIR), reverse=True):
            if dirpath != PLUGIN_DIR and not os.listdir(dirpath):
                os.rmdir(dirpath)
    if check and drift:
        sys.exit(1)


if __name__ == "__main__":
    main()
