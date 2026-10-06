#!/bin/sh
# SessionStart hook: put the ADR index and the rules for ADRs into Claude's context.
#
# Must never break session start: always exits 0 and prints nothing when anything
# is unexpected. Plain stdout of a SessionStart hook is added to Claude's context.
#
# Input (environment):
#   CLAUDE_PROJECT_DIR                       project root; empty -> no output
#   CLAUDE_PLUGIN_OPTION_ADR_DIR             ADR directory, default docs/adr
#   CLAUDE_PLUGIN_OPTION_INJECT_ADR_CONTEXT  "false" or "0" -> no output
#
# Sizes are counted in bytes (LC_ALL=C). A byte count is never smaller than a
# character count, so staying under the byte budget keeps us under Claude Code's
# 10,000-character limit.

LC_ALL=C
export LC_ALL

MAX_LINES=60
MAX_INDEX_BYTES=5000
MAX_TITLE_BYTES=150

# Prints "- NNNN <title> [Accepted|Proposed]" for each ADR file given, in order,
# within the line and byte budget, then "- … and N more" for the rest.
adr_index() {
	awk -v max_lines="$MAX_LINES" -v max_bytes="$MAX_INDEX_BYTES" -v max_title="$MAX_TITLE_BYTES" '
	function emit(path, title, status,    name, num, label, line) {
		status = tolower(status)
		if (status ~ /^accepted/) label = "Accepted"
		else if (status ~ /^proposed/) label = "Proposed"
		else return

		name = path
		sub(/.*\//, "", name)
		num = substr(name, 1, 4)

		gsub(/\r/, "", title)
		sub("^(ADR[- ])?" num "[.:]?[ \t]*", "", title)
		if (title == "") {
			title = name
			sub(/\.md$/, "", title)
		}
		if (length(title) > max_title) {
			title = substr(title, 1, max_title)
			# Drop a UTF-8 sequence the cut may have split.
			sub(/[\300-\367][\200-\277]*$/, "", title)
			title = title "…"
		}

		line = "- " num " " title " [" label "]"
		if (!full && shown < max_lines && bytes + length(line) + 1 <= max_bytes) {
			print line
			shown++
			bytes += length(line) + 1
		} else {
			full = 1
			more++
		}
	}
	FNR == 1 {
		if (path != "") emit(path, title, status)
		path = FILENAME
		title = ""
		status = ""
	}
	title == "" && /^# / {
		title = $0
		sub(/^# +/, "", title)
	}
	status == "" && /^[ \t]*([Ss][Tt][Aa][Tt][Uu][Ss]|Статус|статус|СТАТУС):/ {
		status = $0
		sub(/^[^:]*:[ \t]*/, "", status)
	}
	END {
		if (path != "") emit(path, title, status)
		if (more) print "- … and " more " more"
	}
	' "$@"
}

main() {
	[ -n "${CLAUDE_PROJECT_DIR:-}" ] || return 0

	case ${CLAUDE_PLUGIN_OPTION_INJECT_ADR_CONTEXT:-} in
	false | 0) return 0 ;;
	esac

	adr_dir=${CLAUDE_PLUGIN_OPTION_ADR_DIR:-docs/adr}
	while :; do
		case $adr_dir in
		?*/) adr_dir=${adr_dir%/} ;;
		*) break ;;
		esac
	done
	case $adr_dir in
	'' | /* | *..* | *[!A-Za-z0-9._/-]*) return 0 ;;
	esac

	dir=$CLAUDE_PROJECT_DIR/$adr_dir
	if [ ! -d "$dir" ] || [ -L "$dir" ]; then
		return 0
	fi

	set --
	for f in "$dir"/[0-9][0-9][0-9][0-9]-*.md; do
		if [ ! -f "$f" ] || [ -L "$f" ] || [ ! -r "$f" ]; then
			continue
		fi
		set -- "$@" "$f"
	done

	index=
	if [ $# -gt 0 ]; then
		index=$(adr_index "$@" 2>/dev/null) || index=
	fi

	out=
	if [ -n "$index" ]; then
		out="Architecture decision records (Accepted and Proposed):
$index

"
	fi
	out="${out}This project records architecture decisions as ADRs in $adr_dir/ (relative to the project root).
Rules:
- Before changing code in an area covered by an Accepted ADR, read that ADR.
- If a task would contradict an Accepted ADR, stop and name the ADR and the conflict before writing code. Never work around an ADR silently.
- Proposed ADRs are drafts under discussion, not constraints.
- ADRs are written by the user. Do not create or edit ADR content unless the user explicitly asks."

	printf '%s\n' "$out"
}

main 2>/dev/null
exit 0
