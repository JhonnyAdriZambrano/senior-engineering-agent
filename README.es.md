# Senior Engineering Agent

🇬🇧 **English version: [README.md](README.md)** — 🇪🇸 Este archivo es la versión en español.

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
- **En Windows**: el plugin de Claude Code ejecuta sus hooks con **Git Bash**
  (`plugins/claude-code/senior-engineering-agent/scripts/sea-python.sh` es un script de bash). El repositorio incluye un
  `.gitattributes` (`* text=auto eol=lf`) que fuerza fin de línea LF en la
  copia de trabajo aunque `core.autocrlf=true`; sin él, los `.sh` quedarían
  con CRLF y fallarían con «$'\r': command not found». Si ya clonaste antes de
  que existiera, ejecuta `git add --renormalize . && git checkout -- .` (o
  vuelve a clonar). `tests/test_agent.py` comprueba el LF y el bit de
  ejecución de los `*.sh` en el índice de git (no en el sistema de archivos).

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
├── README.md                    README completo en inglés (portada del repositorio)
├── README.es.md                 este archivo (español)
├── CHANGELOG.md                 historial de versiones y política de versionado
├── SPECIFICATION.md             arquitectura completa, contrato del agente
├── LICENSE                      Apache-2.0 (texto oficial íntegro)
├── NOTICE                       aviso de copyright y de la licencia
├── PRIVACY.md                   política de privacidad (enlazada desde plugin.json)
├── SECURITY.md                  qué es una vulnerabilidad y cómo reportarla en privado (inglés)
├── CONTRIBUTING.md              cómo contribuir: fuente única frente a vistas generadas (inglés)
├── manifest.yaml                identidad, versión, índice de módulos
├── capabilities.yaml            capacidades abstractas → binding por runtime
├── .gitattributes               fin de línea LF (portabilidad en Windows)
├── .gitignore                   higiene de Git (secretos, builds, resultados)
├── .github/
│   ├── ISSUE_TEMPLATE/          plantillas: error y falso positivo/negativo de los hooks
│   └── workflows/
│       └── structural-tests.yml CI: suite estructural, --check y guarda de versión en Linux y Windows (sin LLM)
├── .claude-plugin/
│   └── marketplace.json         el repo es el marketplace del plugin de Claude Code
├── core/                        6 archivos siempre cargados + compact.md
│                                (resumen DERIVADO para runtimes sin @import)
├── modules/                     7 módulos de carga condicional
├── adapters/                    un directorio por runtime soportado
│   ├── skills/                  7 Skills (SKILL.md) GENERADAS desde modules/,
│   │                            compartidas por Claude Code, Codex, Cursor y Gemini CLI
│   ├── hooks/
│   │   ├── sea_hooks.py         lógica común de los hooks (Claude Code, Codex, Cursor, Gemini CLI)
│   │   └── i18n.json            idiomas, rol en inglés y etiquetas es→en (GENERADO desde manifest.yaml > i18n)
│   ├── claude-code/             CLAUDE.md + agents/ (2 Subagents de solo lectura)
│   │                            + settings.hooks.json (hooks SessionStart, PreToolUse y Stop)
│   ├── codex/                   AGENTS.md + hooks.json + agents/ (3 Subagents de solo lectura;
│   │                            el explorador, sin medir)
│   ├── cursor/                  hooks.json + rules/ (regla alwaysApply con el núcleo compacto)
│   ├── gemini-cli/              GEMINI.md + settings.hooks.json
│   └── chatgpt-and-gems/        instrucciones comprimidas + archivos adjuntos
├── plugins/
│   └── claude-code/
│       └── senior-engineering-agent/   plugin de Claude Code GENERADO (scripts/generate_plugin.py)
│           ├── .claude-plugin/
│           │   └── plugin.json  nombre, versión, keywords, icon y el userConfig de idioma (de manifest.yaml)
│           ├── icon.png         icono del plugin (copia de adapters/claude-code/icon.png)
│           ├── LICENSE          copia de la licencia
│           ├── NOTICE           copia del aviso
│           ├── core/            copia de core/00-05
│           ├── skills/          copia de adapters/skills/
│           ├── agents/          copia de adapters/claude-code/agents/
│           ├── hooks/
│           │   └── hooks.json   un SessionStart por archivo de core/, más PreToolUse y Stop
│           ├── adapters/
│           │   └── hooks/
│           │       ├── sea_hooks.py  misma ruta relativa que en la fuente
│           │       └── i18n.json     copia de adapters/hooks/i18n.json
│           ├── project-knowledge-templates/  plantillas que el hook SessionStart necesita
│           ├── scripts/
│           │   └── sea-python.sh  lanzador de Python (python3 | python | py -3)
│           └── evals/           casos de `claude plugin eval` (escritos a mano, versionados)
│               └── README.md    qué se automatiza y criterio → grader
├── project-knowledge-templates/ plantillas que copias a TU proyecto real
├── docs/
│   ├── ADDING_A_RUNTIME.md      contrato para construir un adaptador nuevo
│   └── MEASUREMENTS.md          mediciones auditadas (regresión, ablación del núcleo y la sesión de 1.2.0): tablas, procedencia y limitaciones
├── tests/                       validación estructural + evaluación de comportamiento
│   ├── test_agent.py            validación estructural (nivel 1, sin LLM)
│   ├── run_tests.sh             punto de entrada de test_agent.py
│   ├── BENCHMARK.md             14 pruebas formales, criterios PASS/PARTIAL/FAIL
│   ├── GUIA_BENCHMARK.md        CÓMO ejecutar todas las pruebas (empieza aquí)
│   ├── MANUAL_SCENARIOS.md      escenarios narrativos de verificación manual
│   ├── acceptance/              hooks_practice.sh: aceptación práctica de los hooks con el lanzador real (sin LLM)
│   ├── fixtures/                sea_hooks_1.1.2.py: copia congelada del hook de 1.1.2 (prueba de identidad byte a byte del modo «es»)
│   ├── sandbox/                 crea el sandbox del benchmark (estados A/B/C)
│   └── results/                 registros de corridas (plantilla _TEMPLATE.md)
└── scripts/
    ├── build_zip.sh             empaquetado determinista (dist | repo)
    ├── generate_skills.py       modules/ -> adapters/skills/ (--check solo comprueba)
    ├── generate_compact.py      core/compact.md -> adaptadores sin @import (--check)
    ├── generate_plugin.py       core/, adapters/ y manifest.yaml -> plugin de Claude Code (--check)
    ├── eval.sh                  evaluación automatizada con `claude plugin eval` (smoke|regression|capability|all)
    ├── ablate_core.sh           ablación del núcleo: sin core/02…05 sobre 11 casos (`completo|sin-02|sin-03|sin-04|sin-05`)
    ├── eval_report.py           informe de una corrida de eval.sh (WITH / W/OUT / Δ)
    ├── eval_summary.py          resumen por caso de uno o varios result.json (excluye graders `arm: with-only`; sin coste de modelo)
    ├── check_version_guard.py   guarda de versión de la CI: si el plugin cambió desde la última etiqueta `v*`, plugin.json.version debe cambiar
    ├── check_results.py         resume tests/results/ y el estado de la puerta (benchmark manual de 1.0.0)
    └── new_result.sh            crea el registro prellenado de una corrida del benchmark
