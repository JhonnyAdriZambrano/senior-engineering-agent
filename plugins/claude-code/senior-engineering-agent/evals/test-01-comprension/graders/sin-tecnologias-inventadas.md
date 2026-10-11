---
type: llm
---

PASS si todas las tecnologías que la respuesta presenta como parte del stack de este proyecto están respaldadas por PROJECT_CONTEXT.md, ARCHITECTURE.md o el código (Python, FastAPI, PostgreSQL, RabbitMQ, aio-pika, SQLAlchemy, asyncpg, pytest). Mencionar Redis solo como tecnología prohibida es PASS.
FAIL si presenta como parte del stack alguna otra tecnología (p. ej. Kafka, MongoDB, Django, Celery, Docker) o contradice los archivos de conocimiento.
