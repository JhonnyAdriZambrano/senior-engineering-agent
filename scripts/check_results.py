#!/usr/bin/env python3
"""
Informe del benchmark y estado de la puerta hacia 1.0.0 (CHANGELOG.md).

Lee los registros de tests/results/*.md (no los de archive/), decide cuáles son
VÁLIDOS para la puerta y escribe tests/results/RESUMEN.md. finish_test.sh lo
ejecuta al cerrar cada prueba; también puede ejecutarse a mano.

Si el registro tiene un bloque de auditoría («- **Resultado auditado:** **X**»),
ese resultado prevalece sobre el que anotó el evaluador (que se conserva).

Una corrida es válida si: tiene resultado, el sandbox se recreó con
prepare_test.sh, fue en sesión nueva, tiene evidencia objetiva de
finish_test.sh, los hooks estaban activos (configuración de referencia) y el
modelo/effort coinciden con la configuración de referencia de abajo, y tiene
un bloque de auditoría con veredicto («- **Resultado auditado:** **X**», X =
PASS|PARTIAL|FAIL|NO EJERCITADO). Una corrida sin auditar se lista (columna
«Auditado» de RESUMEN.md) pero no cuenta para la puerta.

Puerta: las 14 pruebas (TEST-02 como 2a, 2b y 2c) con sus últimas N corridas
válidas en PASS; N = 3 para TEST-00, TEST-02b, TEST-07 y TEST-13; N = 1 para el
resto.

Uso: python3 scripts/check_results.py [--results DIR] [--output ARCHIVO] [--strict]
     --strict: sale con 1 si la puerta no se cumple.
"""
import argparse
import datetime
import glob
import os
import re
import sys

# Configuración de referencia de la puerta (decisión del autor: 2026-09-27 con
# Sonnet 5; cambiada a Sonnet 5.5 el 2026-10-09, ronda 3). El modelo se compara
# de forma EXACTA (sin distinguir mayúsculas): «Sonnet 5» no vale por «Sonnet 5.5».
REFERENCE_MODEL = "Sonnet 5.5"
REFERENCE_EFFORT = "medium"

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESULTS = ("PASS", "PARTIAL", "FAIL", "NO EJERCITADO")
ITEMS = ["TEST-00", "TEST-01", "TEST-02a", "TEST-02b", "TEST-02c"] + [f"TEST-{i:02d}" for i in range(3, 14)]
REPEAT = {"TEST-00": 3, "TEST-02b": 3, "TEST-07": 3, "TEST-13": 3}
NAME_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})_(TEST-\d\d[abc]?)_r(\d+)\.md$")


def field(text, label):
    m = re.search(r"^- \*\*" + re.escape(label) + r"\*\*\s*(.*)$", text, re.M)
    return m.group(1).strip() if m else ""


def _norm(s):
    return " ".join(s.lower().replace("claude", " ").split())


def config_matches(cfg):
    """«CLI / Modelo / Effort» → compara modelo y effort de forma exacta con la referencia."""
    parts = [p.strip() for p in cfg.split(" / ")]
    if len(parts) < 3:
        return False
    return _norm(parts[1]) == _norm(REFERENCE_MODEL) and _norm(parts[2]) == _norm(REFERENCE_EFFORT)


def parse(path):
    name = os.path.basename(path)
    m = NAME_RE.match(name)
    if not m:
        return None
    text = open(path, encoding="utf-8").read()
    rec = {"file": name, "date": m.group(1), "item": m.group(2), "n": int(m.group(3))}
    res = field(text, "Resultado:")
    rec["result"] = res if res in RESULTS else None
    rec["tester_result"] = rec["result"]
    audited = re.findall(r"\*\*(PASS|PARTIAL|FAIL|NO EJERCITADO)\*\*", field(text, "Resultado auditado:"))
    rec["audited"] = bool(audited)
    if audited:
        rec["result"] = audited[0]
    reasons = []
    if not rec["result"]:
        reasons.append("sin resultado")
    if not field(text, "Sandbox recreado antes de esta prueba:").startswith("sí"):
        reasons.append("sandbox no recreado con prepare_test.sh")
    if not field(text, "Sesión nueva de Claude Code:").startswith("sí"):
        reasons.append("sesión nueva no confirmada")
    if "## Evidencia objetiva (finish_test" not in text:
        reasons.append("sin evidencia de finish_test.sh")
    if not field(text, "Hooks activos:").startswith("sí"):
        reasons.append("sin hooks (corrida informativa)")
    if not rec["audited"]:
        reasons.append("sin auditoría (falta «Resultado auditado»)")
    if not config_matches(field(text, "CLI / Modelo / Effort:")):
        reasons.append(f"modelo/effort distinto de la referencia ({REFERENCE_MODEL}, {REFERENCE_EFFORT})")
    rec["reasons"] = reasons
    rec["valid"] = not reasons
    return rec


