local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.automatically_reload_config = true
config.check_for_updates = false

config.default_prog = { "zsh", "-l" }
config.default_cwd = wezterm.home_dir

config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
  "FiraCode Nerd Font",
})
config.font_size = 11.5
config.line_height = 1.08
config.freetype_load_target = "Light"
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.96
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
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.window_close_confirmation = "NeverPrompt"

config.cursor_blink_rate = 650
config.default_cursor_style = "BlinkingBar"

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
    key = "w",
    mods = "CTRL|SHIFT",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  },
  {
    key = "d",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "D",
    mods = "CTRL|SHIFT",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
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
}

return config
