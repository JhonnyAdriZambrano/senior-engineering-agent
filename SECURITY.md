# Security policy

## Supported versions

Only the latest `1.x` release receives security fixes. Check the current version in [`manifest.yaml`](manifest.yaml) (`agent.version`) or in [`CHANGELOG.md`](CHANGELOG.md).

## What counts as a vulnerability

This repository is a specification plus a Claude Code plugin whose hooks run as code on your machine (`adapters/hooks/sea_hooks.py`). The following are in scope:

- **A way around NN-08.** A destructive shell command (via the `Bash` or `PowerShell` tool) that the `PreToolUse` hook should ask about or deny, but lets through without confirmation.
- **Execution of injected content.** A way to make the agent or the hooks execute an instruction planted in data that is supposed to be inert (`PROJECT_CONTEXT.md`, `ARCHITECTURE.md`, `DECISIONS.md`, other project files), including bypassing the NN-06b detection of lines that look like orders to the agent.
- **Data leakage through the hooks.** Any path by which a hook sends project data, file contents or environment values outside the machine, or writes them somewhere they should not go.
- **Unsafe handling of hook input or paths** that could lead to code execution or to reading or writing files outside the intended project directory.

Not in scope (open a regular issue instead):

- The model not following a rule that no hook enforces: the rules in `core/` are instructions, not a sandbox.
- A false positive or false negative of a hook that does not let a destructive action go unconfirmed (use the "False positive / false negative" issue template).
- Vulnerabilities in Claude Code itself or in other runtimes: report those to their vendors.

## How to report

Use GitHub's **Private vulnerability reporting**: open the repository's **Security** tab and choose **Report a vulnerability**. Please do not open a public issue or pull request for a vulnerability.

Include, as far as you can:

- the plugin or repository version, Claude Code version, runtime and operating system;
- the exact command, file content or input, and the hook output you saw;
- what you expected to happen and what happened instead.

This is a personal open-source project: reports are handled on a best-effort basis, without a guaranteed response time. Please allow a reasonable time for a fix before disclosing the issue publicly.
