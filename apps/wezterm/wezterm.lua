-- ~/dotfiles/wezterm/.config/wezterm/wezterm.lua
local wezterm = require 'wezterm'
local config = {}
local mux = wezterm.mux

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Basic Settings
config.color_scheme = 'Catppuccin Macchiato' -- Or your preferred scheme
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 14.0

-- Use Nushell as the default terminal shell
config.default_prog = { '/run/current-system/sw/bin/nu' }

-- Tab Bar & Window
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE" -- Cleaner look on macOS

-- 2. Define the Leader (Try increasing timeout to 3000 for testing)
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 2000 }

-- 3. Define the Keys directly on the config object
config.keys = {
  -- SPLITS
  { key = '\\', mods = 'LEADER', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- NAVIGATION
  { key = 'LeftArrow', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Right' },
  { key = 'DownArrow', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Down' },
  { key = 'UpArrow', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Up' },

  -- CLOSE & ZOOM
  { key = 'x', mods = 'LEADER', action = wezterm.action.CloseCurrentPane { confirm = true } },
}

-- Maximize window on startup.
wezterm.on('gui-startup', function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

-- Remove the global close prompt.
config.window_close_confirmation = 'NeverPrompt'

-- Enable debugging of key events
-- - Uncomment the line below to see key event debug logs in wezterm's log file
-- - Type "ctrl+shift+L" to toggle the debug logging on.
-- - Type "ctrl+l" to toggle the debug logging off.
-- config.debug_key_events = true

return config
