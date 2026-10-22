#!/bin/sh
set -eu

# Ghostty windows, tabs and splits can share a PID. Use the focused surface's
# full-path title, maintained by Oh My Posh, rather than guessing a child shell.
window="$(hyprctl activewindow -j 2>/dev/null || printf '{}')"
directory="$(
	printf '%s' "$window" |
		jq -r 'select(.class == "com.mitchellh.ghostty") | .title // empty' 2>/dev/null || true
)"

# Oh My Posh abbreviates the home directory, even in its PWD template.
case "$directory" in
	'~') directory="$HOME" ;;
	'~/'*) directory="$HOME/${directory#\~/}" ;;
esac

case "$directory" in
	/*)
		if [ -d "$directory" ]; then
			exec strata "$directory"
		fi
		;;
esac

# Other apps, old terminal titles, or deleted directories use Strata's default.
exec strata
