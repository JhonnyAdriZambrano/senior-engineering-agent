#!/usr/bin/env python3
"""Herramientas que scripts/eval.sh concede a una corrida de `claude plugin eval` y casos que esa concesión invalidaría.

Uso: eval_grants.py <carpeta evals/> [--case GLOB] [--tag TAG]... [--exclude CASO]...

`--allow-tools` vale para TODOS los casos de una corrida, así que se concede la unión de las herramientas no de solo lectura que
declaran los casos seleccionados (por etiqueta, como `claude plugin eval --tag`, y por `--case`). Un caso con la etiqueta
`strict-tools` declara a propósito un conjunto cerrado (p. ej. cap-certeza-sin-ejecutar: sin Bash); si la unión le daría una
herramienta que no declara, la medición no sería válida (auditoría M6, 1.2.3) y el caso se lista en `strict_conflicts`.

Salida: JSON {"cases": [...], "grants": [...], "strict_conflicts": [...]}.
"""
import argparse
import fnmatch
import glob
import json
import os
import re
import sys

READ_ONLY = {"Read", "Glob", "Grep", "NotebookRead", "Skill", "AskUserQuestion", "Agent", "Task", "TodoWrite", "TaskCreate", "TaskGet",
             "TaskList", "TaskUpdate", "TaskStop"}


def _list(text, key):
    m = re.search(rf"^{key}:\s*\[(.*?)\]", text, re.M)
    return [t.strip().strip("\"'") for t in m.group(1).split(",") if t.strip()] if m else []


def analyze(evals_dir, case_glob="", tags=(), exclude=()):
    cases = {}
    for p in sorted(glob.glob(os.path.join(evals_dir, "*", "prompt.md"))):
        name = os.path.basename(os.path.dirname(p))
        if case_glob and not fnmatch.fnmatchcase(name, case_glob):
            continue
        if name in exclude:
            continue
        text = open(p, encoding="utf-8").read()
        case_tags = _list(text, "tags")
        if tags and not set(tags) & set(case_tags):
            continue
        cases[name] = {"tools": set(_list(text, "allowed_tools")) - READ_ONLY, "strict": "strict-tools" in case_tags}
    grants = set().union(*(c["tools"] for c in cases.values())) if cases else set()
    conflicts = sorted(n for n, c in cases.items() if c["strict"] and grants - c["tools"])
    return {"cases": sorted(cases), "grants": sorted(grants), "strict_conflicts": conflicts}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("evals_dir")
    ap.add_argument("--case", default="")
    ap.add_argument("--tag", action="append", default=[])
    ap.add_argument("--exclude", action="append", default=[])
    a = ap.parse_args()
    print(json.dumps(analyze(a.evals_dir, a.case, a.tag, a.exclude)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
