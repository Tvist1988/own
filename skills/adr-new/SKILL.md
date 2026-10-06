---
name: adr-new
description: Create an empty ADR skeleton for the user to fill in
disable-model-invocation: true
argument-hint: <decision title>
allowed-tools: Read, Glob
---

Create a new ADR skeleton titled: $ARGUMENTS

1. If the title is empty, ask for it and stop.
2. ADR directory: `${user_config.adr_dir}` (if this is an unexpanded placeholder, use
   `docs/adr`). If it does not exist, tell the user to run
   /own:adr-init first and stop.
3. Next number = highest existing `NNNN-*.md` number + 1, zero-padded to 4 digits
   (0001 if none).
4. File name: `NNNN-<slug>.md`, slug = lowercase kebab-case ASCII of the title
   (transliterate non-Latin text), at most 60 characters.
5. Content: copy `${CLAUDE_SKILL_DIR}/template.md` and fill ONLY the title, the
   number, today's date and `Status: Proposed`. Leave every section with its
   guidance comment. Do NOT write any context, decision, alternatives or consequences,
   even if you know them from the conversation — the user writes those.
6. If `<adr_dir>/README.md` has an "## Index" section, append
   `- [NNNN. <title>](NNNN-<slug>.md)`. Do not put the status in the index:
   it lives only in the ADR file.
7. Reply with the file path and one line: fill it in, then run
   `/own:critique <path>`.

Reply in the user's language.
