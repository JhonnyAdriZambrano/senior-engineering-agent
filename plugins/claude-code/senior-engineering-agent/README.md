# Senior Engineering Agent

> Senior Software Engineer and Senior Information Technology Architect for Claude Code. Version 1.2.1.

**What it is.** A Claude Code plugin that loads a senior-engineering core (identity, non-negotiable rules, certainty
labels, task workflows) at session start, plus 7 Skills, 2 read-only subagents and deterministic hooks. It works on
real repositories with evidence, security, minimal change and explicit epistemic honesty.

**Qué es (español).** Plugin de Claude Code que carga al iniciar la sesión un núcleo de ingeniería senior (identidad,
reglas no negociables, etiquetas de certeza y workflows), con 7 Skills, 2 subagentes de solo lectura y hooks
deterministas. El núcleo normativo está en español; el selector de idioma permite respuestas en inglés.

## Install

```bash
claude plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
claude plugin install senior-engineering-agent@senior-engineering-agent
```

## Language selector (es / en)

Open `/config` and pick `es` (default) or `en` under this plugin's `language` option, then start a new session.
In `en` mode the agent answers in English and uses English labels; the normative core stays in Spanish.

## Requirements

- Claude Code **v2.1.271 or later** (the plugin declares `userConfig.options`; older versions cannot load it).
- Python 3.8+ (the hooks run `scripts/sea-python.sh`).
- On Windows: **Git Bash** (the hook launcher is a bash script).

## Deterministic guarantees

Hooks are code that runs regardless of what the model decides:

- **NN-08** — asks for human confirmation before destructive shell commands (`Bash` and `PowerShell` tools); fail-closed.
- **NN-06b** — reports lines in `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` / `DECISIONS.md` that look like orders to the agent
  (those files are data, not instructions).
- **Stop** — if the turn edited code without evidence of validation, blocks once and asks to validate or say why not
  (documentation-only edits are exempt).

## More

- Repository, full documentation and specification: https://github.com/JhonnyAdriZambrano/senior-engineering-agent
- Measured results and their limitations: https://github.com/JhonnyAdriZambrano/senior-engineering-agent/blob/main/docs/MEASUREMENTS.md
- License: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) from 1.2.1 (see the `LICENSE` and `NOTICE` files in this folder). Versions up to and including 1.2.0 were released under CC BY-NC 4.0.
