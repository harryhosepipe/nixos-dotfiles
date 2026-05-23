local terminal = "wezterm"
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
    hl.exec_cmd("handy --start-hidden")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "breeze_cursors")

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/nix/store/[a-z0-9]+-grim-[0-9.]+/bin/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/nix/store/[a-z0-9]+-xdg-desktop-portal-hyprland-[0-9.]+/libexec/.xdg-desktop-portal-hyprland-wrapped",
    "screencopy", "allow")
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

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Escape",
    hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("[float; move center; size 1200 800] " .. fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind("CTRL + M", hl.dsp.exec_cmd("~/.config/hypr/handy-toggle-notify.sh"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("sh -lc 'hyprctl reload && $HOME/.config/hypr/random-wallpaper.sh'"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("sh -lc '$HOME/.config/hypr/random-wallpaper.sh'"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/waybar/toggle-waybar.sh"))
hl.bind(mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("sh -lc 'pkill -SIGUSR2 -x waybar || pkill -SIGUSR2 -x .waybar-wrapped'"))
hl.bind(mainMod .. " + A",
    hl.dsp.exec_cmd(
        "sh -lc 'if pgrep -x pwvucontrol >/dev/null 2>&1; then pkill -x pwvucontrol; else pwvucontrol >/tmp/pwvucontrol.log 2>&1 & fi'"))
hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ state = 0 }))
hl.bind(altMod .. " + F", hl.dsp.window.fullscreen({ state = 1 }))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl kill"))

dofile(configDir .. "layouts/" .. layoutPreset .. ".lua")(hl, mainMod)

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -40, y = 0 }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 40, y = 0 }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -40 }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 40 }))

for i = 1, 10 do
    local key = i == 10 and "0" or tostring(i)
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind("Print", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d)\" - | wl-copy'"))
hl.bind("ALT + mouse:276", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d)\" - | wl-copy'"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp -d)\" - | swappy -f -'"))
hl.bind("CTRL + Print",
    hl.dsp.exec_cmd(
        "sh -lc 'mkdir -p \"$HOME/Pictures/Screenshots\" && grim \"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\"'"))
hl.bind("CTRL + SHIFT + Print",
    hl.dsp.exec_cmd(
        "sh -lc 'mkdir -p \"$HOME/Pictures/Screenshots\" && grim -g \"$(slurp -d)\" \"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\"'"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("sh -lc 'grim - | wl-copy'"))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",
    hl.dsp.exec_cmd("sh -c 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl -e4 -n2 set 5%+'"),
    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",
    hl.dsp.exec_cmd("sh -c 'command -v brightnessctl >/dev/null 2>&1 && brightnessctl -e4 -n2 set 5%-'"),
    { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl next'"),
    { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl play-pause'"),
    { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl play-pause'"),
    { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("sh -c 'command -v playerctl >/dev/null 2>&1 && playerctl previous'"),
    { locked = true })

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
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
