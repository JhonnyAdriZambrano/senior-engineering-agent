# Especificación Técnica — Senior Engineering Agent

Especificación portable de un agente que encarna el rol de Ingeniero de
Software Senior y Arquitecto de Tecnologías de la Información Senior:
un núcleo de comportamiento modular que puede materializarse en distintos
runtimes (Claude Code, Codex, Cursor, Gemini CLI, ChatGPT Projects, Gemini
Gems) conservando su identidad, reglas, clasificación de tareas y
prioridades, adaptando únicamente las capacidades que dependen de cada
plataforma.

---

## 1. Principio de diseño: especificación compilable, no un archivo único

Un solo archivo grande que se carga completo en cada turno, sin importar la
tarea, no es la forma correcta de distribuir este agente. La evidencia que
sustenta esto:

1. **Ningún runtime real premia cargar todo siempre.** Claude Code tiene
   Skills con *progressive disclosure* (se cargan solo cuando la
   descripción coincide con la tarea). Cursor tiene cuatro modos de
   activación (`alwaysApply`, *auto attached* por glob, *agent requested*
   por descripción, manual) y documenta límites concretos: reglas
   *alwaysApply* combinadas por debajo de ~2000 tokens, archivos
   individuales por debajo de ~500 líneas. Codex recomienda mantener
   `AGENTS.md` conciso y remitir el detalle a Skills/Plugins.
2. **Markdown, no XML, es el formato nativo de todos los runtimes de
   proyecto investigados** (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `.mdc`
   de Cursor). Mantener el núcleo en un formato distinto obliga a traducir
   manualmente cada vez que cambia.
3. **Aplicar el mismo workflow a cualquier tipo de tarea produce
   comportamiento desproporcionado** (el mismo proceso de varios pasos para
   "qué hace `async/await`" que para "migra este backend"). Solo una
   estructura condicional por tipo de tarea evita esto.
4. **Dos plataformas (ChatGPT Projects, Gemini Gems) tienen límite de
   caracteres en el campo de instrucciones** y no soportan importar
   archivos externos ahí. Un núcleo grande simplemente no cabe completo.

**Consecuencia de diseño:** esta especificación es un **manifiesto +
módulos pequeños con metadatos de activación**, y no un documento único.
Un **adaptador** por plataforma **compone** (nunca duplica) esos módulos
usando el mecanismo nativo de esa plataforma.

---

## 2. Árbol de la especificación

