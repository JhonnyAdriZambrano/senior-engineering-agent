# Módulo: Descubrimiento de conocimiento del proyecto
Descripción de Skill: Usar cuando PROJECT_CONTEXT.md y/o ARCHITECTURE.md no existen o están vacíos/con placeholders al iniciar sesión en un proyecto existente, o el usuario pide inicializar/actualizar el conocimiento del proyecto.
Activar cuando: `PROJECT_CONTEXT.md` y/o `ARCHITECTURE.md` no existen o
están vacíos/con placeholders al iniciar una sesión en un proyecto
existente, o el usuario lo pide explícitamente.

**Reparto de responsabilidades.** La comprobación inicial y la mención breve
(una sola vez, una línea) viven en `core/00-identity.md`, que se carga
siempre; este módulo aporta el procedimiento completo de descubrimiento una
vez que el usuario lo pide o lo confirma.

**Esta condición depende únicamente de `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`
— no de si `CLAUDE.md`/`AGENTS.md` ya tiene contenido.** Que ya exista un
`CLAUDE.md` con información real (de un `/init` corrido antes de instalar
este agente, de uno corrido ahora, o escrito a mano por alguien del
equipo) **no** significa que el conocimiento portable esté completo, ni es
motivo para no activar este módulo. Mientras ese conocimiento solo viva en
`CLAUDE.md`, queda atrapado en un formato específico de Claude Code — si
el mismo proyecto se despliega después en Codex, Cursor o Gemini CLI, esos
adaptadores no tienen forma de leerlo. El traspaso a formato portable
sigue haciendo falta aunque `CLAUDE.md` ya "conteste bien" por sí solo.

## Principio: no reimplementar lo que la plataforma ya hace bien
Antes de inspeccionar nada por cuenta propia, comprueba si este runtime
tiene un comando nativo de inicialización de proyecto (por ejemplo `/init`
en Claude Code o Codex, que ya analiza el código y genera un
`CLAUDE.md`/`AGENTS.md` inicial). Si existe, recomiéndalo o parte de su
salida. El trabajo propio de este módulo es únicamente el **traspaso al
formato portable** que ningún comando nativo produce.

## Procedimiento
0. **No bloquees trabajo real ya solicitado, pero tampoco omitas la
   mención.** Si el usuario ya llegó con una tarea técnica específica
   antes de que hayas hecho esta verificación, no antepongas el
   descubrimiento completo como un desvío que retrasa esa tarea —
   respóndela con normalidad, y añade, en una sola línea (al inicio o al
   final, lo que interrumpa menos), que `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`
   no existen y que puedes generarlos si se confirma. Esto aplica **incluso
   si el proyecto define un formato de salida propio y estricto** (por
   ejemplo, en su `CLAUDE.md`): añade la nota aunque no encaje en ninguna
   de las secciones definidas por ese formato — una nota breve fuera de
   formato es preferible a omitir la alerta por completo. Lo que nunca es
   aceptable es completar una sesión entera de trabajo real sin haberlo
   mencionado ni una sola vez.
1. **Verificar contrato de conocimiento.** Comprueba `knowledge_contract`
   en `manifest.yaml`: ¿existen `PROJECT_CONTEXT.md`/`ARCHITECTURE.md` con
   contenido real (no solo la plantilla vacía)?
2. **Obtener la base.** Tres casos distintos, en este orden de preferencia:
   - **`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` ya existe con contenido real** (sin
     importar si se generó antes o después de instalar este agente, con
     `/init` o a mano): léelo y úsalo directamente como insumo. No vuelvas
     a ejecutar `/init` — sería trabajo redundante sobre algo que ya
     existe.
   - **`CLAUDE.md`/`AGENTS.md`/`GEMINI.md` no existe, o existe pero está vacío**: si
     el runtime tiene comando nativo de inicialización, recomiéndalo o
     ejecútalo primero.
   - **No hay comando nativo disponible en este runtime**: inspecciona
     directamente con `FILE_SYSTEM`/`CODE_SEARCH` (manifiestos de
     dependencias, estructura de carpetas, README, CI).
3. **Redactar el borrador.** Rellena `PROJECT_CONTEXT.md`/`ARCHITECTURE.md`
   a partir de la plantilla. Todo lo inferido se marca `[INFERENCIA]`,
   nunca `[HECHO VERIFICADO]` (ver `core/02-certainty-classification.md`).
4. **No sobrescribir conocimiento existente.** Si el archivo ya tiene
   contenido real, este módulo pasa a modo "análisis de huecos": propone
   solo lo que falta, nunca reemplaza lo ya escrito.
5. **Confirmar antes de escribir.** Usa la capacidad `USER_INTERACTION`
   para presentar el borrador y obtener confirmación antes de guardarlo
   como fuente de verdad del proyecto.

## Exclusión explícita — `DECISIONS.md`
Este módulo **nunca** redacta ni infiere el contenido de `DECISIONS.md`.
El porqué de una decisión (contexto, alternativas, trade-offs) no es
observable inspeccionando código, solo especulable con baja confianza, y
una justificación inventada que suena creíble es más dañina que no tener
ninguna. `DECISIONS.md` se inicializa vacío desde la plantilla; se llena
solo de forma prospectiva, cuando una decisión real se confirma durante el
trabajo (`modules/adaptive-behavior-and-referencing.md`). Como máximo,
señala candidatos observables para que el usuario los documente él mismo
("se detectó X en vez de Y — si fue una decisión consciente, sería un buen
ADR"), sin proponer el razonamiento.

## Nota de compatibilidad
Comando nativo de inicialización confirmado en Claude Code y Codex
(`/init`, genera `CLAUDE.md`/`AGENTS.md`) y en Gemini CLI (`/init`, genera
`GEMINI.md`; fuente: `geminicli.com/docs/reference/commands`, consultada el 2026-09-26). No confirmado para Cursor — tratar como
`[INCERTIDUMBRE / REQUIERE VERIFICACIÓN]` y usar el respaldo de inspección
directa. No aplica a ChatGPT Projects ni Gemini
Gems (sin sistema de archivos real).
