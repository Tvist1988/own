---
name: adr-init
description: Set up an ADR directory in this project
disable-model-invocation: true
allowed-tools: Read, Glob
---

Set up Architecture Decision Records for this project.

1. ADR directory: `${user_config.adr_dir}` relative to the project root (if this is
   an unexpanded placeholder, use `docs/adr`). If it already exists,
   report what is there (count, statuses) and stop — do not
   modify anything.
2. Otherwise create the directory with a single `README.md` index:
   a title, one paragraph on what ADRs are and that they are written by humans,
   the status lifecycle (Proposed → Accepted → Superseded by NNNN / Rejected),
   and an empty "## Index" section.
3. Do not create any ADR files. Do not write any ADR content.
4. Ask the user whether to add the following block to the project's CLAUDE.md.
   Explain that the plugin's session-start hook already delivers these rules, so the
   block is only needed for teammates without the plugin. Default answer: no.
   Write it only on an explicit yes.

   ## Architecture decisions
   Accepted decisions live in `<adr_dir>/`. Before changing code in an area an
   Accepted ADR covers, read it. If a task would contradict an Accepted ADR, stop
   and name the ADR and the conflict before writing code. ADRs are written by people;
   don't create or edit ADR content unless asked.

Reply in the user's language.
