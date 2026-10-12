# Privacy Policy — Senior Engineering Agent

Last updated: 2026-10-11

## Summary

Senior Engineering Agent is an open-source plugin (Apache-2.0). It has no telemetry or analytics and does not collect, sell or share personal data with its author or any third party. Everything it does happens on your machine or inside your own Claude session.

## What runs on your machine

Paths below are relative to the plugin root (`plugins/claude-code/senior-engineering-agent/` in this repository).

- Skills and agents are instructions executed by Claude inside your session.
- Hooks run locally through `scripts/sea-python.sh` and `adapters/hooks/sea_hooks.py`. They use only the Python standard library, make no network requests, and their only subprocess is `git rev-parse --show-toplevel`.
- Environment variables: the hooks read only `CLAUDE_PROJECT_DIR`, `CURSOR_PROJECT_DIR` and `GEMINI_PROJECT_DIR` (project path), `CLAUDE_PLUGIN_DATA` (plugin data directory), and `CLAUDE_PLUGIN_OPTION_LANGUAGE` and `SEA_LANGUAGE` (language option). The launcher script reads none; it only sets `PYTHONUTF8` and `PYTHONIOENCODING` for the Python process it starts.
- To decide what to report, the hooks can read locally the session transcript (the `transcript_path` that Claude Code passes to the Stop hook) and files of your project repository: `PROJECT_CONTEXT.md`, `ARCHITECTURE.md` and `DECISIONS.md` in the project root, and the files you edited in the session together with the project files they import (to detect whether edited code was run). This content is read and processed in memory, on your machine; the only part that leaves the hook is its output, described under "Data processed by Claude".
- They do not look for or extract credentials. Hooks never make network requests themselves. Their only output goes into your Claude session (see below).
- The PreToolUse hook only returns "ask" or "deny" for risky shell commands; it never runs or rewrites commands.

## Local files

The hooks write one small state file per session, named `sea-alerts-<session id>.json`. It contains only a list of `{"file": <name>, "line": <number>}` records (which of `PROJECT_CONTEXT.md`, `ARCHITECTURE.md` or `DECISIONS.md` had a suspicious line, and its line number) and a `blocked` true/false flag. It does not contain command text, transcript text or file contents. It is stored in the directory given by `CLAUDE_PLUGIN_DATA` when Claude Code provides one and it is writable, otherwise in the operating system's temporary directory. It is deleted when a later session start finds no alerts; otherwise it persists until you or the operating system clear those directories. It never leaves your machine. `scripts/sea-python.sh` writes no files, and the hooks create no logs and no files other than this one. Files that Claude creates or edits in your project while following the plugin's skills are written by Claude through its normal tools, subject to your permissions.

## Data processed by Claude

Conversations and files you share with Claude are handled by Anthropic under its own privacy policy; this plugin does not send them anywhere else.

Hook output becomes part of your Claude session: ask/deny decisions and reminders, and, at session start, up to 140 characters of each line in PROJECT_CONTEXT.md, ARCHITECTURE.md or DECISIONS.md that looks like an embedded instruction, so Claude can warn you about it. That output is handled like the rest of your conversation.

## Contact

Questions or concerns: open an issue at https://github.com/JhonnyAdriZambrano/senior-engineering-agent/issues
