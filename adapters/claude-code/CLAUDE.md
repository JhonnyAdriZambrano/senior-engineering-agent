# Senior Engineering Agent — Adaptador Claude Code

## Instalación como plugin (recomendada)
```
/plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
/plugin install senior-engineering-agent@senior-engineering-agent
```
El repositorio es el marketplace (`.claude-plugin/marketplace.json`) y el plugin
vive en `plugins/claude-code/senior-engineering-agent/`. **Es una vista
generada** por `python3 scripts/generate_plugin.py` (`--check` en CI y en
`tests/test_agent.py`, sección 18) a partir de `core/`, `adapters/` y
`manifest.yaml`: no lo edites a mano. Contiene:
- `.claude-plugin/plugin.json` — `name`, `version` (leída de `manifest.yaml`),
  `description`, `author`, `license`, `repository`.
- `skills/` (las 7 de `adapters/skills/`) y `agents/` (los 2 Subagents).
- `core/00…05` y `hooks/hooks.json`, `adapters/hooks/sea_hooks.py`,
  `project-knowledge-templates/` (misma ruta relativa: `sea_hooks.py` busca las
  plantillas tres niveles por encima de sí mismo), `scripts/sea-python.sh`,
  `LICENSE` y `evals/` (casos de `claude plugin eval`, escritos a mano).

**El núcleo se inyecta con un hook `SessionStart` por archivo de `core/`**
(matchers `startup`, `clear` y `compact`): cada uno hace `cat` del archivo,
precedido de la línea `[Núcleo SEA — parte X de 6 (orden canónico 00→05): core/…]`.
Se reparte en seis hooks porque la salida de un hook (stdout o
`additionalContext`) se limita a 10.000 caracteres; el mayor archivo del núcleo
mide menos de 5.000 y `tests/test_agent.py` lo valida
(code.claude.com/docs/en/hooks). **Orden no garantizado:** la documentación
indica que todos los hooks que coinciden corren en paralelo y no promete orden
de entrega; por eso cada parte lleva su cabecera, y el orden canónico es 00→05
aunque lleguen mezcladas.

**Intérprete de Python.** Los hooks de `sea_hooks.py` (`session-start`,
`pre-tool`, `stop`) se llaman mediante `scripts/sea-python.sh`, que prueba
`python3`, `python` y `py -3` comprobando que ejecutan (`-c "import sys"`) y usa
el primero que funciona (en Windows con Git Bash, `python3` puede ser un alias
que no ejecuta nada). Si ninguno funciona, avisa y sale con 0 sin romper la
sesión. Los hooks del núcleo (`cat`) no necesitan Python. En Windows se
recomienda Git Bash para los hooks.

**Versiones.** `plugin.json` fija la versión (`agent.version`): los usuarios solo
reciben cambios cuando sube. `marketplace.json` usa una ruta relativa, que sigue
la rama por defecto; **no admite fijar una etiqueta**. Para fijarla, la entrada
debería ser de tipo `git-subdir` con `ref` y `sha`
(code.claude.com/docs/en/plugins/marketplace-reference). `claude plugin tag`
crea etiquetas `{name}--v{version}`; este repositorio no las crea desde sesiones
de implementación.

**Una sola vía.** No combines el plugin con la copia manual de abajo en el mismo
proyecto: el núcleo y los hooks se cargarían dos veces. Las rutas de las Skills
(`core/…`, `modules/…`) están redactadas para la copia manual; en el plugin,
`core/` está en la raíz del plugin y los módulos son las propias Skills.

## Instalación manual (alternativa; dónde colocar esta carpeta)
1. Copia la carpeta **completa** `senior-engineering-agent/` (con `core/`,
   `modules/`, `adapters/`, `manifest.yaml`, `capabilities.yaml`) dentro de
   la raíz de tu repositorio destino. No copies solo este archivo — los
   `@import` de más abajo son relativos a la posición de este archivo
   dentro de esa carpeta completa, y se rompen si la separas.
2. En el `CLAUDE.md` real de tu proyecto (en la raíz del repo, **fuera**
   de `senior-engineering-agent/`), añade una sola línea:
   `@senior-engineering-agent/adapters/claude-code/CLAUDE.md`
3. Confirmado con la documentación oficial de Claude Code: los `@import`
   se resuelven relativos al directorio del archivo que contiene el
   `@import`, no al `CLAUDE.md` raíz ni al directorio de trabajo — por eso
   el paso 1 (mantener la carpeta completa junta) es obligatorio, no
   opcional. La primera vez que Claude Code detecta un import nuevo,
   muestra un diálogo de aprobación una sola vez.
