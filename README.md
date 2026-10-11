# Senior Engineering Agent

Especificación portable de un agente que encarna el rol de **Ingeniero de
Software Senior y Arquitecto de Tecnologías de la Información Senior**:
identidad, reglas y workflows definidos **una sola vez**, capaces de
materializarse en Claude Code, OpenAI Codex, Cursor, Gemini CLI, ChatGPT
Projects y Gemini Gems sin reescribir el comportamiento en cada plataforma.

## Requisitos

- **Para usar el agente** (cargarlo en Claude Code, Codex, Cursor, Gemini
  CLI, ChatGPT Projects o Gemini Gems): ninguno además del runtime mismo —
  es texto plano (Markdown/YAML/TOML) que ese runtime consume directamente.
- **Para correr los tests o regenerar el ZIP** (solo necesario si vas a
  modificar el agente, no para usarlo): Python 3.11+ con `pyyaml`
  (`pip install pyyaml --break-system-packages`), y las utilidades de
  sistema `zip`/`unzip`. Con Python 3.10, instala también `tomli` para no
  omitir la validación TOML.

## Qué es y qué problema resuelve

Escribir "un buen prompt de ingeniero senior" para una sola plataforma es
fácil. Mantener ese mismo comportamiento — reglas de seguridad, criterio de
cuándo preguntar, disciplina de alcance — consistente en 6 plataformas
distintas, cada una con su propio formato de instrucciones, límites de
tamaño y mecanismos de carga, no lo es. Este proyecto separa:

- **Qué debe hacer el agente** (identidad, reglas, criterio) — se escribe
  una vez, en `core/` y `modules/`.
- **Cómo se lo decimos a cada plataforma** — vive en `adapters/`, un
  directorio por runtime, que traduce (nunca duplica) lo anterior al
  mecanismo nativo de esa plataforma.
- **Qué sabe sobre TU proyecto** — nunca vive aquí. Vive en
  `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`/`DECISIONS.md` dentro de cada
  repositorio real donde despliegues el agente (plantillas en
  `project-knowledge-templates/`).

Ver `SPECIFICATION.md` para la arquitectura completa y la justificación
basada en evidencia de cada decisión de diseño.

## Estructura del repositorio

```
senior-engineering-agent/
├── README.md                  este archivo
├── CHANGELOG.md                historial de versiones y política de versionado
├── SPECIFICATION.md            arquitectura completa, contrato del agente
├── manifest.yaml                identidad, versión, índice de módulos
├── capabilities.yaml            capacidades abstractas → binding por runtime
├── core/                        6 archivos siempre cargados + compact.md
│                                (resumen DERIVADO para runtimes sin @import)
├── modules/                     7 módulos de carga condicional
├── adapters/                    un directorio por runtime soportado
│   ├── skills/                   7 Skills (SKILL.md) GENERADAS desde modules/,
│   │                             compartidas por Claude Code, Codex, Cursor y Gemini CLI
│   ├── claude-code/              CLAUDE.md + agents/ (Subagents de solo lectura)
│   │                             + settings.hooks.json (hooks SessionStart, PreToolUse)
│   ├── hooks/sea_hooks.py        lógica común de los hooks (Claude Code, Codex, Cursor, Gemini CLI)
│   ├── codex/                    AGENTS.md + agents/ (Subagents de solo lectura)
│   ├── cursor/rules/              regla alwaysApply con el núcleo compacto
│   ├── gemini-cli/                GEMINI.md
│   └── chatgpt-and-gems/          instrucciones comprimidas + archivos adjuntos
├── plugins/claude-code/senior-engineering-agent/  plugin de Claude Code GENERADO (+ evals/ propios)
├── .claude-plugin/marketplace.json  el repo es el marketplace del plugin
├── project-knowledge-templates/ plantillas que copias a TU proyecto real
├── docs/
│   └── ADDING_A_RUNTIME.md      contrato para construir un adaptador nuevo
├── tests/                        validación estructural + benchmark de comportamiento
│   ├── GUIA_BENCHMARK.md         CÓMO ejecutar todas las pruebas (empieza aquí)
│   ├── sandbox/setup_sandbox.sh  crea el sandbox del benchmark (estados A/B/C)
│   └── results/                  registros de corridas (plantilla _TEMPLATE.md)
└── scripts/
    ├── build_zip.sh              empaquetado determinista (dist | repo)
    ├── generate_skills.py        modules/ -> adapters/skills/ (--check solo comprueba)
    ├── generate_compact.py       core/compact.md -> adaptadores sin @import
    ├── generate_plugin.py        core/, adapters/ y manifest.yaml -> plugin de Claude Code (--check solo comprueba)
    └── new_result.sh             crea el registro prellenado de una corrida del benchmark
```

