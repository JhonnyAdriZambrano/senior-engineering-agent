---
name: repository-workflow
description: Usar para depurar, implementar, refactorizar o revisar código en un repositorio ya existente (modos DEBUG, IMPLEMENTATION, REFACTOR, REVIEW). No usar para preguntas puramente informativas.
---

> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): relativas a la carpeta `senior-engineering-agent/` instalada en la raíz del proyecto.

## Principio
No comiences modificando código sin antes comprender el contexto suficiente
para evitar cambios incompatibles o innecesarios.

## Workflow
1. **INSPECCIONAR** — examina estructura relevante, configuración,
   dependencias, puntos de entrada, documentación, pruebas y componentes
   relacionados (capacidad `FILE_SYSTEM`/`CODE_SEARCH`).
2. **COMPRENDER** — determina cómo está implementada la funcionalidad
   actualmente, qué dependencias y restricciones existen, dónde está
   realmente el problema.
3. **PLANIFICAR** — define el cambio mínimo y suficiente; identifica
   archivos afectados, riesgos, dependencias, validaciones necesarias y
   posibles efectos secundarios.
4. **IMPLEMENTAR** — modifica únicamente lo necesario, respetando
   arquitectura, convenciones, estilo y dependencias existentes salvo razón
   técnica justificada.
5. **VALIDAR** — ejecuta, si la capacidad `TERMINAL` lo permite,
   compilación, tests, lint, análisis estático o validaciones funcionales.
6. **REPORTAR** — resume qué cambió, por qué, qué se validó, qué no pudo
   validarse, qué riesgos quedan y qué decisiones importantes se tomaron.

## Reglas complementarias
- **Cambio mínimo:** prefiere el cambio mínimo que resuelva correctamente el
  problema, sin comprometer seguridad, mantenibilidad o requisitos.
- **Dependencias:** antes de agregar una nueva, comprueba si el proyecto o
  la plataforma ya ofrece una capacidad equivalente.
- **Arquitectura existente:** no reestructures un proyecto completo para un
  problema local salvo evidencia de que la arquitectura actual es la causa
  material.
- **Código generado:** no generes archivos completos o bloques grandes
  cuando un cambio localizado sea suficiente.
