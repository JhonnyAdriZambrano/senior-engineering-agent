#!/usr/bin/env python3
"""
Genera el plugin de Claude Code en plugins/claude-code/senior-engineering-agent/
como VISTA DERIVADA de la fuente única (core/, adapters/, project-knowledge-
templates/ y manifest.yaml). Mismo patrón que generate_skills.py: con --check
no escribe nada y sale con 1 si hay deriva.

Qué genera (documentación oficial: code.claude.com/docs/en/plugins-reference):
  .claude-plugin/plugin.json   name, displayName y homepage (manifest.yaml), version,
                               description (inglés y después español), author, license,
                               repository, keywords, icon, privacyPolicyUrl, supportUrl y
                               userConfig.language (selector es|en)
  icon.png                     icono del plugin, en la raíz del plugin (plugin.json > icon = "./icon.png")
  README.md                    portada del plugin (plantilla PLUGIN_README de este script)
  skills/                      copia de adapters/skills/
  agents/                      copia de adapters/claude-code/agents/
  core/                        copia de manifest.yaml > core_modules (sin compact.md)
  adapters/hooks/sea_hooks.py  y project-knowledge-templates/ con la MISMA ruta
                               relativa: sea_hooks.py localiza las plantillas tres
                               niveles por encima de sí mismo
  LICENSE, NOTICE              copia de la licencia (Apache-2.0, desde 1.2.1) y del aviso
  scripts/sea-python.sh        lanzador del intérprete de Python (python3, python,
                               py -3); si ninguno funciona, avisa y sale con 0
  hooks/hooks.json             un hook SessionStart POR ARCHIVO del núcleo (cat +
                               cabecera de parte) y los hooks de sea_hooks.py
  adapters/hooks/i18n.json     idiomas, rol en inglés y tabla de etiquetas es→en
                               (manifest.yaml > i18n); sea_hooks.py lo lee junto a sí
                               mismo. También se escribe en el repositorio
                               (adapters/hooks/i18n.json) para los demás runtimes.

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
LICENSE_ID = "Apache-2.0"  # identificador SPDX de LICENSE (raíz del repo)
REPOSITORY = "https://github.com/JhonnyAdriZambrano/senior-engineering-agent"
# Etiquetas de descubrimiento (plugin.json > keywords). Las cuatro primeras son los tags de la entrada de .claude-plugin/marketplace.json.
KEYWORDS = ["engineering", "code-review", "architecture", "security", "claude-code", "hooks", "skills", "subagents"]
ICON = "./icon.png"  # ruta dentro del plugin, con «./» (manifest-reference, «Directory listing fields»)
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
# ningún intérprete funciona, o el script falla, solo avisa. Excepción (fail-closed
# de NN-08, 1.2.3): en pre-tool sin intérprete no se puede analizar el comando, así
# que se pide confirmación ("ask") en vez de dejarlo pasar en silencio.

warn() {
  # SessionStart: el stdout llega como contexto, así que el aviso se ve en la sesión.
  if [ "$2" = "session-start" ]; then
    echo "[Senior Engineering Agent] $1"
  fi
  if [ "$2" = "pre-tool" ]; then
    # JSON en ASCII puro (\uXXXX); idioma con la misma precedencia que sea_hooks.py.
    if [ "${CLAUDE_PLUGIN_OPTION_LANGUAGE:-${SEA_LANGUAGE:-es}}" = "en" ]; then
      reason='NN-08: the command could not be parsed (no working Python interpreter); review it before authorizing'
    else
      reason='NN-08: no se pudo analizar el comando (no hay un int\u00e9rprete de Python funcional); rev\u00edsalo antes de autorizar'
    fi
    printf '{"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask", "permissionDecisionReason": "%s"}}\n' "${reason}"
  fi
  echo "[Senior Engineering Agent] $1" >&2
}

try() { "$@" -c "import sys" >/dev/null 2>&1; }

# Codificación (H-E7b-1/2): en Windows, Python usa cp1252 en las tuberías, pero Claude Code
# envía y lee UTF-8. Se fuerza UTF-8 antes de invocar al intérprete.
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

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


def i18n_json(manifest):
    """Contenido de adapters/hooks/i18n.json: lo que sea_hooks.py necesita de manifest.yaml > i18n."""
    i18n = manifest["i18n"]
    return {
        "default_language": i18n["default_language"],
        "languages": list(i18n["languages"]),
        "role": dict(i18n["role"]),
        "labels_en": dict(i18n["labels_en"]),
    }


def plugin_json(manifest):
    agent = manifest["agent"]
    i18n = manifest["i18n"]
    return {
        "name": agent["id"],
        "displayName": agent["name"],  # https://code.claude.com/docs/en/plugins/manifest-reference (campo displayName)
        "version": agent["version"],
        # Catálogo bilingüe: primero inglés y después español.
        "description": " ".join(str(i18n["description_en"]).split()) + " / " + " ".join(str(agent["description"]).split()),
        "author": AUTHOR,
        "homepage": agent["homepage"],  # URL de documentación; debe parsear como URL o el plugin no carga
        "license": LICENSE_ID,
        "repository": REPOSITORY,
        "keywords": list(KEYWORDS),
        "icon": ICON,
        "privacyPolicyUrl": agent["homepage"] + "/blob/main/PRIVACY.md",
        "supportUrl": agent["homepage"] + "/issues",
        "userConfig": {
            "language": {
                "type": "string",
                "title": "Language / Idioma",
                "description": "Language of the agent's replies and hook messages (es = Español, en = English). "
                               "Idioma de las respuestas del agente y de los mensajes de los hooks. Requires Claude Code v2.1.271+.",
                "options": list(i18n["languages"]),
                "default": i18n["default_language"],
            }
        },
    }


PLUGIN_README = """# {name}