## Instalación y uso

### Con Claude Code

**Opción recomendada: instalación como plugin.** El propio repositorio es el
marketplace (`.claude-plugin/marketplace.json`). Dentro de Claude Code:

```
/plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
/plugin install senior-engineering-agent@senior-engineering-agent
```

(En Claude Code 2.1.275 o posterior también sirve, en un solo paso:
`/plugin install senior-engineering-agent --marketplace JhonnyAdriZambrano/senior-engineering-agent`.)
El plugin trae las 7 Skills, los 3 Subagents de solo lectura, el núcleo
(inyectado al iniciar la sesión por un hook `SessionStart` por cada archivo de
`core/`) y los hooks deterministas; no hace falta tocar `CLAUDE.md` ni copiar
nada. Es una **vista generada** (`plugins/claude-code/senior-engineering-agent/`,
`python3 scripts/generate_plugin.py`), no una segunda fuente de verdad. Los
hooks de Python usan un lanzador que prueba `python3`, `python` y `py -3`.
En Windows se recomienda Git Bash para los hooks. Los hooks de un mismo evento
corren en paralelo y la documentación no garantiza su orden: cada parte del
núcleo lleva la cabecera «[Núcleo SEA — parte X de 6 (orden canónico 00→05)]».
Detalle y límites: `adapters/claude-code/CLAUDE.md`.

**Alternativa: copia manual** (sin plugin; no combines ambas en el mismo
proyecto).

1. Copia la carpeta **completa** `senior-engineering-agent/` a la raíz de
   tu repositorio.
2. En el `CLAUDE.md` de tu proyecto, añade una línea:
   `@senior-engineering-agent/adapters/claude-code/CLAUDE.md`
3. Copia cada carpeta de `adapters/skills/` a `.claude/skills/` en tu
   proyecto (`.claude/skills/<nombre>/SKILL.md`) para que Claude Code las
   cargue solo cuando la tarea lo amerite.
4. Opcional: copia `adapters/claude-code/agents/*.md` a `.claude/agents/`
   para habilitar los Subagents de solo lectura (explorador, revisor e
   investigación de bootstrap).
5. Recomendado: copia `adapters/claude-code/settings.hooks.json` a
   `.claude/settings.json` (o fusiónalo) para activar los hooks
   deterministas: aviso de conocimiento faltante al iniciar la sesión y
   confirmación obligatoria de operaciones destructivas. Requiere Python 3.8+.
6. Copia `project-knowledge-templates/*.md` a la raíz de tu proyecto
   (quitando `[Nombre del proyecto]` y rellenando), o deja que
   `project-knowledge-bootstrap` te ayude a generarlas tras correr `/init`.

Detalle completo, incluida la coexistencia con `CLAUDE.md` gestionado por
organización, monorepos y Auto Memory: `adapters/claude-code/CLAUDE.md`.

### Con OpenAI Codex

1. Copia la carpeta **completa** `senior-engineering-agent/` a la raíz de
   tu repositorio (Codex no tiene mecanismo de import; el contenido debe
   copiarse literal).
2. Copia el contenido de `adapters/codex/AGENTS.md` (desde "Identidad"
   hasta el final, sin la sección de instalación) a tu `AGENTS.md` real.
3. Copia cada carpeta de `adapters/skills/` a `.agents/skills/` en tu
   proyecto — Codex las descubre nativamente (también Cursor y Gemini CLI).
4. Opcional: copia `adapters/codex/agents/*.toml` a `.codex/agents/` para
   habilitar los Subagents de solo lectura.
5. Recomendado: copia `adapters/codex/hooks.json` a `.codex/hooks.json`
   (hooks deterministas; en Codex las operaciones destructivas se bloquean,
   porque aún no admite pedir confirmación desde un hook).

