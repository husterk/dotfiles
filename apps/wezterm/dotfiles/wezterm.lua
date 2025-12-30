-- ~/dotfiles/wezterm/.config/wezterm/wezterm.lua
local wezterm = require("wezterm")

-- Create the config object
local config = {}
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Basic Settings
config.automatically_reload_config = true
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrains Mono")
config.font_size = 14.0

-- Use Nushell as the default terminal shell
config.default_prog = { "/run/current-system/sw/bin/nu" }

-- Tab Bar & Window
config.window_close_confirmation = "NeverPrompt"
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE" -- Cleaner look on macOS
config.default_cursor_style = "BlinkingBar"

-- 2. Define the Leader key combination
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

-- 3. Define the Keys directly on the config object
config.keys = {
	-- SPLITS
	{ key = "\\", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "_", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- NAVIGATION
	{ key = "LeftArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "DownArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "UpArrow", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },

	-- CLOSE & ZOOM
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
}

-- Maximize window on startup.
wezterm.on("gui-startup", function(cmd)
	local _, _, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

-- Enable debugging of key events
-- - Uncomment the line below to see key event debug logs in wezterm's log file
-- - Type "ctrl+shift+L" to toggle the debug logging on.
-- - Type "ctrl+l" to toggle the debug logging off.
-- config.debug_key_events = true

return config
