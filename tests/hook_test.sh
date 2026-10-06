#!/bin/sh
# Tests for hooks/adr-context.sh. Usage: sh tests/hook_test.sh
# HOOK_SHELL selects the shell that runs the hook (default: sh).

here=$(cd "$(dirname "$0")" && pwd)
HOOK=$here/../hooks/adr-context.sh

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT
trap 'exit 1' INT TERM

total=0
failed=0

pass() { total=$((total + 1)); }
fail() {
	total=$((total + 1))
	failed=$((failed + 1))
	printf 'FAIL: %s\n' "$1"
	printf '%s\n' "$out" | sed 's/^/    | /'
}

# run [NAME=value ...]: runs the hook in a clean environment; sets $out and $code.
run() {
	out=$(env -i PATH="$PATH" "$@" "${HOOK_SHELL:-sh}" "$HOOK")
	code=$?
}

expect_empty() {
	if [ "$code" -eq 0 ] && [ -z "$out" ]; then pass; else fail "$1: expected empty output, exit 0 (got exit $code)"; fi
}
expect_contains() {
	case $out in
	*"$2"*) [ "$code" -eq 0 ] && pass || fail "$1: exit $code" ;;
	*) fail "$1: expected to contain: $2" ;;
	esac
}
expect_missing() {
	case $out in
	*"$2"*) fail "$1: expected NOT to contain: $2" ;;
	*) pass ;;
	esac
}

# project <name>: creates an empty project directory and prints its path.
project() {
	mkdir -p "$tmp/$1" && printf '%s\n' "$tmp/$1"
}

# adr <file> <title line> <status line>
adr() {
	printf '%s\n\n%s\nDate: 2026-01-01\n\n## Context\n' "$2" "$3" >"$1"
}

RULES='Rules:'
INDEX='Architecture decision records'

# --- no project dir
run
expect_empty "no CLAUDE_PROJECT_DIR"
run CLAUDE_PROJECT_DIR=
expect_empty "empty CLAUDE_PROJECT_DIR"

# --- ADR dir missing
p=$(project missing)
run CLAUDE_PROJECT_DIR="$p"
expect_empty "ADR dir missing"

# --- ADR dir is a symlink
p=$(project symlinked)
mkdir -p "$p/real" "$p/docs"
ln -s ../real "$p/docs/adr"
run CLAUDE_PROJECT_DIR="$p"
expect_empty "ADR dir is a symlink"

# --- invalid ADR_DIR values (each target exists, so only validation stops them)
p=$(project invalid)
mkdir -p "$tmp/x" "$p/a b"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_ADR_DIR=../x
expect_empty "ADR_DIR=../x"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_ADR_DIR=/etc
expect_empty "ADR_DIR=/etc"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_ADR_DIR='a b'
expect_empty "ADR_DIR='a b'"

# --- empty ADR dir: rules only
p=$(project empty)
mkdir -p "$p/docs/adr"
run CLAUDE_PROJECT_DIR="$p"
expect_contains "empty ADR dir" "$RULES"
expect_contains "empty ADR dir names the dir" "ADRs in docs/adr/ (relative"
expect_missing "empty ADR dir has no index" "$INDEX"

# --- option switched off / unset
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_INJECT_ADR_CONTEXT=false
expect_empty "option false"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_INJECT_ADR_CONTEXT=0
expect_empty "option 0"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_INJECT_ADR_CONTEXT=true
expect_contains "option true" "$RULES"

# --- statuses, Cyrillic, symlinked file, missing title, CRLF
p=$(project statuses)
d=$p/docs/adr
mkdir -p "$d"
adr "$d/0001-use-postgres.md" "# 0001. Use Postgres" "Status: Accepted"
adr "$d/0002-outbox.md" "# 0002. Очередь через outbox" "Статус: Proposed"
adr "$d/0003-old.md" "# 0003. Old approach" "Status: Superseded by 0004"
adr "$d/0004-rejected.md" "# 0004. Rejected idea" "Status: Rejected"
adr "$tmp/target.md" "# 0005. Should not appear" "Status: Accepted"
ln -s "$tmp/target.md" "$d/0005-x.md"
adr "$d/0006-no-title.md" "No heading here" "status: accepted"
printf '# 0007. Windows line endings\r\nStatus: Accepted\r\n' >"$d/0007-crlf.md"
adr "$d/notes.md" "# Not an ADR" "Status: Accepted"
run CLAUDE_PROJECT_DIR="$p"
expect_contains "Accepted listed" "- 0001 Use Postgres [Accepted]"
expect_contains "Статус: Proposed listed, Cyrillic intact" "- 0002 Очередь через outbox [Proposed]"
expect_missing "Superseded not listed" "0003"
expect_missing "Rejected not listed" "0004"
expect_missing "symlinked ADR file skipped" "0005"
expect_contains "missing title falls back to file name" "- 0006 0006-no-title [Accepted]"
expect_contains "CRLF title cleaned" "- 0007 Windows line endings [Accepted]"
expect_missing "non-numbered file skipped" "Not an ADR"
expect_contains "rules after index" "$RULES"

# --- ADR_DIR with a trailing slash
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_ADR_DIR=docs/adr/
expect_contains "trailing slash in ADR_DIR" "- 0001 Use Postgres [Accepted]"

# --- custom ADR dir
p=$(project custom)
mkdir -p "$p/architecture/decisions"
adr "$p/architecture/decisions/0001-x.md" "# Custom location" "Status: Accepted"
run CLAUDE_PROJECT_DIR="$p" CLAUDE_PLUGIN_OPTION_ADR_DIR=architecture/decisions
expect_contains "custom ADR dir" "- 0001 Custom location [Accepted]"
expect_contains "custom ADR dir named in rules" "ADRs in architecture/decisions/ (relative"

# --- long Cyrillic title is cut without breaking UTF-8
p=$(project longtitle)
mkdir -p "$p/docs/adr"
long='Очень длинное название архитектурного решения про идемпотентность вебхуков и повторную обработку событий'
adr "$p/docs/adr/0001-long.md" "# $long" "Status: Accepted"
run CLAUDE_PROJECT_DIR="$p"
expect_contains "long title truncated" "…"
expect_missing "long title not shown in full" "$long"
if printf '%s' "$out" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then pass; else fail "long title: output is not valid UTF-8"; fi

# --- 200 ADRs with long titles stay within budget
p=$(project many)
mkdir -p "$p/docs/adr"
i=1
while [ "$i" -le 200 ]; do
	n=$(printf '%04d' "$i")
	adr "$p/docs/adr/$n-decision.md" "# $n. Decision number $i about a rather long topic that keeps going and going and going for quite a while" "Status: Accepted"
	i=$((i + 1))
done
run CLAUDE_PROJECT_DIR="$p"
bytes=$(printf '%s' "$out" | wc -c | tr -d ' ')
if [ "$bytes" -lt 6000 ]; then pass; else fail "200 ADRs: output is $bytes bytes, expected < 6000"; fi
expect_contains "200 ADRs: overflow line" "- … and "
expect_contains "200 ADRs: rules still present" "$RULES"
lines=$(printf '%s\n' "$out" | grep -c '^- [0-9][0-9][0-9][0-9] ')
if [ "$lines" -le 60 ]; then pass; else fail "200 ADRs: $lines index lines, expected <= 60"; fi

printf '%d checks, %d failed\n' "$total" "$failed"
[ "$failed" -eq 0 ]