```
senior-engineering-agent/
├── README.md                         punto de entrada para una persona nueva
├── CHANGELOG.md                       historial de versiones y política de versionado
├── SPECIFICATION.md                   este documento — contrato del agente
├── manifest.yaml                     identidad, versión, índice de módulos
├── capabilities.yaml                 capacidades abstractas → binding por runtime
├── .gitignore / .env.example          higiene de Git (sin secretos)
├── .github/workflows/structural-tests.yml  CI: suite estructural en cada push/PR (sin LLM)
│
├── core/                             siempre cargado, 100% portable
│   ├── 00-identity.md
│   ├── 01-non-negotiable-rules.md
│   ├── 02-certainty-classification.md
│   ├── 03-task-classification.md
│   ├── 04-user-interaction.md
│   ├── 05-final-priorities.md
│   └── compact.md                    DERIVADO: resumen para runtimes sin @import
│
├── modules/                          carga condicional (tipo skill)
│   ├── security.md
│   ├── engineering-quality-and-performance.md
│   ├── repository-workflow.md
│   ├── project-bootstrap.md
│   ├── scope-regression-change-control.md
│   ├── adaptive-behavior-and-referencing.md
│   └── project-knowledge-bootstrap.md
│
├── adapters/                         compone core+módulos al formato nativo
│   ├── hooks/sea_hooks.py                lógica común de los hooks; cada runtime aporta
│   │                                     su configuración (settings.hooks.json / hooks.json)
│   ├── skills/<7 módulos>/SKILL.md       GENERADAS desde modules/; se instalan en
│   │                                     .claude/skills/ (Claude Code) y en
│   │                                     .agents/skills/ (Codex, Cursor, Gemini CLI)
│   ├── claude-code/
│   │   ├── CLAUDE.md
│   │   ├── settings.hooks.json              (hooks para .claude/settings.json)
│   │   └── agents/                          (Subagents de solo lectura)
│   │       ├── repository-explorer-agent.md
│   │       ├── code-reviewer-agent.md
│   │       └── project-bootstrap-research-agent.md
│   ├── codex/
│   │   ├── AGENTS.md
│   │   └── agents/                          (los mismos 3, en .toml, sandbox read-only)
│   ├── cursor/rules/00-core-always.mdc
│   ├── gemini-cli/GEMINI.md
│   └── chatgpt-and-gems/instructions.md
│
├── .claude-plugin/marketplace.json   el repo es el marketplace del plugin de Claude Code
├── plugins/claude-code/senior-engineering-agent/   VISTA GENERADA (scripts/generate_plugin.py):
│   ├── .claude-plugin/plugin.json    versión leída de manifest.yaml
│   ├── skills/ agents/ core/         copias de adapters/skills/, adapters/claude-code/agents/, core/00-05
│   ├── hooks/hooks.json              un hook SessionStart por archivo de core/ + sea_hooks.py
│   ├── adapters/hooks/sea_hooks.py   misma ruta relativa que en la fuente (busca las plantillas
│   │                                 tres niveles por encima) y project-knowledge-templates/
│   ├── scripts/sea-python.sh         lanzador de Python (python3 | python | py -3)
│   └── evals/                        casos de `claude plugin eval` (escritos a mano, versionados)
│
├── project-knowledge-templates/      vive en cada repo real, NO es del agente
│   ├── PROJECT_CONTEXT.md
│   ├── ARCHITECTURE.md
│   ├── DECISIONS.md
│   └── ACTIVE_TASK.md
│
├── docs/
│   └── ADDING_A_RUNTIME.md            contrato para construir un adaptador nuevo
│
├── tests/                              NO se distribuye en el ZIP — herramienta de desarrollo
│   ├── test_agent.py                   validación estructural automatizada
│   ├── run_tests.sh
│   ├── BENCHMARK.md                    14 pruebas de comportamiento con criterios PASS/FAIL
│   ├── GUIA_BENCHMARK.md               procedimiento para ejecutar todas las pruebas
│   ├── results/_TEMPLATE.md            plantilla de registro de corridas
│   ├── MANUAL_SCENARIOS.md             escenarios de verificación de comportamiento real
│   ├── behavioral/run_scenarios.sh     arnés automatizado (9 de las 14, heurístico)
│   └── sandbox/setup_sandbox.sh        crea el sandbox del benchmark (estados A/B/C)
│
└── scripts/                            NO se distribuye en el ZIP
    ├── build_zip.sh                    empaquetado determinista (dist | repo)
    ├── generate_skills.py              modules/ -> SKILL.md (Claude Code y Codex)
    ├── generate_compact.py             core/compact.md -> adaptadores sin @import
    ├── generate_plugin.py              core/, adapters/, manifest.yaml -> plugin de Claude Code
    └── new_result.sh                   registro prellenado de una corrida del benchmark
```

`core/` y `modules/` son la especificación del agente — idéntica en
cualquier proyecto. `adapters/` traduce esa especificación al mecanismo
nativo de cada plataforma. `project-knowledge-templates/` no es del agente:
es la plantilla que cada repositorio concreto rellena con sus propios
hechos. `tests/` y `scripts/` son herramientas de desarrollo de este
repositorio — no se incluyen en el ZIP que un runtime consume.

---

## 3. Clasificación de componentes

