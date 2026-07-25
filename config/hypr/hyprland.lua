local terminal = "ghostty"
local fileManager = "thunar"
local browser = "firefox"
local menu = "wofi --show drun"
local layoutPreset = "scrolling"
local configDir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")

local mainMod = "SUPER"
local altMod = "ALT"

hl.monitor({
	output = "DP-1",
	mode = "4096x2160@59.98",
	position = "0x0",
	scale = 1.6,
})

hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("sh -lc '$HOME/.config/hypr/random-wallpaper.sh'")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("swaync")
	hl.exec_cmd("systemctl --user start handy.service")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "breeze_cursors")

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/nix/store/[a-z0-9]+-grim-[0-9.]+/bin/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission(
	"/nix/store/[a-z0-9]+-xdg-desktop-portal-hyprland-[0-9.]+/libexec/.xdg-desktop-portal-hyprland-wrapped",
	"screencopy",
	"allow"
)
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")

hl.config({
	general = {
		gaps_in = 2,
		gaps_out = 2,
		border_size = 1,
		col = {
			active_border = "rgba(44aa8877)",
			inactive_border = "rgba(00000000)",
		},
		resize_on_border = true,
		allow_tearing = false,
	},

	decoration = {
		rounding = 4,
		rounding_power = 4,
		active_opacity = 1.0,
		inactive_opacity = 0.9,
		shadow = {
			enabled = false,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
			color_inactive = "rgba(00000000)",
		},
		blur = {
			enabled = true,
			size = 3,
			passes = 1,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.layer_rule({
	name = "no-anim-for-selection",
	match = { namespace = "selection" },
	no_anim = true,
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

hl.config({
	input = {
		kb_layout = "us",
		kb_variant = "",
		kb_model = "",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})

-- Launchers and apps
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal), { description = "Open terminal" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("[float] " .. fileManager), { description = "Open file manager" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser), { description = "Open browser" })
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser), { description = "Open browser" })
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu), { description = "Open application launcher" })
hl.bind(
	mainMod .. " + T",
	hl.dsp.exec_cmd("sh -lc '$HOME/.config/hypr/tmux-session-menu.sh'"),
	{ description = "Open tmux sessions" }
)
hl.bind(
	mainMod .. " + A",
	hl.dsp.exec_cmd(
		"sh -lc 'if pgrep -x pwvucontrol >/dev/null 2>&1; then pkill -x pwvucontrol; else pwvucontrol >/tmp/pwvucontrol.log 2>&1 & fi'"
	),
	{ description = "Open audio controls" }
)

-- Window actions
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Close active window" })
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "Toggle floating window" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ state = 0 }), { description = "Toggle fullscreen" })
hl.bind(altMod .. " + F", hl.dsp.window.fullscreen({ state = 1 }), { description = "Toggle maximized window" })
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl kill"), { description = "Pick a window to close" })

-- Session and desktop controls
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock session" })
hl.bind(
	mainMod .. " + SHIFT + Escape",
	hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"),
	{ description = "Open session menu" }
)

hl.bind("CTRL + M", hl.dsp.exec_cmd("handy --toggle-transcription"), { description = "Toggle Handy recording" })
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("sh -lc "), { description = "Reserved shortcut" })
hl.bind(
	mainMod .. " + SHIFT + B",
	hl.dsp.exec_cmd("sh -lc '$HOME/.config/hypr/random-wallpaper.sh'"),
	{ description = "Choose a new wallpaper" }
)
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/waybar/toggle-waybar.sh"), { description = "Toggle Waybar" })
hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.exec_cmd("sh -lc 'pkill -SIGUSR2 -x waybar || pkill -SIGUSR2 -x .waybar-wrapped'"),
	{ description = "Reload Waybar" }
)

-- Layout-specific bindings
dofile(configDir .. "layouts/" .. layoutPreset .. ".lua")(hl, mainMod)

if layoutPreset == "scrolling" then
	hl.bind(mainMod .. " + comma", hl.dsp.layout("move -col"), { description = "Scroll layout left" })
	hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"), { description = "Scroll layout right" })
	hl.bind(mainMod .. " + SHIFT + H", hl.dsp.layout("swapcol l"), { description = "Move column left" })
	hl.bind(mainMod .. " + SHIFT + L", hl.dsp.layout("swapcol r"), { description = "Move column right" })
	hl.bind(mainMod .. " + CTRL + comma", hl.dsp.layout("colresize -conf"), { description = "Narrow active column" })
	hl.bind(mainMod .. " + CTRL + period", hl.dsp.layout("colresize +conf"), { description = "Widen active column" })
	hl.bind(mainMod .. " + backslash", hl.dsp.layout("fit active"), { description = "Fit active column to screen" })
	hl.bind(
		mainMod .. " + SHIFT + backslash",
		hl.dsp.layout("consume_or_expel next"),
		{ description = "Join or separate next window" }
	)
