# Own

[Русская версия](README.ru.md)

A Claude Code plugin for practicing developers who want to keep owning the architecture and the code while Claude writes it.

## Why

When Claude writes most of the code, decisions blur: a design gets "improved" in passing, and after a week nobody can say why the code works the way it does. Own keeps you in charge with three mechanisms:

- **ADRs Claude must respect.** You record decisions as Architecture Decision Records. At session start Claude gets the index of Accepted ADRs and a rule: if a task contradicts an Accepted ADR, stop and say so before writing code.
- **A clean-context critic.** The critic reads only your document and the code. It has not seen your discussion, so it can't be talked into agreeing.
- **Explain-back.** Before committing non-trivial logic you explain the change yourself, and Claude checks your explanation against the code.

## Install

Run each command separately:

```
/plugin marketplace add Tvist1988/own
/plugin install own@own
```

If a settings dialog appears, just press Enter: the defaults work.

Updates: third-party marketplaces don't auto-update by default. To turn it on, open `/plugin` → **Marketplaces** → `own` → enable auto-update. To update by hand, run `claude plugin update own@own` in your shell, or select the plugin on the **Installed** tab of `/plugin` → **Update now**.

## Components

| Command | What it does |
|---|---|
| `/own:adr-init` | Creates the ADR directory with a README index. Asks before touching `CLAUDE.md`. |
| `/own:adr-new <title>` | Creates an empty ADR skeleton with the next number. Never fills in the content. |
| `/own:critique [path]` | Runs the design critic in an isolated context and waits for its verdict: Blocking / Risks / Questions. Without a path it takes the latest Proposed ADR. |
| `/own:explain-back [base-ref]` | Asks you what changed, how data flows and what happens on failure, then checks each claim against the code with `file:line`. |
| `/output-style own:architect` | Optional mode: you design, Claude critiques and implements. |
| SessionStart hook | Adds the ADR index and the ADR rules to Claude's context. Silent when the project has no ADR directory. |

Every command runs only when you call it. Claude never invokes the skills or the critic on its own.

## Workflow

1. A task involves an architectural choice → `/own:adr-new Webhook idempotency`.
2. You write the ADR yourself: context, decision, alternatives, consequences.
3. `/own:critique docs/adr/0001-webhook-idempotency.md`.
4. Resolve every Blocking point and record how in **Review notes**.
5. Set `Status: Accepted`.
6. Implementation. From now on Claude checks new tasks against this ADR.
7. Before committing non-trivial logic → `/own:explain-back` (or `/own:explain-back main` for a whole branch).

Routine tasks (CRUD, mapping, renames, tests against an agreed contract) need none of this. Write ADRs only for decisions that are expensive to reverse.

## Architect output style

Turn it on with `/output-style own:architect`, and off with `/output-style default`.

In this mode, for architectural tasks (module boundaries, interfaces, data model, transactions, concurrency, failure handling, integrations) Claude first asks for your approach, then critiques it, and writes code only after your go-ahead. Routine work is done right away. Saying "just do it" skips the questions for that task.

Turn it on when you want to practice design or when the decision matters. Leave it off for a day of routine work, prototypes and throwaway code: there the questions only slow you down.

## Settings

Change them in `/config`, or in `/plugin` → **Installed** → `own` → **Configure options**.

| Setting | Default | Meaning |
|---|---|---|
| `adr_dir` | `docs/adr` | ADR directory, relative to the project root. |
| `inject_adr_context` | `true` | Add the ADR index and rules to the context at session start. |

## Privacy

No network calls, no telemetry, no external services, no runtime dependencies beyond POSIX `sh` and standard utilities.

The hook adds this to Claude's context, and only when the ADR directory exists: one line per Accepted or Proposed ADR (`- 0001 Webhook idempotency [Accepted]`; at most 60 lines, about 5 KB) and four rules:

```
This project records architecture decisions as ADRs in docs/adr/ (relative to the project root).
Rules:
- Before changing code in an area covered by an Accepted ADR, read that ADR.
- If a task would contradict an Accepted ADR, stop and name the ADR and the conflict before writing code. Never work around an ADR silently.
- Proposed ADRs are drafts under discussion, not constraints.
- ADRs are written by the user. Do not create or edit ADR content unless the user explicitly asks.
```

## Limitations

All of this is instructions to a model, not guarantees. Claude usually follows them, but can miss a conflict with an ADR. If you need hard module boundaries, enforce them with linters in CI: `depguard`, `go-arch-lint`, `dependency-cruiser` and similar.

## Uninstall

```
/plugin uninstall own@own
/plugin marketplace remove own
```

Your ADR files stay in the project.

## Contributing

```
sh tests/hook_test.sh
shellcheck hooks/*.sh tests/*.sh skills/*/*.sh
claude plugin validate . --strict
claude --plugin-dir .
```

## License

MIT
