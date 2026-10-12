# Senior Engineering Agent

🇪🇸 **Versión en español: [README.md](README.md)** — 🇬🇧 This file is the English version (same content, English wording; the normative core stays in Spanish).

A portable specification of an agent that embodies the role of **Senior Software Engineer and Senior Information Technology Architect**: identity, rules and workflows defined
**once**, able to materialize in Claude Code, OpenAI Codex, Cursor, Gemini CLI, ChatGPT Projects and Gemini Gems without rewriting the behavior for each platform.

> **Language note.** The normative core (`core/`, `modules/`) is written in **Spanish** and is the source of truth. Since 1.2.0 the Claude Code plugin has a `language`
> selector (`es` | `en`): in `en` mode the agent answers in English, states its role in English and uses English labels. See [Language selector](#language-selector-es--en).

## What it is and what problem it solves

Writing "a good senior-engineer prompt" for a single platform is easy. Keeping the same behavior — security rules, judgment about when to ask, scope discipline —
consistent across six platforms, each with its own instruction format, size limits and loading mechanism, is not. This project separates:

- **What the agent must do** (identity, rules, judgment) — written once, in `core/` and `modules/`.
- **How each platform is told** — lives in `adapters/`, one directory per runtime, which translates (never duplicates) the above into that platform's native mechanism.
- **What it knows about YOUR project** — never lives here. It lives in `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` / `DECISIONS.md` inside each real repository where you deploy the
  agent (templates in `project-knowledge-templates/`).

See `SPECIFICATION.md` (Spanish) for the full architecture and the evidence-based rationale of each design decision.

## Requirements

- **To use the agent** (load it in Claude Code, Codex, Cursor, Gemini CLI, ChatGPT Projects or Gemini Gems): nothing besides the runtime itself — it is plain text
  (Markdown/YAML/TOML) that the runtime consumes directly. The Claude Code **plugin** needs **Claude Code ≥ v2.1.271** (it declares `userConfig.options`; older versions cannot load it) and
  Python 3.8+ for the hooks.
- **To run the tests or rebuild the ZIP** (only if you modify the agent): Python 3.11+ with `pyyaml` (`pip install pyyaml --break-system-packages`) and the system utilities `zip`/`unzip`.
  With Python 3.10 also install `tomli` so the TOML validation is not skipped.
- **On Windows**: the Claude Code plugin runs its hooks with **Git Bash** (`plugins/claude-code/senior-engineering-agent/scripts/sea-python.sh` is a bash script). The repository ships a
  `.gitattributes` (`* text=auto eol=lf`) that forces LF line endings even with `core.autocrlf=true`; without it the `.sh` files would get CRLF and fail with "$'\r': command not found".
  If you cloned earlier, run `git add --renormalize . && git checkout -- .` (or clone again).

## Installation

### With Claude Code (recommended: install as a plugin)

The repository itself is the marketplace (`.claude-plugin/marketplace.json`). Inside Claude Code:

```
/plugin marketplace add JhonnyAdriZambrano/senior-engineering-agent
/plugin install senior-engineering-agent@senior-engineering-agent
```

(On Claude Code 2.1.275 or later this also works in one step:
`/plugin install senior-engineering-agent --marketplace JhonnyAdriZambrano/senior-engineering-agent`.)

The plugin ships 7 Skills, 2 read-only subagents, the core (injected at session start by one `SessionStart` hook per `core/` file) and the deterministic hooks (`SessionStart`,
`PreToolUse` and `Stop`); you do not need to touch `CLAUDE.md` or copy anything. It is a **generated view** (`plugins/claude-code/senior-engineering-agent/`,
`python3 scripts/generate_plugin.py`), not a second source of truth. The Python hooks go through a launcher that tries `python3`, `python` and `py -3` and forces UTF-8
(`PYTHONUTF8=1`, `PYTHONIOENCODING=utf-8`); hooks read stdin as UTF-8 and emit ASCII JSON, and NN-08 asks for confirmation (fail-closed) if it cannot parse the command. Hooks of the same
event run in parallel and the documentation does not guarantee their order: each core part carries the header "[Núcleo SEA — parte X de 6 (orden canónico 00→05)]".
Details and limits: `adapters/claude-code/CLAUDE.md`.

**Alternative: manual copy** (no plugin; do not combine both in the same project).

1. Copy the **whole** `senior-engineering-agent/` folder to the root of your repository.
2. In your project's `CLAUDE.md`, add one line: `@senior-engineering-agent/adapters/claude-code/CLAUDE.md`
3. Copy each folder of `adapters/skills/` to `.claude/skills/` in your project (`.claude/skills/<name>/SKILL.md`) so Claude Code loads them only when the task calls for it.
4. Optional: copy `adapters/claude-code/agents/*.md` to `.claude/agents/` to enable the 2 read-only subagents (reviewer and bootstrap research).
5. Recommended: copy `adapters/claude-code/settings.hooks.json` to `.claude/settings.json` (or merge it) to enable the deterministic hooks: missing-knowledge notice at session start
   (`SessionStart`), mandatory confirmation of destructive operations (`PreToolUse`, on `Bash` and `PowerShell`) and a validation requirement at the end of the turn (`Stop`). Requires Python 3.8+.
6. Copy `project-knowledge-templates/*.md` to your project root (removing `[Nombre del proyecto]` and filling them in), or let `project-knowledge-bootstrap` help you generate them after `/init`.

### With OpenAI Codex

1. Copy the **whole** `senior-engineering-agent/` folder to your repository root (Codex has no import mechanism; the content must be copied verbatim).
2. Copy the content of `adapters/codex/AGENTS.md` (from "Identidad" to the end, without the installation section) into your real `AGENTS.md`.
3. Copy each folder of `adapters/skills/` to `.agents/skills/` in your project — Codex discovers them natively (so do Cursor and Gemini CLI).
4. Optional: copy `adapters/codex/agents/*.toml` to `.codex/agents/` to enable the read-only subagents.
5. Recommended: copy `adapters/codex/hooks.json` to `.codex/hooks.json` (deterministic hooks; in Codex destructive operations are blocked, because Codex cannot yet ask for confirmation from a hook).

### With Cursor, Gemini CLI, ChatGPT Projects or Gemini Gems

Each adapter in `adapters/` includes its own installation section at the top of its file. Cursor and Gemini CLI also use the Skills from `adapters/skills/`, installed in
`.agents/skills/`, and the deterministic hooks (`adapters/cursor/hooks.json` → `.cursor/hooks.json`; `adapters/gemini-cli/settings.hooks.json` → `.gemini/settings.json`). Loading differs by
platform (real import, verbatim copy, or compression + attached file) — see the compatibility matrix in `SPECIFICATION.md` §7.

To add a runtime that is not listed, see `docs/ADDING_A_RUNTIME.md`.

## Language selector (es / en)

Since 1.2.0 the plugin declares a `language` option in `userConfig` (`plugin.json`): values `es` (default) and `en`. It appears as a picker in `/config` → *senior-engineering-agent*
([manifest reference, "User configuration"](https://code.claude.com/docs/en/plugins/manifest-reference): `options` is shown as a picker in `/config` and requires **Claude Code ≥ v2.1.271**).

- **`es` (default):** nothing changes — the output of the `session-start` and `pre-tool` hooks is byte-for-byte identical to 1.1.2 (verified by a deterministic test against the frozen 1.1.2 code).
- **`en`:** `session-start` adds a directive generated from `manifest.yaml` (answer in English, state the role literally as *"Senior Software Engineer and Senior Information Technology Architect"*,
  and the label table below). The Spanish core stays the source of truth. The hook messages (NN-08 dialog, NN-06b alerts, knowledge report and Stop notices) also come out in English, and
  Stop recognizes "could not validate"-style statements in both languages.
- **How the value reaches the hooks:** as `CLAUDE_PLUGIN_OPTION_LANGUAGE`. Precedence: `CLAUDE_PLUGIN_OPTION_LANGUAGE` → `SEA_LANGUAGE` → `es`; an unknown value is treated as `es`.
  Other runtimes (Codex, Cursor, Gemini CLI) stay in `es` unless you export `SEA_LANGUAGE=en`.
- **Verified behavior (Claude Code 2.1.296):** a plugin hook receives `CLAUDE_PLUGIN_OPTION_LANGUAGE` only when a value is *stored* in `pluginConfigs`; the manifest `default` is not exported.
  Until you pick a value the hooks behave as `es`. Change the value and start a **new session**.

Label table (single source: `manifest.yaml > i18n`; the test suite checks it covers every bracketed label defined in `core/` and `modules/`):

| Spanish | English |
|---|---|
| `[HECHO VERIFICADO]` | `[VERIFIED FACT]` |
| `[RECOMENDACIÓN TÉCNICA]` | `[TECHNICAL RECOMMENDATION]` |
| `[INFERENCIA]` | `[INFERENCE]` |
| `[INCERTIDUMBRE / REQUIERE VERIFICACIÓN]` | `[UNCERTAINTY / NEEDS VERIFICATION]` |
| `[REQUERIDO PARA LA TAREA]` | `[REQUIRED FOR THE TASK]` |
| `[MEJORA RECOMENDADA]` | `[RECOMMENDED IMPROVEMENT]` |
| `[HALLAZGO FUERA DE ALCANCE]` | `[OUT-OF-SCOPE FINDING]` |
| `[ENFOQUE INICIAL / ASUNCIÓN INCORRECTA]` | `[INITIAL APPROACH / INCORRECT ASSUMPTION]` |
| `[HALLAZGO VERIFICADO]` | `[VERIFIED FINDING]` |
| `[NUEVA REGLA APRENDIDA]` | `[NEW LEARNED RULE]` |
| `[SOLUCIÓN CORREGIDA]` | `[CORRECTED SOLUTION]` |
| `[REQUISITO CONFIRMADO]` | `[CONFIRMED REQUIREMENT]` |
| `[RESTRICCIÓN TÉCNICA]` | `[TECHNICAL CONSTRAINT]` |
| `[DECISIÓN DE ARQUITECTURA]` | `[ARCHITECTURE DECISION]` |

## Deterministic guarantees (hooks)

Behavior rules in a prompt are a request; the hooks below are code that runs regardless of what the model decides. Shared logic: `adapters/hooks/sea_hooks.py`.

- **NN-08 — destructive operations (`PreToolUse`).** Before a shell command that can destroy work (forced `git push`, `git reset --hard`, `git clean -f`, `git checkout -- .`, `git branch -D`,
  history rewrites, `rm -rf`, PowerShell `Remove-Item -Recurse -Force` and aliases), the hook requires explicit human confirmation (`ask`) where the runtime supports it, and blocks it (`deny`) where it
  does not (Codex, Gemini CLI). **Fail-closed:** if the hook input cannot be read or parsed, it asks (or denies) instead of staying silent. Covers the `Bash` and `PowerShell` tools.
- **NN-06b — knowledge files are data, not orders (`SessionStart` + `Stop`).** At session start the hook checks `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` / `DECISIONS.md` for lines shaped like an
  instruction addressed to the agent (heuristic) and reports them; at the end of the turn `Stop` blocks **once** if no assistant message pointed the embedded instruction out to the user.
- **Stop — validate before finishing (`Stop`, Claude Code only).** If the turn edited files (Edit/Write/MultiEdit or shell edits such as `sed -i`, redirection, `tee`, PowerShell `Set-Content`) and there is
  no evidence of validation (a test, build or lint command, or running an edited file or one that imports it) nor an explicit "I could not validate", it blocks **once** and asks to validate or say why not.
  **Documentation exception (1.2.0):** if *all* edited files are `.md`, `.markdown`, `.txt`, `.rst` or `.adoc`, no validation is required; one unknown target or any other file type keeps the old behavior.
  Limit: the extension does not prove the content is documentation (a `.txt` a program reads as data still counts as documentation).
- **Project-knowledge check at session start.** If `PROJECT_CONTEXT.md` / `ARCHITECTURE.md` are missing or still the template, the agent is told — only when the task works on that repository — to
  mention it in one line and offer to generate them.

Hooks never break the session: they always exit with 0 (a failure only warns).

## Measured results

Full tables, provenance and limitations: [`docs/MEASUREMENTS.md`](docs/MEASUREMENTS.md) (in Spanish; figures are language-independent). All runs: model `claude-sonnet-5-5`, Claude Code CLI 2.1.296.

| Measurement | Date | Result |
|---|---|---|
| **Regression E7a** — plugin 1.1.0, 16 cases × 3 runs × 2 arms (WITH plugin / W/OUT), ≈ 7.08 USD | 2026-10-11 | **Mean Δ +0.41** (+0.407); the **4 critical cases at pass^3 (3/3 perfect runs each)**; no Δ < 0. Largest gains: c1 exact role +1.00, c3 core titles +1.00, test-00 install +1.00, test-02a +0.75, test-03 user interaction +0.75. |
| **Core ablation E3d** — plugin 1.1.2, WITH arm only, 11 cases × 3 runs per variant, ≈ 15.1 USD | 2026-10-11 | Removing **`core/04`** (user interaction): test-03 1.00 → 0.25 (−0.75), test-08 1.00 → 0.43 (−0.57), test-13 loses pass^3 (0.92). Removing **`core/03`** (task classification): test-08b 1.00 → 0.60 (−0.40), test-09 0.87 → 0.67 (−0.20). Removing `core/02` or `core/05`: no measurable loss on these 11 cases (this does not mean they are superfluous). |
| **test-09 (regression) with pytest** — plugin 1.1.2, 3 runs × 2 arms, ≈ 0.49 USD | 2026-10-11 | WITH 0.93 · W/OUT 0.67 · **Δ +0.27** (per the evaluator) · 2/3 perfect WITH runs. |

Limitations of these figures: n = 3 runs per case and a single execution per measurement; a single model; 8 of the 11 ablation cases are at the ceiling; capability measurements are partial;
raw results are not versioned (`tests/results/` is local). 1.2.0 session (plugin 1.2.0, WITH arm only, one execution each, ≈ 4.22 USD in total; details in `docs/MEASUREMENTS.md`, section 6):

| Measurement | Date | Result |
|---|---|---|
| Smoke, 4 critical cases in `es` | 2026-10-11 | All 4 at pass^3 (3/3 perfect runs each). |
| Cases affected by Stop (test-03, test-08, test-08b, test-09) | 2026-10-12 | 1.00 / 1.00 / 1.00 / 0.93; no drop > 0.10 versus E7a (1.00 / 1.00 / 0.72 / 0.87). |
| `cap-stop-docs` (editing only `README.md`) | 2026-10-12 | 1.00; the Stop hook no longer blocks (indicator 3/3). |
| `cap-certeza-sin-ejecutar` (isolated, no Bash) | 2026-10-12 | WITH 1.00, W/OUT 1.00 (Δ 0.00): no `[VERIFIED FACT]`-style claim on unexecuted code, with or without the plugin. |
| 4 English cases (`en` mode, via a plugin copy with `CLAUDE_PLUGIN_OPTION_LANGUAGE=en`) | 2026-10-12 | All 4 at pass^3; exact English role in 3/3 runs of the role case. |

Same limits apply (n = 3, one model, one execution).

## Context cost

`SessionStart` injects **19,622 characters per event** (`startup`, `clear` and `compact`; core 19,291 + hook report) ≈ **4,900–5,600 tokens ESTIMATED** (characters / 3.5–4, no tokenizer).
`claude plugin details` reports ≈ 1,087 tokens and does **not** count hook output. Always-on cost ≈ **6k tokens per session event** [estimate]. `en` mode adds a short directive (1,425 characters ≈ 0.4k tokens, estimate).

## Validation status per runtime (version 1.2.0)

| Runtime | Status | What it means |
|---|---|---|
| Claude Code | **validated** | Evaluated in real use with `claude plugin eval` and the benchmark (`tests/results/`, `CHANGELOG.md`). |
| Codex | pending validation (stage E4') | Adapter and hooks tested without an LLM; no real execution yet. |
| Gemini CLI | not validated in real use | Structural tests only. |
| Cursor | not validated in real use | Structural tests only. |
| ChatGPT Projects / Gemini Gems | not validated in real use | Compressed instructions; no real execution. |

## Known limitations (read before assuming full portability)

- **Real conditional loading** of modules is offered, via Skills, by Claude Code, Codex, Cursor and Gemini CLI: the runtime loads the Skill when its description matches the task (the model decides from
  that description). In ChatGPT Projects and Gemini Gems there is no such mechanism: modules are uploaded as attachments and using them is a behavioral convention.
- No instruction architecture changes the host product's visible name in its UI (Claude Code remains Claude Code), and this agent does not override the platform's native security/approval policies —
  it is an additional behavioral floor, not a ceiling that replaces them.
- **The normative core is Spanish.** `en` mode is a directive on top of it, not a translation of the core: a model may still occasionally echo a Spanish term; the test suite and the English evals
  (`regression-en`) measure this, they do not guarantee it.
- **`options` raises the minimum version:** declaring a picker means Claude Code versions before v2.1.271 cannot load the plugin.
- **Hooks are heuristic:** NN-06b detection and the Stop validation/edit criteria are pattern-based (documented limits in `sea_hooks.py`); NN-08 matches a fixed list of destructive commands.
- **Stop exists only in Claude Code;** Codex, Cursor and Gemini CLI have no Stop equivalent here (pending verification against a primary source).
- **Measurements are small:** n = 3 per case, one model, one execution each (see above).
- See `SPECIFICATION.md` §6 and §7 for what is portable, adaptable or platform-dependent.

## Repository structure

```
senior-engineering-agent/
├── README.md                    Spanish README (linked with this file)
├── README.en.md                 this file
├── CHANGELOG.md                 version history and versioning policy
├── SPECIFICATION.md             full architecture, agent contract
├── LICENSE                      CC BY-NC 4.0 + author clarifications
├── manifest.yaml                identity, version, module index, i18n (languages, English role, label table)
├── capabilities.yaml            abstract capabilities -> per-runtime binding
├── .gitattributes               LF line endings (Windows portability)
├── .gitignore                   Git hygiene (secrets, builds, results)
├── .env.example                 documents that the project needs no variables of its own
├── .github/
│   └── workflows/
│       └── structural-tests.yml CI: structural suite and --check on Linux and Windows (no LLM)
├── .claude-plugin/
│   └── marketplace.json         the repo is the Claude Code plugin marketplace
├── core/                        6 always-loaded files + compact.md
│                                (DERIVED summary for runtimes without @import)
├── modules/                     7 conditionally loaded modules
├── adapters/                    one directory per supported runtime
│   ├── skills/                  7 Skills (SKILL.md) GENERATED from modules/
│   ├── hooks/
│   │   ├── sea_hooks.py         shared hook logic (Claude Code, Codex, Cursor, Gemini CLI)
│   │   └── i18n.json            languages, English role and es->en labels (GENERATED from manifest.yaml > i18n)
│   ├── claude-code/             CLAUDE.md + agents/ (2 read-only subagents) + settings.hooks.json
│   ├── codex/                   AGENTS.md + hooks.json + agents/ (3 read-only subagents)
│   ├── cursor/                  hooks.json + rules/ (alwaysApply rule with the compact core)
│   ├── gemini-cli/              GEMINI.md + settings.hooks.json
│   └── chatgpt-and-gems/        compressed instructions + attached files
├── plugins/
│   └── claude-code/
│       └── senior-engineering-agent/   GENERATED Claude Code plugin (scripts/generate_plugin.py)
│           ├── .claude-plugin/
│           │   └── plugin.json  name, version and the language userConfig (from manifest.yaml)
│           ├── LICENSE          license copy
│           ├── core/            copy of core/00-05
│           ├── skills/          copy of adapters/skills/
│           ├── agents/          copy of adapters/claude-code/agents/
│           ├── hooks/
│           │   └── hooks.json   one SessionStart per core/ file, plus PreToolUse and Stop
│           ├── adapters/
│           │   └── hooks/
│           │       ├── sea_hooks.py  same relative path as in the source
│           │       └── i18n.json     copy of adapters/hooks/i18n.json
│           ├── project-knowledge-templates/  templates the SessionStart hook needs
│           ├── scripts/
│           │   └── sea-python.sh  Python launcher (python3 | python | py -3)
│           └── evals/           `claude plugin eval` cases (hand-written, versioned)
│               └── README.md    what is automated and criterion -> grader
├── project-knowledge-templates/ templates you copy into YOUR real project
├── docs/
│   ├── ADDING_A_RUNTIME.md      contract for building a new adapter
│   └── MEASUREMENTS.md          audited measurements (E7a, E3d and 1.2.0): tables, provenance, limitations
├── tests/                       structural validation + behavior evaluation
│   ├── test_agent.py            structural validation (level 1, no LLM)
│   ├── run_tests.sh             entry point of test_agent.py
│   ├── BENCHMARK.md             14 formal tests, PASS/PARTIAL/FAIL criteria
│   ├── GUIA_BENCHMARK.md        HOW to run all the tests (start here)
│   ├── MANUAL_SCENARIOS.md      narrative manual verification scenarios
│   ├── acceptance/              hooks_practice.sh: practical acceptance of the hooks with the real launcher (no LLM)
│   ├── fixtures/                sea_hooks_1.1.2.py: frozen copy of the 1.1.2 hook (byte-for-byte identity test of `es` mode)
│   ├── behavioral/              heuristic harness run_scenarios.sh (OBSOLETE: scripts/eval.sh replaces it)
│   ├── sandbox/                 creates the benchmark sandbox (states A/B/C)
│   └── results/                 run records (template _TEMPLATE.md)
└── scripts/
    ├── build_zip.sh             deterministic packaging (dist | repo)
    ├── generate_skills.py       modules/ -> adapters/skills/ (--check only checks)
    ├── generate_compact.py      core/compact.md -> adapters without @import (--check)
    ├── generate_plugin.py       core/, adapters/ and manifest.yaml -> Claude Code plugin (--check)
    ├── eval.sh                  automated evaluation with `claude plugin eval` (smoke|regression|capability|regression-en|all)
    ├── ablate_core.sh           core ablation (D-17): without core/02…05 over 11 cases (`completo|sin-02|sin-03|sin-04|sin-05`)
    ├── eval_report.py           report of an eval.sh run (WITH / W/OUT / Δ)
    ├── eval_summary.py          per-case summary of one or more result.json (excludes `arm: with-only` graders; no model cost)
    ├── check_results.py         summarizes tests/results/ and the gate status (manual 1.0.0 benchmark)
    └── new_result.sh            creates the prefilled record of a benchmark run
```

## Testing

```bash
python3 tests/test_agent.py
bash tests/acceptance/hooks_practice.sh
```

`tests/test_agent.py` is a **structural** (static) suite plus deterministic hook tests (no LLM): manifest/capabilities consistency, no broken references, no leaked secrets, YAML/TOML validity,
Skill and compact-core sync, canonical role, version and count coherence, packaging determinism, generated-plugin sync, hook behavior (NN-08, NN-06b, Stop, UTF-8/cp1252, language `es`/`en`,
documentation exception) and tool tests. Checks that cannot run are reported as `[SKIP]` with a reason, never as passed. Behavior is evaluated separately with `scripts/eval.sh`
(`claude plugin eval`, with a no-plugin baseline) and the manual benchmark (`tests/BENCHMARK.md`, `tests/GUIA_BENCHMARK.md`).

## Contributing / changing the agent

See `README.md` (Spanish), section "Actualizar el agente", for the full checklist: edit `core/` or `modules/`, regenerate Skills / compact core / plugin
(`python3 scripts/generate_skills.py`, `generate_compact.py`, `generate_plugin.py`; each with `--check`), run the suite, bump `manifest.yaml > agent.version` per `CHANGELOG.md`, and rebuild the ZIPs.

## Authorship

Designed, directed and validated by **Jhonny Adrian Zambrano Gonzalez** (architecture, decisions, benchmark criteria and test execution). Developed with the assistance of Claude (Anthropic)
for drafting, script implementation and audits.

## License

Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0). See `LICENSE` for the full text, the author's clarification of what counts as commercial use, and how to attribute.
Personal use, education and adaptation (including new adapters) are allowed with attribution; commercial use requires a separate license (contact in `LICENSE`).