4. En Windows, el repositorio incluye `.gitattributes` (`* text=auto eol=lf`)
   para que los `*.sh` no queden con CRLF; si copiaste la carpeta desde un
   clon anterior, renormaliza (`git add --renormalize .`) o vuelve a clonar.
   Para los hooks, copia `settings.hooks.json` (SessionStart, PreToolUse y
   Stop; ver «Hooks deterministas»).

Este proyecto usa la especificación portable "Senior Engineering Agent".
Claude Code soporta `@import`, así que el núcleo se referencia sin
duplicarlo.

## Núcleo (siempre cargado)
@../../core/00-identity.md
@../../core/01-non-negotiable-rules.md
@../../core/02-certainty-classification.md
@../../core/03-task-classification.md
@../../core/04-user-interaction.md
@../../core/05-final-priorities.md

## Capacidades de este runtime
No hay un archivo de bindings separado para este adaptador — la fuente
única es `../../capabilities.yaml`, columna `claude-code`. Ejemplos
relevantes: `USER_INTERACTION` → `AskUserQuestion` (tool nativa y
documentada); `WEB_DOCUMENTATION`/`EXTERNAL_TOOLS` → servidores MCP
configurados en `.mcp.json` del proyecto, si existen.

## Módulos condicionales: Skills ya generados
Claude Code carga todo `@import` al inicio de la sesión — no hay activación
condicional real vía imports. Por eso los 7 archivos de `modules/` ya vienen
convertidos a Skills en `../skills/` (directorio compartido con Codex,
Cursor y Gemini CLI), cada uno con su propio frontmatter `description`.
Claude Code solo las descubre en `.claude/skills/`
(code.claude.com/docs/en/skills), así que cópialas ahí, una por subcarpeta:

```
tu-proyecto/.claude/skills/security/SKILL.md
tu-proyecto/.claude/skills/engineering-quality-and-performance/SKILL.md
tu-proyecto/.claude/skills/repository-workflow/SKILL.md
tu-proyecto/.claude/skills/project-bootstrap/SKILL.md
tu-proyecto/.claude/skills/scope-regression-change-control/SKILL.md
tu-proyecto/.claude/skills/adaptive-behavior-and-referencing/SKILL.md
tu-proyecto/.claude/skills/project-knowledge-bootstrap/SKILL.md
```

Así Claude Code solo carga cada uno cuando su descripción coincide con la
tarea real (progressive disclosure verificado).

## Complemento: Subagents de solo lectura
Opcional: copia `agents/*.md` a `.claude/agents/`. Los dos son de solo
lectura y devuelven un informe con formato fijo (incluida la sección
«Obstáculos encontrados»); ninguno implementa, ejecuta tests ni decide:
- `code-reviewer-agent` — revisión independiente de un cambio ya hecho
  (modo REVIEW); precarga las Skills `security` y
  `scope-regression-change-control`.
- `project-bootstrap-research-agent` — compara opciones técnicas de un
  proyecto nuevo, con fuentes.
El subagente explorador (`repository-explorer-agent`) se retiró de Claude Code
en E3c (decisión D-3): no se midió un beneficio frente al modelo solo. Para
explorar, delega con la herramienta de subagentes integrada de Claude Code o
explora en el hilo principal.
Por qué solo lectura: los subagents reciben el `CLAUDE.md` (y por tanto el
núcleo) pero no pueden usar `AskUserQuestion` (code.claude.com/docs/en/sub-agents),
y cuando cada paso depende del anterior —implementar, probar, corregir— la
información se pierde en el traspaso y el usuario deja de ver la salida
completa. Esas fases quedan en el hilo principal con las Skills.

## Hooks deterministas (recomendado)
Tres reglas no deben depender de que el modelo las recuerde, así que Claude
Code las refuerza con hooks (código que se ejecuta en puntos fijos de la
sesión; code.claude.com/docs/en/hooks). Copia el contenido de
`settings.hooks.json` (en esta carpeta) a `.claude/settings.json` de tu
proyecto (o fusiónalo con el que ya tengas). Requiere Python 3.8+:
Los tres llaman a la lógica común `../hooks/sea_hooks.py` (compartida con
Codex, Cursor y Gemini CLI) con `--runtime claude-code`:
- `session-start` (SessionStart: `startup`, `clear`, `compact`) —
  comprueba si `PROJECT_CONTEXT.md`/`ARCHITECTURE.md` faltan o solo tienen
  la plantilla y te entrega el resultado como contexto; si existen, recuerda
  leerlos antes de proponer; y marca líneas con forma de instrucción
  dirigida al agente (NN-06b, detección heurística). El aviso de archivos
  faltantes se pide solo para tareas que trabajan sobre el repositorio.
