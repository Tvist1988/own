# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-06

### Added
- `/own:adr-init`: creates the ADR directory with a README index; offers a CLAUDE.md block and writes it only on an explicit yes.
- `/own:adr-new <title>`: creates an empty ADR skeleton. The user writes the content.
- `/own:critique <path>`: runs the `design-critic` agent in a forked, clean context.
- `/own:explain-back [base-ref]`: you explain a change, Claude checks the explanation against the code.
- `own:architect` output style: you design, Claude critiques and implements.
- `SessionStart` hook: puts the index of Accepted/Proposed ADRs and the ADR rules into Claude's context.

### Deviations from spec

Results of the [VERIFY] items, checked with Claude Code 2.1.291 (`claude -p`, `--continue`, `--plugin-dir`).

- **userConfig defaults (3.1).** Until the user saves the plugin's settings, `default` values are not applied: `${user_config.KEY}` stays literal in skills and agents, and `CLAUDE_PLUGIN_OPTION_*` is not exported to hooks. Once saved, substitution works and booleans are exported as `true`/`false`. So every component has a fallback: the hook uses `docs/adr` and treats a missing option as enabled; skills and the agent say "if this is an unexpanded placeholder, use `docs/adr`". Whether the install dialog appears when every field has a default is still to check in an interactive session.
- **`/own:critique` (5.3).** `agent: own:design-critic` works with `context: fork`, and the fork does not see the conversation history (a "secret" stated earlier in the main session was unknown to the critic). Forked skills run in the background by default, so the skill sets `background: false` (Claude Code ≥ 2.1.218). In `-p` mode a fork always runs in the foreground, so foreground behaviour in an interactive session is still to check. Plan B from the spec is not needed.
- **`/own:explain-back` (5.4).** A failing injected command aborts the whole skill, and `git status` / `git diff HEAD` fail outside a repo or before the first commit. Repository state is therefore collected by `skills/explain-back/collect.sh`, which always exits 0 and is pre-approved in `allowed-tools` as `Bash(sh ${CLAUDE_SKILL_DIR}/collect.sh)`. Checked in `--permission-mode default`: no repo, no `HEAD`, no changes, untracked files only — the skill loads in every case.
- **Hook output budget (7.2).** Sizes are counted in bytes (`LC_ALL=C`); titles longer than 150 bytes are cut without splitting a UTF-8 character (instead of 120 characters via `cut -c`, which breaks Cyrillic with GNU `cut`). The index is capped at 60 lines and 5,000 bytes. A leading `NNNN.` in the title is dropped to avoid `- 0001 0001. Title`. The index has a header line `Architecture decision records (Accepted and Proposed):` so it reads clearly before the rules.
- **CI (8.2).** `claude plugin validate` works without authentication (empty `HOME`). `validate .` on the repository root checks the marketplace and the plugin's components. Hook tests run under both dash and bash.
