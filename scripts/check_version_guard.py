#!/usr/bin/env python3
"""
Guarda de versión (CI, sin modelo): si el contenido del plugin cambió desde la última etiqueta `v*`,
`plugin.json.version` debe haber SUBIDO respecto de la etiqueta. Si no, los usuarios con el plugin ya
instalado no recibirían la actualización (Claude Code fija el plugin a su `version`).

Falla (salida 1) cuando:
  - `plugin.json.version` o `manifest.yaml > agent.version` no tienen la forma X.Y.Z, o no coinciden;
  - la versión es MENOR que la de la última etiqueta (regresión), o el plugin cambió desde la etiqueta
    (`git diff --quiet <etiqueta> HEAD -- plugins/claude-code/senior-engineering-agent`) y la versión no es mayor;
  - HEAD lleva una etiqueta `v*` que no coincide con la versión (en ese caso se compara además con la etiqueta anterior);
  - git falla (sin repositorio, historial incompleto…): un error de git no se confunde con «no hay etiquetas».
Sin etiquetas `v*`, solo comprueba el formato y la coincidencia. Requiere el historial y las etiquetas (en la CI:
checkout con fetch-depth: 0). Endurecida en 1.2.3 (auditoría M7).

Uso: python3 scripts/check_version_guard.py
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLUGIN_REL = "plugins/claude-code/senior-engineering-agent"
SEMVER = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def parse(version):
    m = SEMVER.match(str(version).lstrip("v"))
    return tuple(int(x) for x in m.groups()) if m else None


def violates(plugin_changed, plugin_version, tag):
    """Criterio: la versión es menor que la de la etiqueta, o el plugin cambió desde la etiqueta y la versión no es mayor."""
    v, t = parse(plugin_version), parse(tag)
    if v is None or t is None:
        return True
    return v < t or (bool(plugin_changed) and v <= t)


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")


class GitError(Exception):
    pass


def git_ok(*args):
    r = git(*args)
    if r.returncode != 0:
        raise GitError(f"git {' '.join(args)} -> {r.returncode}: {r.stderr.strip()[:200]}")
    return r.stdout.strip()


def last_tag(rev):
    """Última etiqueta v* alcanzable desde `rev`, o "" si no hay ninguna (git describe falla en ese caso; se distingue con git tag)."""
    r = git("describe", "--tags", "--abbrev=0", "--match", "v*", rev)
    if r.returncode == 0:
        return r.stdout.strip()
    if not git_ok("tag", "--list", "v*", "--merged", rev):
        return ""
    raise GitError(f"git describe {rev} -> {r.returncode}: {r.stderr.strip()[:200]}")


def manifest_version():
    for line in open(os.path.join(ROOT, "manifest.yaml"), encoding="utf-8"):
        m = re.match(r'^  version:\s*"([^"]+)"', line)
        if m:
            return m.group(1)
    return None


def main():
    with open(os.path.join(ROOT, PLUGIN_REL, ".claude-plugin", "plugin.json"), encoding="utf-8") as f:
        version = json.load(f)["version"]
    mversion = manifest_version()
    if parse(version) is None or version != mversion:
        print(f"FALLA: plugin.json.version ({version}) y manifest.yaml agent.version ({mversion}) deben ser X.Y.Z e iguales. "
              "Regenera con scripts/generate_plugin.py.")
        return 1
    try:
        git_ok("rev-parse", "--is-inside-work-tree")
        tag = last_tag("HEAD")
        if not tag:
            print(f"Guarda de versión: no hay etiquetas v*; versión {version} con formato válido.")
            return 0
        if git_ok("rev-list", "-n", "1", tag) == git_ok("rev-parse", "HEAD"):  # commit de release ya etiquetado
            if tag.lstrip("v") != version:
                print(f"FALLA: HEAD lleva la etiqueta {tag} pero plugin.json.version es {version}.")
                return 1
            has_parent = git("rev-parse", "--verify", "--quiet", "HEAD^").returncode == 0
            tag = last_tag("HEAD^") if has_parent else ""
            if not tag:
                print(f"Guarda de versión: OK (HEAD = {version}, sin etiqueta anterior).")
                return 0
        changed = git("diff", "--quiet", tag, "HEAD", "--", PLUGIN_REL).returncode
        if changed not in (0, 1):
            raise GitError(f"git diff {tag} HEAD -> {changed}")
    except GitError as e:
        print(f"FALLA: error de git ({e}). La guarda necesita el repositorio con historial y etiquetas (fetch-depth: 0).")
        return 1
    if violates(changed == 1, version, tag):
        why = "es menor que la etiqueta" if parse(version) < parse(tag) else "no sube aunque el plugin cambió"
        print(f"FALLA: plugin.json.version {version} {why} ({tag}). Sube agent.version en manifest.yaml y regenera el plugin.")
        return 1
    print(f"Guarda de versión: OK (última etiqueta {tag}; plugin cambiado: {changed == 1}; plugin.json.version {version}).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