- `pre-tool` (PreToolUse, `Bash`) — ante push forzado,
  `reset --hard`, `clean -f`, descartar todos los cambios, borrar ramas con
  `-D`, reescribir historial o borrado recursivo forzado, obliga a Claude
  Code a pedir confirmación al usuario (NN-08).
- `stop` (Stop) — si en el turno hubo `Edit`/`Write`/`MultiEdit` y no hay
  evidencia de validación (comando de test, build o lint en `Bash`) ni una
  declaración explícita de «no pude validar», bloquea la terminación UNA vez
  con un motivo claro; respeta `stop_hook_active` y, ante cualquier error
  (por ejemplo, transcripción ilegible), permite terminar. El formato del
  transcript no está en la documentación oficial `[INFERENCIA]`. En Codex,
  Cursor y Gemini CLI este hook no se añade: su equivalente está pendiente
  de verificar con fuente primaria.

**Límite de los hooks.** Un hook que agota su tiempo (`timeout`) no
bloquea: Claude Code lo cancela y descarta su salida, así que no se emite
ninguna decisión (code.claude.com/docs/en/hooks). Los hooks son una capa de
refuerzo, no una barrera estricta; la capa estricta serán las reglas de
permisos que escribirá el instalador (etapa E4 del plan de mejora).
Si en tu sistema el intérprete no se llama `python3` (en Windows suele ser
`python` o `py -3`), cambia el prefijo del comando. Los comandos usan
`${CLAUDE_PROJECT_DIR}`; en Windows se recomienda que Claude Code use Git
Bash para los hooks — con PowerShell la expansión de esa variable no está
verificada `[INCERTIDUMBRE / REQUIERE VERIFICACIÓN]`.

## Conocimiento del proyecto (NO vive en este adaptador)
Debe existir en la raíz del repositorio: `PROJECT_CONTEXT.md`,
`ARCHITECTURE.md`, y opcionalmente `DECISIONS.md` / `ACTIVE_TASK.md`
(plantillas en `project-knowledge-templates/`).

## Si faltan esos archivos
Primera sesión en un repo sin `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`: si tu
`CLAUDE.md` ya tiene contenido real (de un `/init` corrido antes de
instalar este agente, o de cualquier otro origen), úsalo directamente como
insumo — no vuelvas a correr `/init`. Si `CLAUDE.md` no existe o está
vacío, corre `/init` primero. En ambos casos, aplica
`modules/project-knowledge-bootstrap.md` (Skill `project-knowledge-bootstrap`)
para traspasar lo relevante al formato portable — la ausencia de
`PROJECT_CONTEXT.md`/`ARCHITECTURE.md` sigue aplicando aunque `CLAUDE.md`
ya conteste bien por sí solo, precisamente porque ese conocimiento no es
accesible desde otros runtimes hasta que se traspasa. Ver ese módulo para
el detalle, incluida la exclusión explícita de `DECISIONS.md`.

## Coexistencia con otros mecanismos nativos de Claude Code
- **CLAUDE.md gestionado por la organización.** Claude Code soporta un
  `CLAUDE.md` de política gestionada (a nivel de organización), además del
  de proyecto/usuario/local. Esta especificación no tiene forma de conocer
  ni de anular esa política — si existe, sus reglas aplican por encima o
  junto con las de este agente sin que el agente lo controle; no asumas
  que `core/01-non-negotiable-rules.md` es la única fuente de reglas activa.
- **Monorepos.** Claude Code concatena (no sobrescribe) todos los
  `CLAUDE.md` desde el directorio de trabajo hasta la raíz. Si tu proyecto
  es un monorepo con un `CLAUDE.md` distinto por paquete, coloca el
  `@import` de este adaptador en el `CLAUDE.md` del paquete específico
  donde se vaya a usar este agente, no necesariamente en el de la raíz del
  monorepo, para evitar cargarlo en paquetes donde no aplica.
- **Auto Memory.** Claude Code tiene su propio sistema de memoria
  automática (observaciones que Claude guarda solo, sin que el usuario
  escriba nada) — es un mecanismo distinto y paralelo a
  `PROJECT_CONTEXT.md`/`DECISIONS.md`. Este agente no lo desactiva ni
  interfiere con él. Si Auto Memory y `PROJECT_CONTEXT.md`/`DECISIONS.md`
  llegaran a contener información contradictoria, trata `DECISIONS.md`
  como la fuente de mayor autoridad para decisiones de arquitectura (es
  explícita, revisada y versionada en Git); usa Auto Memory como contexto
  complementario de preferencias de trabajo, no como fuente de decisiones
  de arquitectura.