Detalle completo: `adapters/codex/AGENTS.md`.

### Con Cursor, Gemini CLI, ChatGPT Projects o Gemini Gems

Cada adaptador en `adapters/` incluye su propia sección de instalación al
inicio del archivo correspondiente. Cursor y Gemini CLI usan además las
Skills de `adapters/skills/`, instaladas en `.agents/skills/`, y los hooks
deterministas (`adapters/cursor/hooks.json` → `.cursor/hooks.json`;
`adapters/gemini-cli/settings.hooks.json` → `.gemini/settings.json`). La mecánica de carga difiere por
plataforma (import real, copia literal, o compresión + archivo adjunto) —
ver la matriz de compatibilidad en `SPECIFICATION.md §7` para el detalle
exacto de qué soporta cada una.

### Agregar un runtime que no está en esta lista

Ver `docs/ADDING_A_RUNTIME.md` — el contrato explícito de capacidades
mínimas y checklist para construir un adaptador nuevo sin tocar `core/`.

## Limitaciones conocidas (léelas antes de asumir portabilidad total)

- La **carga condicional real** de módulos (activación solo cuando la
  tarea lo amerita) la ofrecen, vía Skills, Claude Code, Codex, Cursor y
  Gemini CLI: el runtime carga la Skill cuando su descripción coincide con
  la tarea (la decisión la toma el modelo con esa descripción). En ChatGPT
  Projects y Gemini Gems no existe ese mecanismo: los módulos se suben
  como archivos adjuntos y su uso es una convención de comportamiento.
- Ninguna arquitectura de instrucciones cambia el nombre visible del
  producto anfitrión en su interfaz (Claude Code sigue siendo Claude Code).
- Este agente no anula políticas de seguridad/aprobación nativas de la
  plataforma donde corre — es un piso de comportamiento adicional, no un
  techo que las sustituye.
- Ver `SPECIFICATION.md §6` y `§7` para el detalle completo de qué es
  portable, qué es adaptable y qué depende fuertemente de una plataforma.

## Testing

```bash
python3 tests/test_agent.py
```

Valida: integridad de estructura (todo lo declarado en `manifest.yaml`
existe), coherencia del esquema de `capabilities.yaml`, consistencia entre
`manifest.yaml`/`core/03-task-classification.md`/cabeceras de módulo,
ausencia de referencias rotas a archivos de nivel de paquete, ausencia de
secretos, validez de sintaxis YAML/TOML, validez de frontmatter en los
Skills generados, sincronía del núcleo compacto con los adaptadores sin
`@import` (Codex, Cursor, ChatGPT/Gems), carga del núcleo completo en los
que sí lo tienen, rol canónico, coherencia de versión y de conteos entre
documentos, redacción de reglas, determinismo del empaquetado, rutas de los
adaptadores tras la instalación y reglas NN en el subagent de Codex. Las
comprobaciones que no pueden ejecutarse se informan como `[SKIP]`, nunca
como superadas.

Esto es validación **estructural** (estática), no un test de comportamiento
real del agente. Para eso existen dos niveles: `tests/BENCHMARK.md`
(14 pruebas formales con criterios objetivos PASS/PARTIAL/FAIL y
diagnóstico de causa raíz — Modelo/Prompt/Contexto del proyecto/Tooling) y
`tests/behavioral/run_scenarios.sh` (**OBSOLETO**: lo sustituye `claude plugin eval`, ver abajo; 9 de esas 14 automatizadas contra
una instalación real de Claude Code vía `claude -p --output-format json`).
Ambos son screening heurístico, no perfecto — revisa `tests/MANUAL_SCENARIOS.md`
para el detalle narrativo de cada caso. **Procedimiento paso a paso (sandbox,
fixtures, repeticiones, qué PASS del script no creer aún):
`tests/GUIA_BENCHMARK.md`.**

**Evaluación automatizada (`claude plugin eval`).** `bash scripts/eval.sh <smoke|regression|all>` ejecuta los casos de
`plugins/claude-code/senior-engineering-agent/evals/` (13 casos del benchmark automatizados total o parcialmente, más 2 indicadores del
núcleo) y mide el valor del agente frente al modelo solo (Δ). Requiere `bubblewrap` y `socat` (WSL2 en Windows) y consume plan o API; los
resultados van a `tests/results/evals/` (no se versiona). Qué se automatiza, qué es manual y la tabla criterio → grader: `evals/README.md`;
procedimiento: `tests/GUIA_BENCHMARK.md` §6b.