| Componente | Tipo | ¿Portable? | Ubicación |
|---|---|---|---|
| Identidad y objetivo | CORE | Sí | `core/00-identity.md` |
| Reglas no negociables (NN-01 a NN-10) | CORE | Sí | `core/01-non-negotiable-rules.md` |
| Clasificación de certeza | CORE | Sí | `core/02-certainty-classification.md` |
| Clasificación de tarea | CORE | Sí | `core/03-task-classification.md` |
| Interacción con el usuario (principio) | CORE | Sí (el principio; el binding no) | `core/04-user-interaction.md` |
| Prioridades finales y forma de respuesta | CORE | Sí | `core/05-final-priorities.md` |
| Conocimiento del proyecto (contenido real) | CONOCIMIENTO | No — es del proyecto, no del agente | `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` |
| Estado de sesión / tarea activa | CONOCIMIENTO efímera | Depende del runtime | Conversación, o `ACTIVE_TASK.md` si la tarea es larga |
| Seguridad | MÓDULO | Sí | `modules/security.md` |
| Calidad de ingeniería, rendimiento, verificación | MÓDULO | Sí | `modules/engineering-quality-and-performance.md` |
| Workflow sobre repositorio existente | WORKFLOW | Sí (el disparo depende de `task_classification`) | `modules/repository-workflow.md` |
| Bootstrap de proyecto nuevo | WORKFLOW | Sí | `modules/project-bootstrap.md` |
| Control de alcance, regresión y cambios | MÓDULO | Sí | `modules/scope-regression-change-control.md` |
| Autocorrección, decisiones y referenciación | MÓDULO | Sí | `modules/adaptive-behavior-and-referencing.md` |
| Descubrimiento de conocimiento del proyecto | MÓDULO | Sí (el disparo depende de si faltan archivos de conocimiento) | `modules/project-knowledge-bootstrap.md` |
| Decisiones reales del proyecto (ADR) | CONOCIMIENTO | No | `DECISIONS.md` |
| Capacidades (herramientas) | CAPACIDAD + CONFIG | El principio sí; el binding no | `capabilities.yaml` |
| Identidad/versión del manifiesto | CONFIG | Portable como declaración; el efecto visible en UI no | `manifest.yaml` |
| Skills (vista generada de `modules/`) | ADAPTADOR (derivado) | Sí entre Claude Code, Codex, Cursor y Gemini CLI (formato SKILL.md común; cambia solo la carpeta de instalación) | `adapters/skills/` |
| Hooks deterministas (inicio de sesión: conocimiento del proyecto e instrucciones incrustadas; antes de comandos de shell: NN-08) | ADAPTADOR (enforcement) | Parcial — lógica común para Claude Code, Codex, Cursor y Gemini CLI; ChatGPT Projects y Gemini Gems no tienen hooks | `adapters/hooks/sea_hooks.py` + `settings.hooks.json`/`hooks.json` de cada adaptador |
| Subagents de solo lectura (explorador, revisor, investigación de bootstrap) | ADAPTADOR (complemento) | No — depende de que el runtime soporte subagentes con contexto propio | `adapters/claude-code/agents/`, `adapters/codex/agents/` |
| Contrato para construir un adaptador nuevo | DOCUMENTACIÓN | Sí, es agnóstico de cualquier runtime concreto | `docs/ADDING_A_RUNTIME.md` |
| Validación estructural | HERRAMIENTA DE DESARROLLO (no se distribuye) | Sí — no depende de ningún runtime, corre en cualquier máquina con Python | `tests/test_agent.py` |
| Empaquetado reproducible | HERRAMIENTA DE DESARROLLO (no se distribuye) | Sí | `scripts/build_zip.sh` |

**Regla general:** todo *principio de comportamiento* es portable; todo
*mecanismo concreto* (nombre de herramienta, formato de archivo, límite de
caracteres) es específico de plataforma y vive en el adaptador, nunca en el
núcleo.

---

## 4. Especificación de cada componente

### 4.1 `manifest.yaml` (CONFIG)
`agent.id`, `agent.name`, `agent.version`, `agent.description`,
`core_modules` (lista ordenada, siempre cargada), `conditional_modules`
(lista con `id`, `path`, `triggers`), `capabilities` (referencia a
`capabilities.yaml`), `knowledge_contract` (archivos que la especificación
espera encontrar en el proyecto, sin traerlos ella misma).

El campo `triggers` admite tres tipos de valor, semánticamente distintos y
evaluados de forma diferente por el adaptador:

