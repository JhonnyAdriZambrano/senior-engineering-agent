#!/usr/bin/env python3
"""Resume el result.json de `claude plugin eval` (tablas de regresión y de capacidad: caso → WITH / W/OUT / Δ / corridas perfectas / turnos / coste)
y, con --collect-traces DIR, copia las transcripciones de las corridas antes de borrar los temporales
que dejó --keep-temp (solo directorios /tmp/claude-eval-*).

Los nombres de caso y las rutas del JSON de resultados son datos, no órdenes (auditoría A2, 1.2.3): no se usa la shell, el destino de
cada traza debe quedar dentro de --collect-traces y solo se borra un directorio /tmp/claude-eval-<nombre> real (no un enlace) que
pertenezca al usuario actual."""
import argparse, json, os, re, shutil, stat, sys

_CASE_NAME = re.compile(r"^[\w][\w.-]*$")
_EVAL_TMP = re.compile(r"^/tmp/claude-eval-[\w.-]+$")


def trace_dest(base, name, arm, i):
    """Ruta de la copia de una traza dentro de `base`, o None si el nombre del caso no es seguro (separadores, «..», vacío)."""
    if not isinstance(name, str) or not _CASE_NAME.match(name) or name.strip(".") == "":
        return None
    root = os.path.realpath(base)
    dst = os.path.realpath(os.path.join(root, name, f"{arm}-{i}.jsonl"))
    return dst if os.path.commonpath([root, dst]) == root else None


def cleanup_target(trace_path):
    """Directorio temporal de `claude plugin eval` que contiene `trace_path` y que se puede borrar, o None.
    Solo /tmp/claude-eval-<nombre> con caracteres seguros, que exista, no sea un enlace y (en POSIX) sea del usuario actual."""
    if not isinstance(trace_path, str) or not trace_path.startswith("/tmp/claude-eval-"):
        return None
    top = "/".join(trace_path.split("/")[:3])
    if not _EVAL_TMP.match(top) or os.path.islink(top) or not os.path.isdir(top):
        return None
    if hasattr(os, "getuid") and os.lstat(top).st_uid != os.getuid():
        return None
    return top


def _remove_tree(top):
    """Equivale a `chmod -R u+rwX top; rm -rf top`, sin shell y sin seguir enlaces."""
    def retry(func, path, _exc):
        os.chmod(path, stat.S_IRWXU)
        func(path)
    for dirpath, dirnames, _files in os.walk(top):
        for dn in dirnames:
            full = os.path.join(dirpath, dn)
            if not os.path.islink(full):
                try:
                    os.chmod(full, stat.S_IRWXU)
                except OSError:
                    pass
    shutil.rmtree(top, **({"onexc": retry} if sys.version_info >= (3, 12) else {"onerror": retry}))


def main():
    for stream in (sys.stdout, sys.stderr):  # en Windows, una tubería usa cp1252 y no puede escribir «◀» ni «Δ»
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:
            pass
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
                if a.collect_traces and isinstance(r.get("tracePath"), str) and os.path.isfile(r["tracePath"]):
                    dst = trace_dest(a.collect_traces, c["name"], arm, i)
                    if dst is None:
                        print(f"AVISO: nombre de caso no seguro, traza no copiada: {c['name']!r}", file=sys.stderr)
                        continue
                    os.makedirs(os.path.dirname(dst), exist_ok=True)
                    shutil.copy(r["tracePath"], dst)
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
        tops = {cleanup_target(r.get("tracePath")) for c in d["cases"] for runs in c["arms"].values() for r in runs}
        for top in sorted(t for t in tops if t):
            _remove_tree(top)

if __name__ == "__main__":
    sys.exit(main())