## Generar el ZIP de distribución

```bash
bash scripts/build_zip.sh          # distribución (sin tests/ ni scripts/)
bash scripts/build_zip.sh repo     # repositorio completo, para seguir desarrollando
```

Genera en `dist/`:

- `senior-engineering-agent-<versión>.zip` — lo que un runtime consume.
- `senior-engineering-agent-<versión>-REPO-COMPLETO.zip` — repo completo.

La carpeta raíz dentro de ambos se llama siempre `senior-engineering-agent/`.
La construcción es **determinista** (mismo contenido ⇒ mismo SHA-256): el
script construye dos veces y falla si difieren, además de verificar que el
ZIP coincide con el contenido preparado y que no hay secretos. Ver
`scripts/build_zip.sh` para el detalle de qué entra y qué no.

## Actualizar el agente

1. Haz el cambio en `core/`, `modules/`, `adapters/`, `manifest.yaml` o
   `capabilities.yaml` según corresponda (ver `docs/ADDING_A_RUNTIME.md`
   si el cambio es un runtime nuevo).
2. Si editaste algo en `modules/`, corre
   `python3 scripts/generate_skills.py` para regenerar `adapters/skills/`
   — es una vista derivada (la descripción de cada Skill vive en la línea
   «Descripción de Skill:» del módulo), no una segunda fuente de verdad.
3. Si editaste algo en `core/`, actualiza el bloque de `core/compact.md` y
   corre `python3 scripts/generate_compact.py` (propaga el resumen a Codex,
   Cursor y ChatGPT/Gems; `--check` solo comprueba).
4. Si cambiaste `core/`, `adapters/skills/`, `adapters/claude-code/agents/`,
   `adapters/hooks/` o la versión de `manifest.yaml`, corre
   `python3 scripts/generate_plugin.py` para regenerar el plugin
   (`--check` solo comprueba). Los usuarios del plugin reciben la nueva versión
   cuando cambia `agent.version`: `plugin.json` la fija.
5. Corre `python3 tests/test_agent.py` y confirma que sigue en verde
   (incluye una verificación explícita de que las Skills no se
   desincronizaron de su módulo fuente).
6. Actualiza `manifest.yaml > agent.version` según la política de
   `CHANGELOG.md` (MAJOR/MINOR/PATCH) y documenta el cambio ahí; después
   vuelve a correr `python3 scripts/generate_plugin.py` (`plugin.json` lee la versión).
7. Regenera los ZIP con `scripts/build_zip.sh` (`dist` y `repo`).

## Git y control de versiones

Este repositorio es la fuente de verdad; el ZIP es un artefacto de
distribución generado a partir de él (ver `scripts/build_zip.sh`).
`.gitignore` excluye secretos, artefactos de build y configuración local de
runtimes. La CI (`.github/workflows/structural-tests.yml`) ejecuta en cada
push y pull request a `main` la suite estructural y las comprobaciones
`--check` de las vistas derivadas, sin secretos ni llamadas a modelos; el
benchmark de comportamiento sigue siendo manual (`tests/GUIA_BENCHMARK.md`). `.env.example` documenta que este proyecto en sí no requiere
variables de entorno propias (ver el archivo para el detalle sobre
servidores MCP en despliegues reales).

## Autoría

Diseñado, dirigido y validado por **Jhonny Adrian Zambrano Gonzalez**
(arquitectura, decisiones, criterios del benchmark y ejecución de las
pruebas). Desarrollado con asistencia de Claude (Anthropic) en la redacción,
la implementación de scripts y las auditorías.

## Licencia

Creative Commons Atribución-NoComercial 4.0 Internacional (CC BY-NC 4.0).
Ver `LICENSE` para el texto completo, la aclaración del autor sobre qué
cuenta como uso comercial, y cómo atribuir. Uso personal, educativo y
adaptación (incluidos adaptadores nuevos) permitidos con atribución; uso
comercial requiere licencia aparte (contacto en `LICENSE`).
