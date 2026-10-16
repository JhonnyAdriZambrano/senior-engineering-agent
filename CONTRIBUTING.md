# Contributing

Thanks for your interest. This repository is a portable specification of a senior-engineering agent plus a generated Claude Code plugin. Read [`SPECIFICATION.md`](SPECIFICATION.md) (Spanish) for the architecture and [`README.md`](README.md) for the overview.

## Single source vs generated views

Edit only the **single source**:

- `core/*.md` and `modules/*.md` (the normative content),
- `manifest.yaml` (identity, version, module index, language settings),
- `capabilities.yaml`, `adapters/hooks/sea_hooks.py`, the hand-written adapter files and `project-knowledge-templates/`,
- `core/compact.md`: a **hand-maintained summary** of `core/00–05` for runtimes without `@import`. No script rewrites it: when a rule in
  `core/` changes, update the summary yourself and review that it still says the same thing (the tests check sync and some clauses, not
  full semantic equivalence).

These are **generated views**; never edit them by hand:

- `adapters/skills/` (from `modules/`) — `scripts/generate_skills.py`
- the compact-core blocks in the adapters (copied from `core/compact.md`) — `scripts/generate_compact.py`
- `plugins/claude-code/senior-engineering-agent/` (except `evals/`, which is hand-written) and `adapters/hooks/i18n.json` — `scripts/generate_plugin.py`

After changing the source, regenerate and verify that nothing drifts:

```bash
python3 scripts/generate_skills.py
python3 scripts/generate_compact.py
python3 scripts/generate_plugin.py

python3 scripts/generate_skills.py --check
python3 scripts/generate_compact.py --check
python3 scripts/generate_plugin.py --check
```

## Run the checks

```bash
python3 tests/test_agent.py              # structural suite (no model, no network)
bash tests/acceptance/hooks_practice.sh  # hooks through the real launcher
```

On Windows use Git Bash (`py -3` instead of `python3` if needed). A check that cannot run is reported as `[SKIP]` with its reason; it never counts as passed. The same checks run in CI.

## Conventions

- **Language of the core.** `core/` and `modules/` are written in Spanish and are the source of truth. Do not translate them; the English output mode is handled by `manifest.yaml > i18n`.
- **Line endings.** LF everywhere (`.gitattributes` enforces it).
- **No real project data.** Do not commit names, paths, credentials, tickets or code from real projects, not even as examples.
- **Minimal, scoped changes.** One concern per pull request. If a change alters what reaches the model (`core/`, `modules/`, Skill descriptions, agents, hooks), say so explicitly and explain why.
- **Versioning.** A change to the plugin needs a version bump in `manifest.yaml > agent.version` (then regenerate) and an entry in [`CHANGELOG.md`](CHANGELOG.md). CI fails if the plugin changed since the last `v*` tag and `plugin.json` kept the same version.
- **Commits.** Write them in the imperative, one topic each, with no attribution to AI tools (no `Co-Authored-By` lines for assistants).

## Reporting problems

Use the issue templates. For security issues, follow [`SECURITY.md`](SECURITY.md) and do not open a public issue.