def archive_summary(results_dir):
    rows = []
    for d in sorted(glob.glob(os.path.join(results_dir, "archive", "*"))):
        if not os.path.isdir(d):
            continue
        counts = {r: 0 for r in RESULTS}
        files = sorted(glob.glob(os.path.join(d, "*.md")))
        for f in files:
            lines = open(f, encoding="utf-8").read().splitlines()
            # prioridad: auditado > reclasificado > resultado en negrita
            for key in ("Resultado auditado:", "Resultado reclasificado:", "- **Resultado:** **"):
                hit = next((l for l in lines if key in l), None)
                vals = re.findall(r"\*\*(PASS|PARTIAL|FAIL|NO EJERCITADO)", hit) if hit else []
                if vals:
                    counts[vals[-1]] += 1
                    break
        rows.append((os.path.basename(d), len(files), counts))
    return rows


def build(results_dir):
    recs = [r for r in (parse(p) for p in glob.glob(os.path.join(results_dir, "*.md"))) if r]
    recs.sort(key=lambda r: (r["date"], r["n"]))
    status = []
    for item in ITEMS:
        need = REPEAT.get(item, 1)
        valid = [r for r in recs if r["item"] == item and r["valid"]]
        last = valid[-need:]
        ok = len(last) == need and all(r["result"] == "PASS" for r in last)
        status.append((item, need, len(valid), [r["result"] for r in last], ok))
    return recs, status


def render(recs, status):
    met = sum(1 for s in status if s[4])
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
    out = [
        "# Resumen del benchmark (generado — no editar a mano)",
        "",
        f"Generado por `scripts/check_results.py` el {now}. Configuración de referencia: "
        f"**{REFERENCE_MODEL}, effort {REFERENCE_EFFORT}, hooks activos**, sandbox recreado con "
        "`prepare_test.sh` y cerrado con `finish_test.sh`.",
        "",
        f"## Puerta hacia 1.0.0: {'CUMPLE' if met == len(status) else 'NO CUMPLE'} — {met} de {len(status)} ítems",
        "",
        "| Ítem | Corridas válidas necesarias (PASS) | Válidas registradas | Últimas válidas | Estado |",
        "|---|---|---|---|---|",
    ]
    for item, need, nvalid, last, ok in status:
        out.append(f"| {item} | {need} | {nvalid} | {', '.join(last) or '—'} | {'✅' if ok else '⏳'} |")
    out += ["", "## Corridas registradas", "", "| Archivo | Resultado | Auditado | Válida | Motivo si no es válida |", "|---|---|---|---|---|"]
    for r in recs:
        aud = "—"
        if r["audited"]:
            aud = "sí" if r["result"] == r["tester_result"] else f"sí (evaluador: {r['tester_result'] or '—'})"
        out.append(f"| `{r['file']}` | {r['result'] or '—'} | {aud} | {'sí' if r['valid'] else 'no'} | {'; '.join(r['reasons']) or '—'} |")
    if not recs:
        out.append("| (ninguna todavía) | | | | |")
    return "\n".join(out) + "\n"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--results", default=os.path.join(ROOT, "tests", "results"))
    p.add_argument("--output")
    p.add_argument("--strict", action="store_true")
    a = p.parse_args()
    recs, status = build(a.results)
    text = render(recs, status)
    rows = archive_summary(a.results)
    if rows:
        text += "\n## Rondas archivadas (no válidas para la puerta; resultado auditado)\n\n| Ronda | Registros | PASS | PARTIAL | FAIL | NO EJERCITADO |\n|---|---|---|---|---|---|\n"
        for name, n, c in rows:
            text += f"| `archive/{name}` | {n} | {c['PASS']} | {c['PARTIAL']} | {c['FAIL']} | {c['NO EJERCITADO']} |\n"
    out = a.output or os.path.join(a.results, "RESUMEN.md")
    with open(out, "w", encoding="utf-8", newline="") as f:
        f.write(text)
    met = sum(1 for s in status if s[4])
    print(f"Puerta hacia 1.0.0: {met}/{len(status)} ítems cumplidos. Informe: {out}")
    pending = [s[0] for s in status if not s[4]]
    if pending:
        print("Pendientes: " + ", ".join(pending))
    if a.strict and met != len(status):
        sys.exit(1)


if __name__ == "__main__":
    main()
