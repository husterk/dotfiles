-- Setup Git status indicators in the linemode
require("git"):setup()

-- Setup Relative Motions (with optional config)
require("relative-motions"):setup({
  show_numbers = "relative",
  show_motion = true,
})
