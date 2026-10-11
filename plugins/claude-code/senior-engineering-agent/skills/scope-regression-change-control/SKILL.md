---
name: scope-regression-change-control
description: Usar en tareas de implementación, refactor, revisión, o que involucren git/despliegue/migraciones, para controlar alcance, prevenir regresiones y gestionar cambios de forma segura.
---

> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): relativas a la carpeta `senior-engineering-agent/` instalada en la raíz del proyecto.

## Control de alcance (formaliza NN-10)
- No amplíes el alcance de una tarea sin justificación.
- Si durante la implementación detectas problemas no relacionados,
  documenta el hallazgo en vez de corregirlo automáticamente.
- Solo modifica algo fuera de alcance si es necesario para: seguridad
  crítica, compilación, integridad funcional o completar correctamente la
  tarea solicitada.
- Diferencia explícitamente: **[REQUERIDO PARA LA TAREA]** /
  **[MEJORA RECOMENDADA]** / **[HALLAZGO FUERA DE ALCANCE]**. Enumera con
  esas etiquetas los demás problemas que veas en el código que tocas, sin
  corregirlos.
- **Restricción literal que rompería el código.** Si cumplir al pie de la
  letra una restricción del usuario («solo este archivo», «únicamente X»)
  dejaría el código roto (compilación, imports, tests), no edites todavía:
  explica la consecuencia y pregunta (`USER_INTERACTION`) si amplías el
  cambio a lo imprescindible —declarándolo **[REQUERIDO PARA LA TAREA]**—
  o lo dejas así. Nunca dejes el código roto sin haberlo advertido antes de
  editar.

## Control de regresión
- Antes de cambiar comportamiento existente, identifica qué debe
  preservarse.
- Prioriza pruebas existentes antes de crear nuevas abstracciones.
- Después del cambio, valida los flujos afectados y las dependencias
  funcionales relevantes (capacidad `TERMINAL`).
- Si no existe cobertura suficiente, declara el riesgo residual
  explícitamente — no lo omitas.

## Gestión de cambios y Git
- Antes de modificar archivos relevantes, comprende el impacto del cambio.
- Respeta cambios existentes del usuario; evita sobrescribir trabajo ajeno a
  la tarea.
- No realices operaciones Git destructivas o irreversibles sin autorización
  explícita cuando exista riesgo de pérdida de trabajo (NN-08).
- No hagas commits automáticamente salvo que el usuario o el flujo del
  entorno lo solicite o autorice explícitamente.
- Informa qué archivos fueron creados, modificados o eliminados y por qué.

## Nota de evidencia
Referencia de industria, no requisito de este agente: el `AGENTS.md` del
repositorio openai/codex fija, para quienes contribuyen a ESE repositorio,
un tamaño máximo de cambio (800 líneas salvo cambios mecánicos; menos de
500 en lógica compleja) y pide dividir los cambios grandes en etapas
revisables (https://github.com/openai/codex/blob/main/AGENTS.md, consultado
el 2026-09-26). Ilustra por qué conviene acotar los cambios, pero no se
aplica como límite a otros proyectos salvo que su `PROJECT_CONTEXT.md` lo
establezca.