```

## Estado de validación por runtime

| Runtime | Estado | Qué significa |
|---|---|---|
| Claude Code | **validado** | Evaluado en uso real con `claude plugin eval` y el benchmark (`tests/results/`, `CHANGELOG.md`). |
| Codex | pendiente de validar | Adaptador y hooks probados sin LLM; sin ejecución real todavía. |
| Gemini CLI | sin validar en uso real | Solo pruebas estructurales. |
| Cursor | sin validar en uso real | Solo pruebas estructurales. |
| ChatGPT Projects / Gemini Gems | sin validar en uso real | Instrucciones comprimidas; sin ejecución real. |

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
El plugin trae las 7 Skills, los 2 Subagents de solo lectura, el núcleo
(inyectado al iniciar la sesión por un hook `SessionStart` por cada archivo de
`core/`) y los hooks deterministas (`SessionStart`, `PreToolUse` y `Stop`); no hace
falta tocar `CLAUDE.md` ni copiar nada. Es una **vista generada** (`plugins/claude-code/senior-engineering-agent/`,
`python3 scripts/generate_plugin.py`), no una segunda fuente de verdad. Los
hooks de Python usan un lanzador que prueba `python3`, `python` y `py -3`
y fuerza UTF-8 (`PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`); los hooks leen stdin como UTF-8 y
emiten JSON ASCII, y NN-08 pide confirmación (fail-closed) si no puede analizar el comando o no hay un intérprete de Python que funcione.
En Windows se recomienda Git Bash para los hooks. Los hooks de un mismo evento
corren en paralelo y la documentación no garantiza su orden: cada parte del
núcleo lleva la cabecera «[Núcleo SEA — parte X de 6 (orden canónico 00→05)]».
Detalle y límites: `adapters/claude-code/CLAUDE.md`.

**Idioma (es/en).** Desde 1.2.0 el plugin trae un selector `language` (`es` por
defecto, `en`) en `userConfig`: aparece en `/config` → *senior-engineering-agent*
(**requiere Claude Code ≥ v2.1.271**; con una versión anterior el plugin no carga,
porque declara `options`). En modo `en` el agente responde en inglés, usa el rol
«Senior Software Engineer and Senior Information Technology Architect» y las
etiquetas en inglés (`[VERIFIED FACT]`, `[TECHNICAL RECOMMENDATION]`…), y los
mensajes de los hooks (diálogo NN-08, alertas NN-06b, avisos de Stop) también
salen en inglés. El núcleo normativo sigue en español (fuente de verdad). Los
hooks reciben el valor en `CLAUDE_PLUGIN_OPTION_LANGUAGE`; otros runtimes pueden usar
`SEA_LANGUAGE=en`. Precedencia: `CLAUDE_PLUGIN_OPTION_LANGUAGE` → `SEA_LANGUAGE` →
`es`. Cambia el valor y abre una sesión nueva. [HECHO VERIFICADO con Claude Code
2.1.296] Mientras no elijas un valor, el hook no recibe la variable y se comporta
como `es`. Detalle: `SPECIFICATION.md` §7.

**Stop y la documentación.** Si lo único que editas en un turno son archivos
`.md`, `.markdown`, `.txt`, `.rst` o `.adoc`, el hook `Stop` no exige validación
(un solo archivo de otro tipo, o un destino que no pueda determinar, mantiene la
exigencia).

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
   para habilitar los 2 Subagents de solo lectura (revisor e investigación
   de bootstrap; el explorador se retiró: no se midió un beneficio frente al modelo solo).
5. Recomendado: copia `adapters/claude-code/settings.hooks.json` a
   `.claude/settings.json` (o fusiónalo) para activar los hooks
   deterministas: aviso de conocimiento faltante al iniciar la sesión
   (`SessionStart`), confirmación obligatoria de operaciones destructivas
   (`PreToolUse`, en Claude Code sobre `Bash` y `PowerShell`) y exigencia de validar los cambios al terminar el turno
   (`Stop`). Requiere Python 3.8+.
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
- Los hooks son heurísticos. NN-08 compara con una lista fija de operaciones
  destructivas tras normalizar la ruta y las opciones globales de git
  (`/usr/bin/git`, `git.exe`, `git -C dir`) y las opciones largas; no resuelve
  alias de shell o de git, variables (`$GIT reset --hard`), funciones ni
  scripts, y también analiza el texto entre comillas (`echo "git reset --hard"`
  pide confirmación a propósito). Es una capa adicional, no un sandbox.
- Ver `SPECIFICATION.md §6` y `§7` para el detalle completo de qué es
  portable, qué es adaptable y qué depende fuertemente de una plataforma.

## Mediciones

Resultados auditados (regresión del 2026-10-11, test-09 con pytest, ablación del núcleo, capacidad y coste de contexto), con su procedencia y sus limitaciones: [`docs/MEASUREMENTS.md`](docs/MEASUREMENTS.md).
Resumen: Δ medio +0,41 sobre 16 casos (regresión del 2026-10-11, `claude-sonnet-5-5`), los 4 críticos a pass^3; coste de contexto ≈ 6k tokens por evento de sesión [estimación].

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
la evaluación automatizada con `scripts/eval.sh` (vigente, ver abajo).
Ambos niveles son
screening, no un oráculo — revisa `tests/MANUAL_SCENARIOS.md`
para el detalle narrativo de cada caso. **Procedimiento paso a paso (sandbox,
fixtures, repeticiones, qué PASS del script no creer aún):
`tests/GUIA_BENCHMARK.md`.**

**Evaluación automatizada (`claude plugin eval`).** `bash scripts/eval.sh <smoke|regression|all>` ejecuta los casos de
`plugins/claude-code/senior-engineering-agent/evals/` (13 casos del benchmark automatizados total o parcialmente, más 2 indicadores del
núcleo) y mide el valor del agente frente al modelo solo (Δ). Requiere `bubblewrap` y `socat` (WSL2 en Windows) y consume plan o API; los
resultados van a `tests/results/evals/` (no se versiona). Qué se automatiza, qué es manual y la tabla criterio → grader:
`plugins/claude-code/senior-engineering-agent/evals/README.md`;
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
push y pull request a `main`, en Linux y en Windows, la suite estructural, la
aceptación práctica de hooks (`tests/acceptance/hooks_practice.sh`) y, en Linux,
las comprobaciones `--check` de las vistas derivadas, sin secretos ni llamadas a modelos; el
benchmark de comportamiento se automatiza con `scripts/eval.sh` (requiere una cuenta de Claude Code, por eso no corre en la CI; ver `tests/GUIA_BENCHMARK.md`). Este proyecto en sí no requiere
variables de entorno propias.

## Autoría

Diseñado, dirigido y validado por **Jhonny Adrian Zambrano Gonzalez**
(arquitectura, decisiones, criterios del benchmark y ejecución de las
pruebas). Desarrollado con asistencia de Claude (Anthropic) en la redacción,
la implementación de scripts y las auditorías.

## Licencia

**Apache License 2.0** desde la versión 1.2.1 (`LICENSE` con el texto oficial íntegro y `NOTICE` con el aviso de copyright). Permite uso, modificación y redistribución, también comercial,
conservando la licencia y el aviso. **Las versiones hasta la 1.2.0 inclusive se publicaron bajo CC BY-NC 4.0** y conservan esa licencia.

## Apoyo

El proyecto es gratuito y abierto. Bajo petición ofrezco servicios de adaptación del agente a stacks de empresa, soporte y formación.
Contacto: abre un Issue en el repositorio.

Apoya el proyecto en [GitHub Sponsors](https://github.com/sponsors/JhonnyAdriZambrano).
