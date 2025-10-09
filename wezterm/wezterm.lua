-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Window appearance
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "NONE"
-- Remove macOS-specific fullscreen mode (causes hangs on Linux/Wayland)
-- config.native_macos_fullscreen_mode = true

-- Font & appearance
config.font = wezterm.font("JetBrains Mono Nerd Font", { weight = "Regular" })
config.font_size = 12.0
config.line_height = 1.2
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

-- Color scheme
config.color_scheme = "Tokyo Night"

-- Tab management
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_new_tab_button_in_tab_bar = false

-- Performance & behavior
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false

-- Graphics backend - use NVIDIA OpenGL
config.front_end = "Software"
-- config.webgpu_power_preference = "HighPerformance"

-- Key bindings (matches tmux/nvim navigation)
config.keys = {
	{ key = "h", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "l", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "k", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "j", mods = "CTRL|SHIFT", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
}

return config
