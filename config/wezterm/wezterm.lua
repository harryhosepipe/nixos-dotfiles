local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- config.enable_wayland = true
-- config.front_end = "WebGpu"

config.automatically_reload_config = true
config.check_for_updates = false

config.default_prog = { "zsh", "-l" }
config.default_cwd = wezterm.home_dir

config.font_dirs = {
	"/tmp/wezterm-font-preview.NQZhHS/TX-02",
}
config.font = wezterm.font_with_fallback({
	"TX-02",
	"Inconsolata Nerd Font Mono",
})
config.font_size = 14
config.line_height = 1.00
config.freetype_load_target = "Light"
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 1
config.text_background_opacity = 1.0
config.bold_brightens_ansi_colors = true

config.window_decorations = "NONE"
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.window_padding = {
	left = 12,
	right = 12,
	top = 10,
	bottom = 10,
}

config.initial_cols = 120
config.initial_rows = 34
config.adjust_window_size_when_changing_font_size = false

config.scrollback_lines = 20000
config.mouse_wheel_scrolls_tabs = false
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

config.cursor_blink_rate = 650
config.default_cursor_style = "BlinkingBar"

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	{
		key = "Enter",
		mods = "ALT",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnTab("CurrentPaneDomain"),
	},
	{
		key = "n",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			local cwd_uri = pane:get_current_working_dir()
			local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir

			window:perform_action(
				wezterm.action.SpawnCommandInNewWindow({
					cwd = cwd,
				}),
				pane
			)
		end),
	},
	{
		key = "h",
		mods = "ALT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "l",
		mods = "ALT",
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = "w",
		mods = "CTRL|SHIFT",
		action = wezterm.action.CloseCurrentTab({ confirm = false }),
	},
	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = "r",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ReloadConfiguration,
	},
	{
		key = "/",
		mods = "CTRL",
		action = wezterm.action.ShowLauncherArgs({
			flags = "FUZZY|KEY_ASSIGNMENTS",
		}),
	},
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "v",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = false }),
	},
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = { WheelUp = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(-2),
	},
	{
		event = { Down = { streak = 1, button = { WheelDown = 1 } } },
		mods = "NONE",
		action = wezterm.action.ScrollByLine(2),
	},
	{
		event = { Up = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action.CopyTo("ClipboardAndPrimarySelection"),
	},
}

return config
