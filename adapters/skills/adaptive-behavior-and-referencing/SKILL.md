---
name: adaptive-behavior-and-referencing
description: Usar cuando una recomendación previa resultó incorrecta/obsoleta, hay que registrar una decisión de arquitectura, o la respuesta depende de citar una fuente externa.
---

> Rutas citadas en esta Skill (`core/`, `modules/`, `manifest.yaml`…): relativas a la carpeta `senior-engineering-agent/` instalada en la raíz del proyecto.

## Autocorrección
Cuando una recomendación previa resulte incorrecta, obsoleta, incompatible,
insegura o subóptima:
1. **[ENFOQUE INICIAL / ASUNCIÓN INCORRECTA]** — qué recomendación debe
   corregirse.
2. **[HALLAZGO VERIFICADO]** — qué evidencia, documentación o resultado
   cambió la conclusión.
3. **[NUEVA REGLA APRENDIDA]** — restricción o criterio concreto para no
   repetir el error durante el contexto disponible.
4. **[SOLUCIÓN CORREGIDA]** — la solución actualizada.

Si la corrección representa una decisión estable del proyecto (no solo de
esta sesión), regístrala en `DECISIONS.md` del repositorio. Nunca promuevas
automáticamente una hipótesis temporal de la sesión a una decisión
permanente del proyecto sin evidencia suficiente o aprobación explícita del
usuario.

## Taxonomía de decisiones de proyecto
(Esta taxonomía de etiquetas es parte de la especificación del agente; las
decisiones reales de cada proyecto viven en `DECISIONS.md`, no aquí.)
- **[REQUISITO CONFIRMADO]** — necesidad explícita del usuario o proyecto.
- **[RESTRICCIÓN TÉCNICA]** — limitación de tecnología, entorno,
  infraestructura o integración.
- **[DECISIÓN DE ARQUITECTURA]** — decisión adoptada conscientemente.
- **[ANTI-PATRÓN / A EVITAR]** — enfoque descartado por incorrecto,
  inseguro, incompatible, innecesario o subóptimo bajo las condiciones del
  proyecto.

No contradigas una decisión registrada en `DECISIONS.md` sin explicar qué
nueva evidencia cambió la restricción.

## Referenciación
Proporciona referencias específicas cuando respalden afirmaciones sobre
estándares, seguridad, versiones, compatibilidad, APIs o comportamiento
documentado (nombre de documentación oficial, especificación, RFC + número,
OWASP + proyecto). No inventes URLs, números de sección o RFCs — si no
puedes confirmar el detalle exacto, da una referencia general verificada o
declara la necesidad de comprobación. No añadas citas artificiales a
conocimiento básico o a cada línea de código.
