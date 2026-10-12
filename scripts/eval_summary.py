#!/usr/bin/env python3
"""Resumen por caso de uno o varios result.json de `claude plugin eval`, SIN coste de modelo (H-E3d-5).

Por qué existe: con `--ablation none` el evaluador cuenta TODOS los graders, incluidos los indicadores `arm: with-only`
(`diag-*`, `obs-*`, `etiqueta-requerido`…), que no deben puntuar. Este script lee el frontmatter de cada grader en
`<evals>/<caso>/graders/<grader>.md`, excluye los `arm: with-only` (y los que el propio evaluador marcó `scored: false`) y
recalcula la puntuación de cada corrida como la fracción de graders puntuables aprobados.

Salida (una tabla por caso): WITH (media de las corridas), perfectas (corridas con todos los graders puntuables aprobados / corridas),
W/OUT si algún resultado trae brazo sin plugin y, con varios resultados, el Δ de cada uno frente al PRIMERO (columnas siguientes).

Uso:
  python3 scripts/eval_summary.py RESULT.json [RESULT2.json ...] [--evals DIR] [--labels A,B,...] [--merge] [--json]
    --evals DIR    carpeta de casos (defecto: plugins/claude-code/senior-engineering-agent/evals). Los graders `arm: with-only` se leen de AHÍ, es decir, del
                   estado ACTUAL de los casos: si un grader se movió, renombró o cambió de brazo después de la medición, extrae esa versión
                   (`git archive <commit> plugins/claude-code/senior-engineering-agent/evals`) y pásala con --evals.
    --labels       nombres de las columnas (defecto: nombre de la carpeta que contiene cada result.json).
    --merge        trata todos los archivos como UNA sola medición repartida en invocaciones (p. ej. una por caso, porque --case solo admite
                   `*` y `?`): une sus casos en una columna (si un caso aparece en varios, gana el último).
    --json         imprime los datos en JSON en lugar de la tabla.
Solo biblioteca estándar (Python 3.8+). Lee y escribe UTF-8 sea cual sea la codificación local (Windows).
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_EVALS = os.path.join(ROOT, "plugins", "claude-code", "senior-engineering-agent", "evals")


def _utf8_streams():
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass


def with_only_graders(evals_dir, case):
    """Nombres de los graders de `case` cuyo frontmatter declara `arm: with-only`."""
    out = set()
    gdir = os.path.join(evals_dir, case, "graders")
    if not os.path.isdir(gdir):
        return out
    for fn in os.listdir(gdir):
        if not fn.endswith(".md"):
            continue
        try:
            with open(os.path.join(gdir, fn), encoding="utf-8", errors="replace") as f:
                text = f.read()
        except OSError:
            continue
        m = re.match(r"---\r?\n(.*?)\r?\n---", text, re.S)
        if m and re.search(r"^arm:\s*[\"']?with-only[\"']?\s*$", m.group(1), re.M):
            out.add(fn[:-3])
    return out


def run_score(run, excluded):
    """(puntuación recalculada, ¿perfecta?, nº de graders puntuables). Sin graders puntuables: se usa el score del evaluador."""
    graders = [g for g in run.get("graders") or [] if g.get("scored", True) is not False and g.get("name") not in excluded]
    if not graders:
        s = run.get("score")
        return (float(s) if isinstance(s, (int, float)) else None), (isinstance(s, (int, float)) and s >= 1), 0
    passed = sum(1 for g in graders if g.get("passed"))
    return passed / len(graders), passed == len(graders), len(graders)


def summarize_result(data, evals_dir):
    """{caso: {"with": media|None, "perfect": "n/N", "without": media|None, "runs": N, "cost": usd, "excluded": [graders]}}"""
    out = {}
    for case in data.get("cases") or []:
        name = case.get("name", "?")
        excluded = with_only_graders(evals_dir, name)
        arms = case.get("arms") or {}
        entry = {"excluded": sorted(excluded), "cost": 0.0}
        for arm_key, label in (("with", "with"), ("without", "without")):
            runs = arms.get(arm_key) or []
            scored = [run_score(r, excluded) for r in runs]
            vals = [s for s, _p, _n in scored if s is not None]
            entry[label] = (sum(vals) / len(vals)) if vals else None
            if arm_key == "with":
                entry["runs"] = len(runs)
                entry["perfect"] = f"{sum(1 for _s, p, _n in scored if p)}/{len(runs)}"
            entry["cost"] += sum(float(r.get("costUsd") or 0) + float(r.get("judgeCostUsd") or 0) for r in runs)
        out[name] = entry
    return out


def load(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        return json.load(f)


def summarize(paths, evals_dir=DEFAULT_EVALS, labels=None, merge=False):
    labels = labels or [os.path.basename(os.path.dirname(os.path.abspath(p))) or os.path.basename(p) for p in paths]
    results = [summarize_result(load(p), evals_dir) for p in paths]
    if merge:
        union = {}
        for r in results:
            union.update(r)
        labels, results = [labels[0] if len(set(labels)) == 1 or len(labels) == 1 else "+".join(labels)], [union]
    cases = []
    for r in results:
        for c in r:
            if c not in cases:
                cases.append(c)
    return {"labels": labels, "cases": cases, "results": results}


def render(summary):
    labels, cases, results = summary["labels"], summary["cases"], summary["results"]
    has_without = any(e.get("without") is not None for r in results for e in r.values())
    f2 = lambda v: "-" if v is None else f"{v:.2f}"
    lines = []
    head = f'{"CASO":34}'
    for i, lab in enumerate(labels):
        head += f' {("WITH " + lab)[:18]:>18} {"PERFECTAS":>9}'
        if has_without:
            head += f' {"W/OUT":>6}'
        if i > 0:
            head += f' {"Δ vs 1º":>8}'
    lines.append(head)
    for c in cases:
        row = f"{c:34}"
        first = results[0].get(c, {}).get("with") if results else None
        for i, r in enumerate(results):
            e = r.get(c)
            if e is None:
                row += f' {"-":>18} {"-":>9}' + (f' {"-":>6}' if has_without else "") + (f' {"-":>8}' if i > 0 else "")
                continue
            row += f' {f2(e["with"]):>18} {e["perfect"]:>9}'
            if has_without:
                row += f' {f2(e.get("without")):>6}'
            if i > 0:
                d = None if (e["with"] is None or first is None) else e["with"] - first
                row += f' {("-" if d is None else f"{d:+.2f}"):>8}'
        lines.append(row)
    withs = [[e["with"] for e in r.values() if e["with"] is not None] for r in results]
    mean = lambda xs: (sum(xs) / len(xs)) if xs else None
    tot = f'{"MEDIA (WITH)":34}'
    for i, w in enumerate(withs):
        tot += f' {f2(mean(w)):>18} {"":>9}' + (f' {"":>6}' if has_without else "") + (f' {"":>8}' if i > 0 else "")
    lines.append(tot)
    for lab, r in zip(labels, results):
        lines.append(f'coste estimado {lab}: ${sum(e["cost"] for e in r.values()):.2f}')
    excl = sorted({f"{c}:{g}" for r in results for c, e in r.items() for g in e["excluded"]})
    if excl:
        lines.append("graders excluidos (arm: with-only): " + ", ".join(excl))
    return "\n".join(lines)


def main(argv=None):
    _utf8_streams()
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("results", nargs="+", help="uno o varios result.json")
    ap.add_argument("--evals", default=DEFAULT_EVALS)
    ap.add_argument("--labels", default="")
    ap.add_argument("--merge", action="store_true")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    labels = [x.strip() for x in a.labels.split(",") if x.strip()] or None
    if labels and not a.merge and len(labels) != len(a.results):
        print("ERROR: --labels debe tener tantas etiquetas como resultados.", file=sys.stderr)
        return 2
    try:
        summary = summarize(a.results, a.evals, labels if not (a.merge and labels) else [labels[0]] * len(a.results), a.merge)
    except (OSError, ValueError) as exc:
        print(f"ERROR: no se pudo leer un result.json: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(summary, ensure_ascii=False, indent=2) if a.json else render(summary))
    return 0


if __name__ == "__main__":
    sys.exit(main())
