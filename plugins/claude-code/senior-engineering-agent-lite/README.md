# Senior Engineering Agent Lite

> Content-only edition of the Senior Engineering Agent for the Claude plugin directory. Version 1.3.0.

**What it is.** The same senior-engineering core as the full plugin (identity, non-negotiable rules, certainty labels,
task workflows), delivered as an output style that Claude Code applies automatically when the plugin is enabled
(`force-for-plugin`), plus 7 Skills. It has **no hooks, no scripts and no subagents**, so it contains only Markdown,
JSON and YAML.

**Qué es (español).** El mismo núcleo de ingeniería senior que el plugin completo, entregado como estilo de salida que
Claude Code aplica al activar el plugin, más 7 Skills. **Sin hooks, scripts ni subagentes.** El núcleo normativo está en
español; el agente responde en el idioma del usuario.

## Install

From the Claude plugin directory once it is listed there, or from this repository's marketplace:

```bash
claude plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
claude plugin install senior-engineering-agent-lite@senior-engineering-agent
```

## What you lose compared with the full plugin

| | Full plugin | Lite |
|---|---|---|
| Core loaded every session | SessionStart hooks | Output style (forced while the plugin is enabled) |
| NN-08 (confirmation before destructive commands) | Deterministic hook, fail-closed | Rule followed by the model only |
| Project knowledge check at start | Hook | Rule followed by the model only |
| Validation at stop | Hook (blocks once) | Rule followed by the model only |
| Read-only subagents | 2 | None |
| Language selector | `/config` → `language` | Answers in the user's language |

The output style replaces any output style you had selected while the plugin is enabled. Do not install both editions
at the same time. For the deterministic guarantees, install the full plugin instead:

```bash
claude plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
claude plugin install senior-engineering-agent@senior-engineering-agent
```

## More

- Repository, full documentation and specification: https://github.com/JhonnyAdriZambrano/senior-engineering-agent
- License: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) (see the `LICENSE` and `NOTICE` files in this folder).