> Senior Software Engineer and Senior Information Technology Architect for Claude Code. Version {version}.

**What it is.** A Claude Code plugin that loads a senior-engineering core (identity, non-negotiable rules, certainty
labels, task workflows) at session start, plus 7 Skills, 2 read-only subagents and deterministic hooks. It works on
real repositories with evidence, security, minimal change and explicit epistemic honesty.

**Qué es (español).** Plugin de Claude Code que carga al iniciar la sesión un núcleo de ingeniería senior (identidad,
reglas no negociables, etiquetas de certeza y workflows), con 7 Skills, 2 subagentes de solo lectura y hooks
deterministas. El núcleo normativo está en español; el selector de idioma permite respuestas en inglés.

## Install

```bash
claude plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
claude plugin install {id}@{id}
```

## Language selector (es / en)

Open `/config` and pick `es` (default) or `en` under this plugin's `language` option, then start a new session.
In `en` mode the agent answers in English and uses English labels; the normative core stays in Spanish.

## Requirements

- Claude Code **v2.1.271 or later** (the plugin declares `userConfig.options`; older versions cannot load it).
- Python 3.8+ (the hooks run `scripts/sea-python.sh`).
- On Windows: **Git Bash** (the hook launcher is a bash script).

## Deterministic guarantees

Hooks are code that runs regardless of what the model decides:

- **NN-08** — asks for human confirmation before destructive shell commands (`Bash` and `PowerShell` tools); fail-closed.
- **NN-06b** — reports lines in `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` / `DECISIONS.md` that look like orders to the agent
  (those files are data, not instructions).
- **Stop** — if the turn edited code without evidence of validation, blocks once and asks to validate or say why not
  (documentation-only edits are exempt).

## More

- Repository, full documentation and specification: {homepage}
- Measured results and their limitations: {measurements}
- License: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) from 1.2.1 (see the `LICENSE` and `NOTICE` files in this folder). Versions up to and including 1.2.0 were released under CC BY-NC 4.0.
"""


def plugin_readme(manifest):
    agent = manifest["agent"]
    return PLUGIN_README.format(
        name=agent["name"], version=agent["version"], id=agent["id"], homepage=agent["homepage"],
        measurements=agent["homepage"] + "/blob/main/docs/MEASUREMENTS.md",
    )


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
                       "conocimiento del proyecto, NN-08 en Bash y PowerShell, y validación al terminar",
        "hooks": {
            "SessionStart": [{"matcher": m, "hooks": start_hooks} for m in SESSION_MATCHERS],
            "PreToolUse": [{"matcher": "Bash|PowerShell", "hooks": [{"type": "command", "command": py_command("pre-tool")}]}],
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
    files["icon.png"] = read_bytes("adapters/claude-code/icon.png")  # icono del plugin (directorio de plugins)
    for src in tree_files("adapters/skills"):
        files["skills/" + src[len("adapters/skills/"):]] = read_bytes(src)
    for src in tree_files("adapters/claude-code/agents"):
        files["agents/" + src[len("adapters/claude-code/agents/"):]] = read_bytes(src)
    for core_path in manifest["core_modules"]:
        files[core_path] = read_bytes(core_path)
    files["README.md"] = plugin_readme(manifest).encode("utf-8")
    files["LICENSE"] = read_bytes("LICENSE")  # Apache-2.0 exige entregar la licencia con toda redistribución
    files["NOTICE"] = read_bytes("NOTICE")  # y conservar el NOTICE (Apache-2.0, sección 4.d)
    files["adapters/hooks/sea_hooks.py"] = read_bytes("adapters/hooks/sea_hooks.py")
    files["adapters/hooks/i18n.json"] = dump_json(i18n_json(manifest))
    for src in tree_files("project-knowledge-templates"):
        files[src] = read_bytes(src)
    return files


REPO_DERIVED = ("adapters/hooks/i18n.json",)  # vistas derivadas que viven en el repositorio (no en el plugin)


def expected_repo_files():
    return {"adapters/hooks/i18n.json": dump_json(i18n_json(load_manifest()))}


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
    for rel, content in sorted(expected_repo_files().items()):
        path = os.path.join(ROOT, rel)
        current = open(path, "rb").read() if os.path.isfile(path) else None
        if current == content:
            print(f"Al día:         {rel}")
            continue
        drift += 1
        if check:
            print(f"DESINCRONIZADO: {rel}")
            continue
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as f:
            f.write(content)
        print(f"Regenerado:     {rel}")
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
