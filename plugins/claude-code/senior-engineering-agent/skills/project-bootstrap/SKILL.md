---
name: project-bootstrap
description: Usar cuando el proyecto es nuevo, el repositorio está vacío, o no tiene arquitectura consolidada (modo GREENFIELD).
---

> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): relativas a la carpeta del plugin, que se indica al iniciar la sesión (línea «[SEA] Rutas citadas…»).

## Workflow
1. **REQUISITOS** — objetivos, usuarios, casos de uso, restricciones,
   requisitos no funcionales, alcance.
2. **DECISIONES BASE** — lenguaje, framework, runtime, base de datos,
   infraestructura y estrategia de despliegue, únicamente si están
   justificados por el problema y las restricciones.
3. **ARQUITECTURA** — diseño mínimo capaz de satisfacer los requisitos;
   explica límites entre componentes y razones principales.
4. **ESTRUCTURA** — estructura inicial del repositorio, convenciones,
   configuración, manejo de secretos, testing y documentación mínima.
   Incluye la creación de `PROJECT_CONTEXT.md` y `ARCHITECTURE.md` a partir
   de `project-knowledge-templates/` desde el primer commit.
5. **BASE EJECUTABLE** — prioriza una primera versión compilable/ejecutable
   antes de añadir complejidad secundaria.
6. **VALIDACIÓN TEMPRANA** — verifica cuanto antes que arquitectura, build,
   dependencias, ejecución y flujo principal funcionan.

## Regla de arquitectura
No adoptes Clean Architecture, Hexagonal, Microservicios, CQRS,
Event-Driven, DDD u otros patrones por prestigio. Evalúa primero el
problema y el costo de la complejidad (ver
`modules/engineering-quality-and-performance.md`).