| Tipo | Ejemplo | Cómo se evalúa |
|---|---|---|
| Palabra clave de tema | `auth`, `rendimiento` | Coincidencia heurística entre el contenido de la solicitud y el tema del módulo |
| Modo de tarea | `task_mode:IMPLEMENTATION` | Coincide con el modo ya determinado en `core/03-task-classification.md` |
| Contrato de conocimiento | `knowledge_contract:incomplete` | Comprobación de existencia/completitud de los archivos listados en `knowledge_contract`, evaluada una vez al inicio de sesión, no por el contenido de cada mensaje |

Solo `project-knowledge-bootstrap` usa el tercer tipo; el resto de módulos
usa los dos primeros.

### 4.2 `capabilities.yaml` (CONFIG)
Cada entrada: `name` (capacidad abstracta, ej. `USER_INTERACTION`),
`purpose`, `bindings` (mapa runtime → mecanismo concreto, o "sin binding
documentado, usar fallback conversacional"). Es el único archivo donde se
permite nombrar herramientas concretas de una plataforma.

### 4.3 `core/*.md` (CORE)
Una responsabilidad única por archivo, sin sintaxis propietaria de ninguna
plataforma. Se cargan siempre, en el orden declarado en `manifest.yaml`.

### 4.4 `modules/*.md` (MÓDULO / WORKFLOW)
Una responsabilidad única, con una cabecera que declara cuándo debe
activarse («Activar cuando:») y la descripción con que se publica como
Skill («Descripción de Skill:»). `scripts/generate_skills.py` convierte cada
módulo en un `SKILL.md` en `adapters/skills/`: el mismo archivo sirve a
Claude Code (`.claude/skills/`) y a Codex, Cursor y Gemini CLI
(`.agents/skills/`), que comparten el formato abierto Agent Skills
(documentación oficial de cada runtime, consultadas 2026-09-26). En runtimes sin Skills
(ChatGPT Projects, Gemini Gems), el módulo se sube como archivo adjunto.

**Subagents (complemento, solo lectura).** Claude Code y Codex incluyen tres
subagents sin permisos de escritura: `repository-explorer-agent`
(INSPECCIONAR/COMPRENDER y propuesta de plan), `code-reviewer-agent`
(revisión independiente, modo REVIEW) y `project-bootstrap-research-agent`
(comparación de opciones con fuentes). Implementar, ejecutar tests y decidir
quedan en el hilo principal: un subagent no puede usar la interacción
estructurada con el usuario (Claude Code, `code.claude.com/docs/en/sub-agents`),
y en tareas donde cada paso depende del anterior la información se pierde en
el traspaso. Cada subagent define un formato de salida con una sección
«Obstáculos encontrados».

### 4.5 `adapters/*` (composición)
Un adaptador no repite contenido de `core/`/`modules/`: lo referencia
(`@import` donde el runtime lo soporte) o lo comprime cuando el runtime no
soporta importación (ChatGPT Projects, Gemini Gems). Decide, por proyecto,
qué módulos se activan por defecto.

### 4.6 `project-knowledge-templates/*` (CONOCIMIENTO)
Plantillas vacías que cada proyecto real copia a su propio repositorio y
rellena. No incluyen contenido de ningún proyecto — son estructura, no
datos.

---

## 5. Descubrimiento de conocimiento del proyecto (`modules/project-knowledge-bootstrap.md`)

Cuando `PROJECT_CONTEXT.md`/`ARCHITECTURE.md` no existen o están
prácticamente vacíos, el agente no debe re-escanear el repositorio desde
cero si el runtime ya tiene una forma nativa de hacerlo (Claude Code y
Codex tienen un comando `/init` documentado que analiza el proyecto y
genera un `CLAUDE.md`/`AGENTS.md` inicial). Reimplementar ese escaneo sería
una duplicación innecesaria de una capacidad ya resuelta por la plataforma.

El único trabajo que le corresponde a este módulo — porque ningún `/init`
nativo lo hace — es el **traspaso al formato portable**:

1. Si existe un comando de inicialización nativo en este runtime,
   recomiéndalo primero (o úsalo si ya se ejecutó) y parte de su salida
   (`CLAUDE.md`/`AGENTS.md`) en vez de inspeccionar todo de nuevo. Si no
   existe (Cursor sin confirmación de equivalente, ChatGPT Projects,
   Gemini Gems), inspecciona
   directamente con las capacidades `FILE_SYSTEM`/`CODE_SEARCH`.
2. Reorganiza lo relevante hacia `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`,
   etiquetando lo inferido como `[INFERENCIA]`, nunca como
   `[HECHO VERIFICADO]`.
3. Si el archivo de destino ya tiene contenido real, no lo sobrescribas:
   propone únicamente lo que falta (análisis de huecos), nunca un
   reemplazo completo.
4. Confirma con el usuario (capacidad `USER_INTERACTION`) antes de escribir
   el resultado final — esto no es un paso adicional inventado: la propia
   documentación de `/init` recomienda revisar y ajustar lo generado antes
   de darlo por bueno.

**Exclusión explícita: `DECISIONS.md` nunca se llena por este módulo.**
Un ADR describe el *porqué* de una decisión (contexto, alternativas
consideradas, trade-offs) — eso no es observable inspeccionando código, solo
inferible con muy baja confianza, y una justificación inventada que suena
plausible es más peligrosa que no tener ninguna. `DECISIONS.md` se
inicializa vacío desde la plantilla y se llena únicamente de forma
prospectiva, cuando una decisión real se confirma durante el trabajo (ver
`modules/adaptive-behavior-and-referencing.md`). Como mucho, este módulo
puede señalar candidatos observables ("se detectó X en vez de Y — si fue
una decisión consciente, documéntala") sin redactar el porqué él mismo.

---

## 6. Decisiones necesarias para portabilidad real

1. **Separación estricta instrucción/conocimiento.** Ningún hecho
   específico de un proyecto vive en `core/` o `modules/`.
2. **Capacidades abstractas, nunca nombres de herramienta en el núcleo.**
   El núcleo declara qué capacidad necesita; el adaptador resuelve el
   binding real — el mismo principio que MCP formaliza a nivel de
   protocolo (negociar capacidades, no asumir nombres fijos), aplicado
   aquí a nivel de especificación de comportamiento.
3. **Carga condicional declarada en metadatos, no en prosa.**
   `manifest.yaml` y las cabeceras `Activar cuando:` de cada módulo deciden
   qué se carga; cada runtime lo traduce con su propio mecanismo.
4. **Formato nativo en el adaptador, formato neutro en la especificación.**
   `core/`/`modules/` se mantienen en Markdown simple; los adaptadores
   añaden lo que cada plataforma exige.
5. **Identidad declarada en un solo lugar** (`manifest.yaml` +
   `core/00-identity.md`), consumida por todos los adaptadores.
6. **Degradación explícita cuando una capacidad no tiene binding.** Si un
   runtime no puede resolver `TERMINAL` o `FILE_SYSTEM` (ChatGPT Projects,
   Gemini Gems), decláralo explícitamente; nunca simules que existe.

### Qué es realmente portable y qué no

**Portable:** que el modelo, en cualquier plataforma que cargue
`core/00-identity.md` en su contexto, adopte el mismo rol, los mismos
valores no negociables y el mismo estilo de respuesta.

**No portable, y ninguna arquitectura de instrucciones lo logra:** el
nombre visible del producto anfitrión en su interfaz (Claude Code sigue
siendo Claude Code, Codex sigue siendo Codex, sin importar qué diga
`core/00-identity.md`), ni las políticas de seguridad/aprobación propias de
esa plataforma, que este manifiesto no puede anular.

---

## 7. Matriz de compatibilidad por plataforma

| Mecanismo requerido | Claude Code | Codex | Cursor | Gemini CLI | ChatGPT Projects | Gemini Gems |
|---|---|---|---|---|---|---|
| Import de archivos externos en el núcleo | Sí (`@ruta`) | No | No directo (archivos independientes en `.cursor/rules/`) | Sí (`@ruta`) | No | No |
| Resolución de `@import` relativa al archivo importador (no al cwd ni al archivo raíz) | **Confirmado** (`docs.anthropic.com/en/docs/claude-code/memory`) | No aplica (sin import) | No aplica | **Confirmado** (`geminicli.com/docs/core/memport`) | No aplica | No aplica |
| Carga condicional real por metadatos | Sí (Skills en `.claude/skills/`; imports no) | Sí (Skills en `.agents/skills/`) | Sí (Skills en `.agents/skills/`; reglas `.mdc`) | Sí (Skills en `.agents/skills/` o `.gemini/skills/`) | No | No |
| Comando nativo de inicialización del proyecto | Sí (`/init`) | Sí (`/init`) | No confirmado | **Sí** (`/init`, genera `GEMINI.md`; `geminicli.com/docs/reference/commands`, consultada el 2026-09-26) | No aplica | No aplica |
| Subagents (contexto aislado, delegación) | Sí — usado en `adapters/claude-code/agents/` | Sí (GA, confirmado) — usado en `adapters/codex/agents/` | **Sí** (`.cursor/agents/`; por compatibilidad también `.claude/agents/` y `.codex/agents/`; campo `readonly`; `cursor.com/docs/subagents`, consultada el 2026-09-26) — sin adaptador propio: los de Claude Code no declaran `readonly`, así que en Cursor no quedan restringidos a solo lectura por mecanismo | **Sí** (`/agents`; locales en `.gemini/agents` y `~/.gemini/agents`; `geminicli.com/docs/reference/commands`, consultada el 2026-09-26) — sin adaptador en este repo todavía | No aplica | No aplica |
| Herramienta nativa de pregunta estructurada | Sí (`AskUserQuestion`) | No documentada | No confirmada | No documentada | No (conversacional) | No (conversacional) |
| Acceso a terminal/filesystem real | Sí | Sí | Sí | Sí | No | No |
| Memoria automática sin archivo | Sí (*Auto Memory*, coexiste sin conflicto — ver adaptador) | No documentada | No | Parcial (`/memory add`, con fallos reportados) | Sí (memoria de proyecto, coexiste sin conflicto — ver adaptador) | No |
| Hooks (inicio de sesión / antes de comandos) | Sí — `SessionStart` / `PreToolUse` (`ask`) | Sí — `SessionStart` / `PreToolUse` (solo `deny`; `ask` aún no soportado) | Sí — `sessionStart` / `beforeShellExecution` (`ask`) | Sí — `SessionStart` / `BeforeTool` (`deny`) | No | No |
| Protocolo de herramientas externas estandarizado | MCP (cliente y origen) | MCP (cliente) | MCP (cliente) | MCP (cliente) | MCP (apps SDK) | No |

**Plugin de Claude Code (vista generada).** Distribuye el núcleo con un hook
`SessionStart` por archivo de `core/` (matchers `startup`, `clear`, `compact`),
porque la salida de un hook se limita a 10.000 caracteres
(`code.claude.com/docs/en/hooks`). Todos los hooks que coinciden con un evento
corren en paralelo y la documentación no garantiza su orden: el orden de
llegada de las seis partes del núcleo (y del aviso de `session-start`) **no está
garantizado**. Cada parte lleva la cabecera `[Núcleo SEA — parte X de 6 (orden
canónico 00→05): <archivo>]` para que el modelo la reconstruya en el orden
canónico. A diferencia de `@import`, no hay un solo bloque contiguo. La fuente
única sigue siendo `core/`, `modules/`, `adapters/` y `manifest.yaml`.

---

## 8. Seguridad

Tres riesgos identificados durante la auditoría de primer uso, ya
mitigados en el núcleo y en `modules/security.md` (propagado a la Skill
`security` generada en `adapters/skills/`):

1. **Contenido inyectado en archivos de conocimiento del proyecto.**
   `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`/`DECISIONS.md` son fuente de
   verdad sobre *hechos*, pero cualquiera con acceso de escritura al
   repositorio puede modificarlos. NN-06b (`core/01-non-negotiable-rules.md`)
   exige tratar cualquier contenido que se lea como instrucción dirigida al
   agente (no como un hecho del proyecto) con sospecha, nunca con la
   autoridad de una regla del núcleo.
2. **Riesgo de servidores MCP.** `capabilities.yaml` recomienda MCP para
   `WEB_DOCUMENTATION`/`EXTERNAL_TOOLS`. La investigación de este proyecto
   documentó la divulgación de OX Security (abril de 2026) sobre RCE por
   diseño en el transporte STDIO de MCP: ~7.000 servidores públicos
   confirmados y una estimación extrapolada de hasta ~200.000 instancias
   (Anthropic lo considera comportamiento esperado; respondió actualizando
   documentación). `modules/security.md` cita la fuente, exige preferir
   servidores oficiales y no asumir que "está en la configuración" implica
   seguridad.
3. **Datos sensibles en archivos versionados.** Las plantillas de
   `project-knowledge-templates/` incluyen advertencias explícitas contra
   pegar credenciales, tokens o datos personales, dado que esos archivos
   suelen versionarse junto con el proyecto real.

Ningún hallazgo de seguridad de la auditoría quedó sin mitigar en el
núcleo. La tabla de re-auditoría original era un documento de proceso
externo que ya no existe; las mitigaciones están en el núcleo
(`core/01`, NN-05 y NN-06b) y en `modules/security.md`.

## 9. Próximos pasos

Estado (versión 1.0.0; puerta de salida cumplida el 2026-10-09):
instalación documentada por runtime, Skills generadas y compartidas por
Claude Code, Codex, Cursor y Gemini CLI, Subagents de solo lectura, tests
estructurales, script de sandbox para el benchmark, núcleo compacto
sincronizado con los adaptadores sin `@import`, empaquetado determinista,
README y CHANGELOG. La etiqueta 1.0.0 se asignó al cumplir la
"Puerta de salida hacia 1.0.0" de `CHANGELOG.md`. Lo que sigue pendiente:

1. **Validación de comportamiento real contra un runtime.** Los tests de
   `tests/test_agent.py` son estructurales (estáticos). El benchmark de
   `tests/BENCHMARK.md` (14 pruebas) tiene un arnés automatizado parcial
   (`tests/behavioral/run_scenarios.sh`, 9 de 14, heurístico) que requiere
   endurecerse antes de fiarse de sus PASS. Las 14 pruebas deben
   ejecutarse en sandbox, registrarse en `tests/results/` y quedar todas en
   PASS (definición completa en la «Puerta de salida hacia 1.0.0» de
   `CHANGELOG.md`). Estado a 2026-10-09 (ronda 3): 16/16 ítems de pruebas de
   la puerta cumplidos; el detalle está en `CHANGELOG.md` («Estado de la puerta»).
   Los registros de las corridas son locales y no se versionan.
2. **Capa de enforcement determinista** (hooks): implementados el
   2026-09-27 el hook de inicio de sesión (conocimiento del proyecto y
   posibles instrucciones incrustadas) y el previo a comandos de shell
   (NN-08), con lógica común para Claude Code, Codex, Cursor y Gemini CLI y
   pruebas sin LLM; solo Claude Code está validado en uso real. Pendiente:
   el hook `Stop` en Codex, Cursor y Gemini CLI (solo implementado en
   Claude Code; su equivalente está por verificar con fuente primaria), la
   validación en uso real de los otros tres runtimes y la comparativa con y sin hooks
   (`prepare_test.sh --sin-hooks`).
3. **Confirmar con fuente primaria** el `/init`-equivalente de Cursor (hoy
   `[INCERTIDUMBRE]` en `modules/project-knowledge-bootstrap.md` y «No
   confirmado» en la matriz §7). Subagents de Cursor (`.cursor/agents/`) y
   `/init` y `/agents` de Gemini CLI ya están confirmados en §7 (consultas
   del 2026-09-26); falta decidir si se crean adaptadores de subagents para
   ellos. Pendiente de confirmar: /init en Cursor.
4. Rellenar `project-knowledge-templates/` con los hechos reales de un
   proyecto concreto y verificar en la práctica que el agente los respeta
   como fuente de verdad (validación de comportamiento, no de estructura).
