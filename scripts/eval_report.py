#!/usr/bin/env python3
"""Resume el result.json de `claude plugin eval` (tablas de regresión y de capacidad: caso → WITH / W/OUT / Δ / corridas perfectas / turnos / coste)
y, con --collect-traces DIR, copia las transcripciones de las corridas antes de borrar los temporales
que dejó --keep-temp (solo directorios /tmp/claude-eval-*)."""
import argparse, json, os, shutil, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("result")
    ap.add_argument("--collect-traces")
    a = ap.parse_args()
    d = json.load(open(a.result, encoding="utf-8"))
    rows, fails = [], []
    for c in d["cases"]:
        w = c["arms"].get("with", [])
        wo = c["arms"].get("without", [])
        agg = c["aggregates"]
        score = agg.get("score")
        base = (sum(r["score"] for r in wo) / len(wo)) if wo else None
        perfect = f'{sum(1 for r in w if r["score"] >= 1)}/{len(w)}'
        cost = sum(r.get("costUsd", 0) + r.get("judgeCostUsd", 0) for r in w + wo)
        delta = agg.get("delta")
        flag = "  ◀ Δ≤0" if (delta is not None and delta <= 0) else ""
        turns = (sum(r.get("turns") or 0 for r in w) / len(w)) if w else None
        rows.append((c["name"], score, base, delta, perfect, cost, flag, turns))
        for arm, runs in (("with", w), ("without", wo)):
            for i, r in enumerate(runs, 1):
                for g in r["graders"]:
                    if not g["passed"] and g.get("scored", True):
                        fails.append((c["name"], arm, i, g["name"], g["explanation"], r.get("tracePath")))
                if a.collect_traces and r.get("tracePath") and os.path.isfile(r["tracePath"]):
                    dst = os.path.join(a.collect_traces, c["name"])
                    os.makedirs(dst, exist_ok=True)
                    shutil.copy(r["tracePath"], os.path.join(dst, f"{arm}-{i}.jsonl"))
    f = lambda v: "-" if v is None else f"{v:.2f}"
    for title, sel in (("REGRESIÓN", lambda n: not n.startswith("cap-")), ("CAPACIDAD (cap-*)", lambda n: n.startswith("cap-"))):
        part = [r for r in rows if sel(r[0])]
        if not part:
            continue
        print(f"\n== {title}")
        print(f'{"CASO":34} {"WITH":>5} {"W/OUT":>6} {"Δ":>6}  {"PERFECTAS":>9} {"TURNOS":>6} {"COSTE":>8}')
        for n, s, b, dl, p, cost, flag, turns in part:
            print(f'{n:34} {f(s):>5} {f(b):>6} {("-" if dl is None else f"{dl:+.2f}"):>6}  {p:>9} {f(turns):>6} ${cost:>6.2f}{flag}')
    print(f'\nmeanΔ={d["aggregates"].get("meanDelta")}  coste total estimado=${d.get("costUsd", 0):.2f}  parcial={d.get("partial")}')
    if fails:
        print("\nGraders fallidos (con brazo y nº de corrida):")
        for n, arm, i, g, e, t in fails:
            print(f"  - {n} [{arm} #{i}] {g}: {e[:240]}")
    if a.collect_traces:
        for c in d["cases"]:
            for runs in c["arms"].values():
                for r in runs:
                    p = r.get("tracePath") or ""
                    top = os.sep.join(p.split(os.sep)[:3])
                    if top.startswith("/tmp/claude-eval-") and os.path.isdir(top):
                        os.system(f"chmod -R u+rwX '{top}' 2>/dev/null; rm -rf '{top}'")

if __name__ == "__main__":
    sys.exit(main())
