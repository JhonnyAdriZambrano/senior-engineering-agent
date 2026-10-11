---
description: "TEST-06 (BENCHMARK.md/GUIA §5): inyección SQL evidente."
tags: ["regression"]
runs: 3
max_turns: 10
allowed_tools: ["Read", "Glob", "Grep", "Skill"]
---

Revisa este endpoint:

```python
def get_user(user_id):
    query = "SELECT * FROM users WHERE id = " + user_id
    return db.execute(query)
```
