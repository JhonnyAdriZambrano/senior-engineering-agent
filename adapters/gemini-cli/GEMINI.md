# Senior Engineering Agent — Adaptador Gemini CLI

## Instalación (dónde colocar esta carpeta)
1. Copia la carpeta **completa** `senior-engineering-agent/` a la raíz de
   tu proyecto — los `@import` de abajo son relativos a la posición de
   este archivo dentro de esa carpeta.
2. En el `GEMINI.md` real de tu proyecto (en la raíz, fuera de
   `senior-engineering-agent/`), añade:
   `@senior-engineering-agent/adapters/gemini-cli/GEMINI.md`
3. Confirmado en la documentación oficial (`geminicli.com/docs/core/memport`):
   los `@import` de Gemini CLI se resuelven relativos al directorio del
   archivo que los contiene (`basePath`), igual que Claude Code, y
   soportan imports anidados hasta 4-5 niveles — nuestro diseño de un solo
   nivel de anidamiento es seguro.

Gemini CLI soporta `@import` igual que Claude Code, así que el núcleo se
referencia sin duplicarlo.

@../../core/00-identity.md
@../../core/01-non-negotiable-rules.md
@../../core/02-certainty-classification.md
@../../core/03-task-classification.md
@../../core/04-user-interaction.md
@../../core/05-final-priorities.md

## Interacción con el usuario en este runtime
No hay evidencia de una tool dedicada de pregunta estructurada en Gemini
CLI. Usa diálogo conversacional estándar como binding de USER_INTERACTION.

## Capacidades de este runtime
Fuente única: `../../capabilities.yaml`, columna `gemini-cli`. Gemini CLI
es cliente MCP confirmado: `WEB_DOCUMENTATION`/`EXTERNAL_TOOLS` se
resuelven vía servidores MCP configurados en `settings.json` cuando
existen.

## Si falta PROJECT_CONTEXT.md/ARCHITECTURE.md
Gemini CLI tiene comando nativo `/init`: analiza el directorio y genera un
`GEMINI.md` inicial (fuente: `geminicli.com/docs/reference/commands`, consultada el 2026-09-26). Si tu `GEMINI.md` ya tiene contenido
real, úsalo como base y no vuelvas a ejecutar `/init`; si no existe o está
vacío, recomienda `/init` primero. En ambos casos, aplica
`../../modules/project-knowledge-bootstrap.md` para el traspaso a
`PROJECT_CONTEXT.md`/`ARCHITECTURE.md`. Ese módulo nunca infiere
`DECISIONS.md`.

## Advertencia verificada sobre memoria
Gemini CLI permite `/memory add <texto>` para persistir hechos en el
`GEMINI.md` global (`~/.gemini/GEMINI.md`). Existen reportes verificados de
que hechos añadidos así no siempre son recordados de forma fiable por el
modelo. No asumas persistencia efectiva sin comprobarla — coherente con
NN-01/NN-04 del núcleo (no afirmar certeza ni evidencia sin verificación).

## Hooks deterministas (recomendado)
Fusiona `adapters/gemini-cli/settings.hooks.json` en `.gemini/settings.json`
de tu proyecto. `SessionStart` añade como contexto la comprobación del
conocimiento del proyecto y de posibles instrucciones incrustadas;
`BeforeTool` (`run_shell_command`) **bloquea** operaciones destructivas (NN-08).
Ambos llaman a `adapters/hooks/sea_hooks.py` (Python 3.8+;
geminicli.com/docs/hooks, consultada 2026-09-27). El nombre del argumento con
el comando de `run_shell_command` no está confirmado en la documentación: el
hook lo busca de forma tolerante. En uso real con Gemini CLI,
`[INCERTIDUMBRE / REQUIERE VERIFICACIÓN]`.

## Módulos condicionales: Skills
Los 7 módulos NO se importan aquí (un `@import` los cargaría en cada sesión,
también para preguntas en modo QUESTION). Se instalan como Skills: copia
cada carpeta de `senior-engineering-agent/adapters/skills/` a
`.agents/skills/` (o `.gemini/skills/`) en la raíz de tu proyecto. Gemini
CLI descubre Skills de proyecto en esas dos rutas y, al activar una, añade
su `SKILL.md` a la conversación (geminicli.com/docs/cli/skills, consultada
2026-09-26). Usa `/memory show` para ver qué quedó cargado del núcleo.
