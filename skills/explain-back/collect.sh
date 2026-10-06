#!/bin/sh
# Prints the git state for /own:explain-back.
#
# Always exits 0: a failing command injected into a skill aborts the whole skill
# invocation, and plain git commands fail outside a repository or before the
# first commit.

MAX_LINES=200

# section <title> <text>
section() {
	printf '### %s\n' "$1"
	if [ -z "$2" ]; then
		echo '(none)'
	else
		printf '%s\n' "$2" | awk -v max="$MAX_LINES" 'NR <= max { print } END { if (NR > max) print "… " NR - max " more" }'
	fi
	echo
}

main() {
	if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		echo 'Not a git repository.'
		return
	fi

	status=$(git status --short 2>/dev/null)
	untracked=$(git ls-files --others --exclude-standard 2>/dev/null)
	if git rev-parse --verify --quiet HEAD >/dev/null 2>&1; then
		changed_title='Changed files (vs HEAD)'
		changed=$(git diff --stat HEAD 2>/dev/null)
	else
		echo 'No commits yet.'
		echo
		changed_title='Staged files (no commits yet)'
		changed=$(git diff --stat --cached 2>/dev/null)
	fi

	if [ -z "$status" ] && [ -z "$untracked" ] && [ -z "$changed" ]; then
		echo 'No uncommitted changes.'
		return
	fi

	section 'Working tree' "$status"
	section "$changed_title" "$changed"
	section 'Untracked files' "$untracked"
}

main 2>/dev/null
exit 0
