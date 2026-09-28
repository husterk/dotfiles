-- WezTerm Keybindings Documentation
-- =================================
-- Leader Key:
-- The <leader> key is set to CTRL + Space, with a timeout of 2000 milliseconds (2 seconds).
-- To execute any keybinding, press the <leader> key (CTRL + Space) first, then the corresponding key.
--
-- Keybindings:
-- 1. Tab Management:
--    - <leader>c: Create a new tab in the current pane's domain.
--    - <leader>x: Close the current pane (with confirmation).
--    - <leader>b: Switch to the previous tab.
--    - <leader>n: Switch to the next tab.
--    - <leader><number>: Switch to a specific tab (0–9).
--
-- 2. Pane Splitting:
--    - <leader>|: Split the current pane horizontally into two panes.
--    - <leader>-: Split the current pane vertically into two panes.
--
-- 3. Pane Navigation:
--    - <leader>h: Move to the pane on the left.
--    - <leader>j: Move to the pane below.
--    - <leader>k: Move to the pane above.
--    - <leader>l: Move to the pane on the right.
--
-- 4. Pane Resizing:
--    - <leader>LeftArrow: Increase the pane size to the left by 5 units.
--    - <leader>RightArrow: Increase the pane size to the right by 5 units.
--    - <leader>DownArrow: Increase the pane size downward by 5 units.
--    - <leader>UpArrow: Increase the pane size upward by 5 units.
--
-- 5. Status Line:
--    - The status line indicates when the leader key is active, displaying an ocean wave emoji (🌊).
--
-- Miscellaneous Configurations:
-- - Tabs are shown even if there's only one tab.
-- - The tab bar is located at the bottom of the terminal window.
-- - Tab and split indices are zero-based.

-- Create the config object
local wezterm = require("wezterm")
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- ============================
-- Colors
-- ============================
local color_scheme = "Catppuccin Mocha"
config.color_scheme = color_scheme

-- color scheme colors for easy access
local scheme_colors = {
  catppuccin = {
    mocha = {
      rosewater = "#f5e0dc",
      flamingo = "#f2cdcd",
      pink = "#f5c2e7",
      mauve = "#cba6f7",
      red = "#f38ba8",
      maroon = "#eba0ac",
      peach = "#fab387",
      yellow = "#f9e2af",
      green = "#a6e3a1",
      teal = "#94e2d5",
      sky = "#89dceb",
      sapphire = "#74c7ec",
      blue = "#89b4fa",
      lavender = "#b4befe",
      text = "#cdd6f4",
      subtext1 = "#bac2de",
      subtext0 = "#a6adc8",
      overlay2 = "#9399b2",
      overlay1 = "#7f849c",
      overlay0 = "#6c7086",
      surface2 = "#585b70",
      surface1 = "#45475a",
      surface0 = "#313244",
      base = "#1e1e2e",
      mantle = "#181825",
      crust = "#11111b",
    },
  },
}

local colors = {
  border = scheme_colors.catppuccin.mocha.lavender,
  tab_bar_active_tab_fg = scheme_colors.catppuccin.mocha.mauve,
  tab_bar_active_tab_bg = scheme_colors.catppuccin.mocha.crust,
  tab_bar_text = scheme_colors.catppuccin.mocha.crust,
  arrow_foreground_leader = scheme_colors.catppuccin.mocha.lavender,
  arrow_background_leader = scheme_colors.catppuccin.mocha.crust,
}

-- Custom config variables
local tab_style = "square"
local leader_prefix = utf8.char(0x1f30a) -- ocean wave

-- Basic Settings
config.automatically_reload_config = true
config.font = wezterm.font_with_fallback({ "JetBrainsMono Nerd Font", "JetBrainsMono" })
config.front_end = "WebGpu" -- Use WebGPU for better performance
config.font_size = 15

-- Tab Bar & Window
config.window_close_confirmation = "NeverPrompt"
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = true
config.window_decorations = "RESIZE" -- Cleaner look on macOS
config.default_cursor_style = "BlinkingBar"

