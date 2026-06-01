#!/bin/sh
set -eu

TMUX_BIN="$(command -v tmux || { echo 'tmux not found' >&2; exit 1; })"
WOFI_BIN="$(command -v wofi || { echo 'wofi not found' >&2; exit 1; })"
GHOSTTY_BIN="$(command -v ghostty || { echo 'ghostty not found' >&2; exit 1; })"
HYPRCTL_BIN="$(command -v hyprctl || true)"
JQ_BIN="$(command -v jq || true)"

new_label="+ New tmux session"

wofi_menu() {
	"$WOFI_BIN" \
		--dmenu \
		--insensitive \
		--matching fuzzy \
		--prompt "$1" \
		--width 520 \
		--height 420
}

sessions="$("$TMUX_BIN" list-sessions -F '#{session_name}' 2>/dev/null || true)"
choice="$(printf '%s\n%s\n' "$new_label" "$sessions" | sed '/^$/d' | wofi_menu "tmux sessions" || true)"
[ -n "$choice" ] || exit 0

if [ "$choice" = "$new_label" ]; then
	session="$(printf '' | wofi_menu "new session name" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' || true)"
	[ -n "$session" ] || exit 0

	if "$TMUX_BIN" has-session -t "$session" 2>/dev/null; then
		create=0
	else
		create=1
	fi
else
	session="$choice"
	create=0
fi

session_id="$(printf '%s' "$session" | cksum | awk '{print $1}')"
window_class="tmux-session-$session_id"
window_title="tmux: $session"

ghostty_tmux() {
	exec "$GHOSTTY_BIN" \
		--class="$window_class" \
		--title="$window_title" \
		--shell-integration-features=cursor,no-sudo,no-ssh-env,no-ssh-terminfo,path \
		-e "$@"
}

hypr_focus_workspace() {
	case "$1" in
		*[!0-9]*)
			"$HYPRCTL_BIN" dispatch "hl.dsp.focus({ workspace = 'name:$1' })" >/dev/null
			;;
		*)
			"$HYPRCTL_BIN" dispatch "hl.dsp.focus({ workspace = $1 })" >/dev/null
			;;
	esac
}

hypr_focus_window() {
	"$HYPRCTL_BIN" dispatch "hl.dsp.focus({ window = 'address:$1' })" >/dev/null
}

focus_existing_window() {
	[ -n "$HYPRCTL_BIN" ] || return 1
	[ -n "$JQ_BIN" ] || return 1

	window="$(
		"$HYPRCTL_BIN" clients -j |
			"$JQ_BIN" -r \
				--arg class "$window_class" \
				--arg title "$window_title" \
				'.[] | select(.class == $class or (.class == "tmux-session" and .title == $title)) | [.address, .workspace.name] | @tsv' |
			head -n 1
	)"

	address="$(printf '%s' "$window" | awk 'BEGIN { FS = "\t" } { print $1 }')"
	workspace="$(printf '%s' "$window" | awk 'BEGIN { FS = "\t" } { print $2 }')"
	[ -n "$address" ] || return 1
	[ -n "$workspace" ] || return 1

	hypr_focus_workspace "$workspace"
	hypr_focus_window "$address"
}

focus_legacy_attached_window() {
	[ -n "$HYPRCTL_BIN" ] || return 1
	[ -n "$JQ_BIN" ] || return 1
	"$TMUX_BIN" list-clients -F '#{client_session}' 2>/dev/null | grep -Fx "$session" >/dev/null || return 1

	windows="$(
		"$HYPRCTL_BIN" clients -j |
			"$JQ_BIN" -r \
				'.[] | select(.class == "com.mitchellh.ghostty" and .title == "tmux attach") | [.address, .workspace.name] | @tsv'
	)"

	[ "$(printf '%s\n' "$windows" | sed '/^$/d' | wc -l)" -eq 1 ] || return 1

	address="$(printf '%s' "$windows" | awk 'BEGIN { FS = "\t" } { print $1 }')"
	workspace="$(printf '%s' "$windows" | awk 'BEGIN { FS = "\t" } { print $2 }')"
	[ -n "$address" ] || return 1
	[ -n "$workspace" ] || return 1

	hypr_focus_workspace "$workspace"
	hypr_focus_window "$address"
}

if [ -n "${TMUX-}" ]; then
	if [ "$create" -eq 1 ] && ! "$TMUX_BIN" has-session -t "$session" 2>/dev/null; then
		"$TMUX_BIN" new-session -ds "$session"
	fi

	exec "$TMUX_BIN" switch-client -t "$session"
fi

if [ "$create" -eq 0 ] && { focus_existing_window || focus_legacy_attached_window; }; then
	exit 0
fi

if [ "$create" -eq 1 ]; then
	ghostty_tmux "$TMUX_BIN" new-session -s "$session"
fi

ghostty_tmux "$TMUX_BIN" attach-session -t "$session"
