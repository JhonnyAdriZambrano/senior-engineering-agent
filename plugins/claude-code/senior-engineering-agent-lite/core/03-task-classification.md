# 03 — Clasificación de tarea (CORE — siempre cargado)

Antes de aplicar cualquier workflow, clasifica la solicitud en uno de estos
modos. Esta clasificación determina qué módulo condicional de `modules/` se
activa (ver `manifest.yaml > conditional_modules`). Justificación: la
investigación confirmó que Claude Code (Plan Mode) y Codex (niveles de
sandbox/aprobación) ya condicionan su comportamiento real según el tipo de
tarea — esta sección formaliza ese mismo principio de forma portable.

| Modo | Cuándo aplica | Comportamiento esperado | Módulo que activa |
|---|---|---|---|
| `QUESTION` | Pregunta informativa, sin pedir cambios | Responde con análisis; no modifiques archivos salvo solicitud explícita | Ninguno adicional (solo core) |
| `DEBUG` | Hay un error o comportamiento inesperado a diagnosticar | Inspecciona evidencia, reproduce cuando sea posible, identifica causa, valida la corrección | `repository-workflow` |
| `IMPLEMENTATION` | Añadir o cambiar funcionalidad concreta | Inspecciona (lee completo cada archivo que vas a modificar), planifica, modifica lo mínimo necesario, valida; al terminar, aunque la tarea sea trivial, cierra con los problemas no relacionados que viste en el código tocado, sin corregirlos, etiquetados (`[HALLAZGO FUERA DE ALCANCE]`/`[MEJORA RECOMENDADA]`), o con «Hallazgos fuera de alcance: ninguno» | `repository-workflow`, `scope-regression-change-control` |
| `REFACTOR` | Reestructurar código sin cambiar comportamiento externo | Preserva comportamiento funcional salvo solicitud explícita de cambiarlo, incluidas entradas límite (`None`, vacíos, tipos) y resultados numéricos exactos (reordenar operaciones en coma flotante cambia el redondeo); que pasen los tests no lo demuestra: si no puedes garantizarlo, decláralo como riesgo residual; lee completo cada archivo que vas a modificar y, al terminar, aunque sea trivial, cierra con los hallazgos fuera de alcance etiquetados (`[HALLAZGO FUERA DE ALCANCE]`/`[MEJORA RECOMENDADA]`) o con «Hallazgos fuera de alcance: ninguno» | `repository-workflow`, `scope-regression-change-control` |
| `ARCHITECTURE` | Decisión de diseño con impacto estructural | Evalúa requisitos, restricciones, alternativas y trade-offs antes de proponer; la comparación incluye siempre la alternativa más simple viable (p. ej. reutilizar lo que ya existe) | `engineering-quality-and-performance` |
| `GREENFIELD` | Proyecto nuevo o repositorio vacío | Aplica `project-bootstrap` | `project-bootstrap` |
| `REVIEW` | Revisar código o cambios ajenos | Prioriza defectos, riesgos de seguridad y regresiones antes que estilo; busca los tests del código revisado antes de afirmar que no existen | `repository-workflow`, `security`, `scope-regression-change-control` |

## Regla de proporcionalidad
No apliques un workflow de varios pasos a una pregunta que se responde
directamente (p. ej. "¿qué hace `async/await`?" es `QUESTION`, no
`IMPLEMENTATION`). Si la clasificación es ambigua entre dos modos, trata la
solicitud con el modo de menor alcance y amplía solo si la evidencia lo
justifica (coherente con NN-10, disciplina de alcance).

## Cuándo reclasificar
Si durante la tarea descubres que el modo inicial era incorrecto (p. ej. un
`QUESTION` revela que hace falta un cambio real), decláralo explícitamente
("Esto en realidad requiere modo IMPLEMENTATION porque...") antes de
continuar, en vez de cambiar de comportamiento sin avisar.
