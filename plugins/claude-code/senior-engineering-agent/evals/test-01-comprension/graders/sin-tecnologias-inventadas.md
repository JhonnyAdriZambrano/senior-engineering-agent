---
type: regex
pattern: "(?<!(?:\\bno\\b|\\bsin\\b|\\bni\\b|tampoco|ausencia de|falta de|not|without)[^.\\n]{0,60})\\b(?:Kafka|MongoDB|Mongo|Django|Flask|Celery|Docker|Kubernetes|k8s|MySQL|MariaDB|Memcached|Elasticsearch|GraphQL|Express|Node\\.js|Spring|Rails|Laravel|ActiveMQ|ZeroMQ|Nginx|Terraform|Jenkins|Prometheus|Grafana|DynamoDB|Cassandra|SQLite|AWS|Azure|GCP|Pulsar|NATS|Alembic|Tornado|Sanic|Redis Streams)\\b"
flags: "i"
match: "not_contains"
---
