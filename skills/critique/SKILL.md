---
name: critique
description: Run the design critic on an ADR or design doc in an isolated context
disable-model-invocation: true
argument-hint: <path to ADR or design doc>
context: fork
agent: own:design-critic
background: false
---

Critique the design document at: $ARGUMENTS

If no path was given, pick the most recently modified ADR with `Status: Proposed`
in the ADR directory (`${user_config.adr_dir}`; if this is an unexpanded placeholder,
use `docs/adr`) and state which file you chose.
