# Cómo agregar un adaptador para un runtime nuevo

Este documento es el contrato explícito que faltaba entre el CORE y
cualquier adaptador — la checklist aislada que la auditoría final marcó
como ausente. Si vas a soportar un séptimo runtime (o el tercero para tu
propio caso de uso), esto es lo mínimo que necesitas resolver.

## 1. Capacidades mínimas que tu runtime debe resolver (o declarar ausentes)

Tu adaptador debe decidir, para cada una de estas 8 capacidades abstractas
declaradas en `capabilities.yaml`, uno de tres estados — nunca dejarla sin
mencionar:

| Capacidad | Pregúntate | Si no existe, declara |
|---|---|---|
| `USER_INTERACTION` | ¿Tiene una tool de pregunta estructurada, o solo diálogo conversacional? | "diálogo conversacional estándar" (fallback siempre válido) |
| `FILE_SYSTEM` | ¿Puede leer/escribir archivos del proyecto? | `SIN BINDING` |
| `TERMINAL` | ¿Puede ejecutar comandos? | `SIN BINDING` |
| `CODE_SEARCH` | ¿Tiene búsqueda de símbolos/referencias propia? | `SIN BINDING` |
| `GIT` | ¿Puede ejecutar git (normalmente vía TERMINAL)? | `SIN BINDING` |
| `WEB_DOCUMENTATION` | ¿Es cliente MCP? ¿Tiene búsqueda web nativa? | `SIN BINDING` |
| `EXTERNAL_TOOLS` | ¿Es cliente MCP para conectores externos? | `SIN BINDING` |
| `VISUAL_INSPECTION` | ¿Puede renderizar y ver la interfaz (captura, navegador)? | `SIN BINDING` — no afirmar verificación visual |

Añade una fila nueva (con el nombre de tu runtime) a los `bindings` de cada
una de las 8 entradas en `capabilities.yaml`. **No** crees un archivo de
bindings separado para tu adaptador — `capabilities.yaml` es la única
fuente de verdad (ver la lección aprendida de la auditoría: duplicar
bindings en un segundo archivo los desincroniza).

## 2. Cómo carga tu runtime el CORE — elige uno

| Mecanismo | Cuándo usarlo |
|---|---|
| Import nativo (`@ruta` o equivalente) | Si tu runtime soporta incluir archivos externos por referencia — confirma primero si la resolución es relativa al archivo importador o al archivo raíz (esto rompió nuestra confianza inicial hasta verificarlo; no lo asumas sin fuente primaria). |
| Núcleo compacto generado | Si tu runtime solo lee un único archivo de instrucciones sin imports (Codex/`AGENTS.md`, Cursor) o tiene límite de caracteres y no tiene concepto de "archivo del proyecto" (ChatGPT Projects/Gemini Gems): **no reescribas un resumen a mano** (así se perdió NN-06b en tres adaptadores). Añade al adaptador un par `<!-- BEGIN:compact -->` / `<!-- END:compact -->`, registra su ruta en `scripts/generate_compact.py > TARGETS` y en `tests/test_agent.py` (`COMPACT_ADAPTERS`), y ejecuta `python3 scripts/generate_compact.py`. Sube `modules/`/conocimiento como adjunto si la plataforma lo permite. |

## 3. Cómo activa tu runtime los `modules/` condicionales — elige uno

| Mecanismo | Cuándo usarlo |
|---|---|
| Skills (formato abierto `SKILL.md`) | **Opción preferida.** Si tu runtime descubre Skills (Claude Code en `.claude/skills/`; Codex, Cursor y Gemini CLI en `.agents/skills/`), reutiliza `adapters/skills/` tal cual y documenta solo la carpeta de instalación. No generes una copia por runtime. |
| Activación condicional por metadatos propios | Si tu runtime no lee `SKILL.md` pero tiene su propio mecanismo (p. ej. reglas con `description`/`globs`), genera la vista desde `modules/` con un script, nunca a mano. |
| Hooks deterministas | Si tu runtime tiene un evento de inicio de sesión que añada contexto y otro previo a comandos de shell que pueda bloquear o pedir confirmación, añade un `--runtime` a `adapters/hooks/sea_hooks.py` (solo el formato de entrada/salida; las reglas son comunes) y una configuración en tu adaptador. Cubre la causa MECANISMO de TEST-02 y refuerza NN-08. |
| Subagent de solo lectura | Opcional y complementario. Solo para trabajo cuyo detalle intermedio no importa (exploración, revisión independiente, investigación); con formato de salida fijo y sección «Obstáculos encontrados». Implementar, ejecutar tests y decidir con el usuario se quedan en el hilo principal. |
| Referencia manual en prosa | Si tu runtime no tiene ningún mecanismo de activación condicional — documenta explícitamente que la "carga bajo demanda" en ese runtime es una convención de comportamiento que el modelo debe decidir seguir, no una garantía estructural (sé honesto sobre esta limitación, no la ocultes). |

## 4. Checklist de entrega de un adaptador nuevo

- [ ] Fila añadida en `capabilities.yaml` para las 8 capacidades (o `SIN BINDING` explícito).
- [ ] Mecanismo de carga del CORE elegido y documentado (sección 2).
- [ ] Mecanismo de activación de `modules/` elegido y documentado (sección 3).
- [ ] Instrucción explícita de **dónde colocar físicamente los archivos** dentro de un proyecto destino (el hallazgo más importante de la auditoría: nunca asumas que esto es obvio).
- [ ] Nota de coexistencia con cualquier mecanismo nativo de memoria/contexto que tu runtime ya tenga (evita que dos sistemas de "memoria" se contradigan en silencio).
- [ ] Verificado, no asumido: cualquier comportamiento técnico específico de tu runtime del que dependa tu diseño (resolución de rutas, límites de tamaño, comandos nativos) tiene una fuente primaria citada — si no puedes confirmarlo, tu adaptador debe decirlo explícitamente como `[INCERTIDUMBRE / REQUIERE VERIFICACIÓN]`.
- [ ] Añadida una fila nueva en la matriz de compatibilidad de `SPECIFICATION.md §7`.
- [ ] Si tu adaptador no puede hacer `@import`: bloque `BEGIN/END:compact` añadido, ruta registrada en `scripts/generate_compact.py` y `tests/test_agent.py`, y `python3 scripts/generate_compact.py` ejecutado (garantiza que NN-06b y el rol canónico llegan a tu runtime).
- [ ] Si tu adaptador consume Skills: instrucciones para copiar `adapters/skills/` a la carpeta que descubre tu runtime, y `python3 scripts/generate_skills.py --check` en verde.
- [ ] Ejecutado `tests/run_tests.sh` y confirmado que sigue en verde (valida estructura, consistencia de triggers, ausencia de secretos y sincronización Skill↔módulo, no el comportamiento del runtime en sí, que no se puede automatizar sin ese runtime real).

## 5. Qué nunca debe tocar un adaptador nuevo

Un adaptador nuevo **no debe requerir cambios en `core/`**. Si descubres
que necesitas modificar `core/` para soportar tu runtime, eso es una señal
de que la capacidad que necesitas no es tan universal como se pensaba —
detente y evalúa si en realidad es una capacidad nueva que falta declarar
en `capabilities.yaml`, no un cambio de comportamiento del núcleo.

Añadir un `module/` nuevo (no específico de tu runtime) sí puede requerir
una línea nueva en `manifest.yaml > conditional_modules` — eso es
compartido por diseño (todos los runtimes se benefician del módulo nuevo),
no una excepción a la regla anterior.
