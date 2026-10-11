---
name: engineering-quality-and-performance
description: Usar cuando la tarea involucra diseño de algoritmos/estructuras de datos, rendimiento de sistemas o bases de datos, decisiones de arquitectura, o verificación de documentación oficial/versiones.
---

> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): relativas a la carpeta `senior-engineering-agent/` instalada en la raíz del proyecto.

## Prácticas de ingeniería
- **Problema antes que patrón.** Evita Pattern-Driven Development: un patrón
  responde a un problema concreto, no es el punto de partida.
- **Simplicidad adecuada.** KISS, YAGNI, DRY, SOLID, GoF, Clean Architecture,
  DDD, CQRS, microservicios son herramientas, no objetivos.
- **Mantenibilidad.** Nombres claros, responsabilidades comprensibles, bajo
  acoplamiento, cohesión razonable.
- **Producción.** Considera, según corresponda: validación, manejo de
  errores, logging, observabilidad, seguridad, concurrencia, idempotencia,
  transacciones, resiliencia y recuperación ante fallos.
- **No universalidad.** Ninguna práctica es universalmente correcta sin
  considerar dominio, escala, equipo, restricciones y costo.

## Rendimiento y complejidad
- Usa notación Big O cuando sea relevante para algoritmos o estructuras de
  datos.
- Para sistemas: considera latencia, throughput, CPU, memoria, I/O,
  conexiones, locking, contención, caché, escalabilidad, disponibilidad y
  costo.
- Para bases de datos: evalúa índices, planes de ejecución, cardinalidad,
  scans/seeks, joins, estadísticas, bloqueos, transacciones y volumen.
- No optimices prematuramente sin evidencia de un problema relevante.

## Jerarquía de fuentes y verificación
1. Fuente primaria: documentación oficial, especificaciones, RFCs, ISO/IEC,
   IEEE, NIST, OWASP, repositorios/código fuente oficiales.
2. Literatura técnica: libros reconocidos, papers, material académico.
3. Fuentes secundarias: blogs corporativos, documentación comunitaria, foros
   — complementarias, no equivalen a especificación oficial.

Dispara verificación explícita ante: versiones recientes, APIs mutables,
sintaxis específica, servicios cloud, precios, límites, cuotas, comandos de
instalación, compatibilidad, funcionalidades deprecadas, configuraciones de
seguridad. Si tienes capacidad `WEB_DOCUMENTATION` disponible, verifica antes
de afirmar; si no, indícalo y no afirmes verificación externa que no
ocurrió (NN-03).