-- Window Frame Styling
config.window_frame = {
  border_left_width = "0.15cell",
  border_right_width = "0.15cell",
  border_bottom_height = "0.1cell",
  border_top_height = "0.1cell",
  border_left_color = colors.border,
  border_right_color = colors.border,
  border_bottom_color = colors.border,
  border_top_color = colors.border,
}

-- Define the Leader key combination
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 2000 }

-- Define the Keys directly on the config object
config.keys = {
  -- TABS
  { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "b", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "0", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
  { key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
  { key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
  { key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
  { key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(4) },
  { key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(5) },
  { key = "6", mods = "LEADER", action = wezterm.action.ActivateTab(6) },
  { key = "7", mods = "LEADER", action = wezterm.action.ActivateTab(7) },
  { key = "8", mods = "LEADER", action = wezterm.action.ActivateTab(8) },
  { key = "9", mods = "LEADER", action = wezterm.action.ActivateTab(9) },

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

  -- PANE MANAGEMENT
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  { key = "LeftArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
  { key = "RightArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },
  { key = "DownArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
  { key = "UpArrow", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
}

-- Maximize window on startup.
wezterm.on("gui-startup", function(cmd)
  local _, _, window = wezterm.mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

--[[
============================
Tab Bar
============================
]]
--

local function tab_title(tab_info)
  local title = tab_info.tab_title
  -- if the tab title is explicitly set, take that
  if title and #title > 0 then
    return title
  end
  -- Otherwise, use the title from the active pane
  -- in that tab
  return tab_info.active_pane.title
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local title = " " .. tab.tab_index .. ": " .. tab_title(tab) .. " "
  local left_edge_text = ""
  local right_edge_text = ""

  if tab_style == "rounded" then
    title = tab.tab_index .. ": " .. tab_title(tab)
    title = wezterm.truncate_right(title, max_width - 2)
    left_edge_text = wezterm.nerdfonts.ple_left_half_circle_thick
    right_edge_text = wezterm.nerdfonts.ple_right_half_circle_thick
  end

  -- ensure that the titles fit in the available space,
  -- and that we have room for the edges.
  -- title = wezterm.truncate_right(title, max_width - 2)

  if tab.is_active then
    return {
      { Background = { Color = colors.tab_bar_active_tab_bg } },
      { Foreground = { Color = colors.tab_bar_active_tab_fg } },
      { Text = left_edge_text },
      { Background = { Color = colors.tab_bar_active_tab_fg } },
      { Foreground = { Color = colors.tab_bar_text } },
      { Text = title },
      { Background = { Color = colors.tab_bar_active_tab_bg } },
      { Foreground = { Color = colors.tab_bar_active_tab_fg } },
      { Text = right_edge_text },
    }
  end
end)

--[[
============================
Leader Active Indicator
============================
]]
--

wezterm.on("update-status", function(window, _)
  -- leader inactive
  local solid_left_arrow = ""
  local arrow_foreground = { Foreground = { Color = colors.arrow_foreground_leader } }
  local arrow_background = { Background = { Color = colors.arrow_background_leader } }
  local prefix = ""

  -- leader is active
  if window:leader_is_active() then
    prefix = " " .. leader_prefix

    if tab_style == "rounded" then
      solid_left_arrow = wezterm.nerdfonts.ple_right_half_circle_thick
    else
      solid_left_arrow = wezterm.nerdfonts.pl_left_hard_divider
    end

    local tabs = window:mux_window():tabs_with_info()

    if tab_style ~= "rounded" then
      for _, tab_info in ipairs(tabs) do
        if tab_info.is_active and tab_info.index == 0 then
          arrow_background = { Foreground = { Color = colors.tab_bar_active_tab_fg } }
          solid_left_arrow = wezterm.nerdfonts.pl_right_hard_divider
          break
        end
      end
    end
  end

  window:set_left_status(wezterm.format({
    { Background = { Color = colors.arrow_foreground_leader } },
    { Text = prefix },
    arrow_foreground,
    arrow_background,
    { Text = solid_left_arrow },
  }))
end)

return config
