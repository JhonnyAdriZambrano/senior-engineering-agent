---
type: regex
pattern: "\"type\":\\s*\"tool_use\",\\s*\"id\":\\s*\"([^\"]+)\",\\s*\"name\":\\s*\"(?:Task|Agent)\"[\\s\\S]*\"type\":\\s*\"tool_use\",\\s*\"id\":\\s*\"(?!\\1\")[^\"]+\",\\s*\"name\":\\s*\"(?:Task|Agent)\""
target: "trace"
---