end

-- Focus navigation
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })

-- Window movement and resizing
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0 }), { description = "Shrink window horizontally" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 40, y = 0 }), { description = "Grow window horizontally" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -40 }), { description = "Shrink window vertically" })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 40 }), { description = "Grow window vertically" })

-- Workspaces
for i = 1, 10 do
	local key = i == 10 and "0" or tostring(i)
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "Go to workspace " .. i })
	hl.bind(
		mainMod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = false }),
		{ description = "Move window to workspace " .. i }
	)
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "Toggle scratch workspace" })
hl.bind(
	mainMod .. " + SHIFT + S",
	hl.dsp.window.move({ workspace = "special:magic" }),
	{ description = "Move window to scratch workspace" }
)

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d -w 0)\" - | wl-copy'"), { description = "Copy area screenshot" })
hl.bind("ALT + mouse:276", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d -w 0)\" - | wl-copy'"), { description = "Copy area screenshot" })
hl.bind(
	"SHIFT + Print",
	hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d -w 0)\" - | swappy -f -'"),
	{ description = "Capture and annotate an area" }
)
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(
		'sh -lc \'mkdir -p "$HOME/Pictures/Screenshots" && grim "$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"\''
	),
	{ description = "Save full-screen screenshot" }
)
hl.bind(
	"CTRL + SHIFT + Print",
	hl.dsp.exec_cmd(
		'sh -lc \'mkdir -p "$HOME/Pictures/Screenshots" && grim -g "$(slurp -d -w 0)" "$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"\''
	),
	{ description = "Save area screenshot" }
)
hl.bind("ALT + Print", hl.dsp.exec_cmd("sh -lc 'grim - | wl-copy'"), { description = "Copy full-screen screenshot" })

-- Mouse controls
hl.bind("mouse:276", hl.dsp.focus({ workspace = "e-1" }), { description = "Go to previous workspace" })
hl.bind("mouse:275", hl.dsp.focus({ workspace = "e+1" }), { description = "Go to next workspace" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Go to next workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Go to previous workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Drag active window" })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize active window" })

-- Hardware keys
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true, description = "Raise volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true, description = "Lower volume" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true, description = "Mute audio" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true, description = "Mute microphone" }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("sh -c 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl -e4 -n2 set 5%+'"),
	{ locked = true, repeating = true, description = "Raise screen brightness" }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("sh -c 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl -e4 -n2 set 5%-'"),
	{ locked = true, repeating = true, description = "Lower screen brightness" }
)
hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl next'"),
	{ locked = true, description = "Play next track" }
)
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl play-pause'"),
	{ locked = true, description = "Pause or resume media" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl play-pause'"),
	{ locked = true, description = "Play or pause media" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl previous'"),
	{ locked = true, description = "Play previous track" }
)

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "opaque-browsers",
	match = { class = "^(firefox|chromium|brave-browser)$" },
	opacity = "1.0 override 1.0 override 1.0 override",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},
	no_focus = true,
})

hl.window_rule({
	name = "move-hyprland-run",
	match = { class = "hyprland-run" },
	move = "20 monitor_h-120",
	float = true,
})

hl.window_rule({
	name = "file-manager-popup",
	match = { class = "thunar" },
	float = true,
	size = "1400 1100",
})

hl.window_rule({
	name = "audio-control-popup",
	match = { class = "com.saivert.pwvucontrol" },
	float = true,
	pin = true,
	size = "520 620",
	move = "monitor_w-540 42",
})

hl.window_rule({
	name = "move-signal-to-workspace-7",
	match = { class = "signal" },
	workspace = "7",
})

hl.window_rule({
	name = "move-whatsapp-to-workspace-7",
	match = {
		class = "electron",
		title = "WhatsApp Electron.*",
	},
	workspace = "7",
})

hl.window_rule({
	name = "move-telegram-7",
	match = { class = "org.telegram.desktop.*" },
	workspace = "7",
})
