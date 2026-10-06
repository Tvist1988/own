---
name: explain-back
description: Check your understanding of a change — you explain it, Claude verifies against the code
disable-model-invocation: true
argument-hint: "[base-ref, e.g. main]"
allowed-tools: Read, Grep, Glob, Bash(sh ${CLAUDE_SKILL_DIR}/collect.sh), Bash(git status *), Bash(git diff *), Bash(git ls-files *), Bash(git log *)
---

## Repository state
!`sh ${CLAUDE_SKILL_DIR}/collect.sh`

## Task

If the state above says this is not a git repository, or there are no changes and
no base ref was given, say so in one line and stop.

Scope: if a base ref was given ("$ARGUMENTS" is non-empty), the change is
`git diff $ARGUMENTS...HEAD` plus any uncommitted work; otherwise it is the
uncommitted work shown above (including untracked files — read them).
Read the actual diffs yourself with `git diff` per file. Do not explain the code
and do not summarize the diff to the user.

1. Ask the user these questions in ONE message, then wait:
   - What changed and why — in one or two sentences.
   - How data and control flow through the new code, from entry point to write/response.
   - What happens on failure: a dependency error, context cancellation, a repeated
     or concurrent request.
   If the change is trivial, ask only the first question.
2. Check every claim in the answer against the code as written — not against what
   was discussed earlier in this conversation. For each claim: correct / gap / wrong,
   with file:line.
3. Separately list behavior that matters and the user did not mention
   (edge cases, side effects, error paths).
No praise. Do not modify code unless the user asks. Reply in the user's language.
