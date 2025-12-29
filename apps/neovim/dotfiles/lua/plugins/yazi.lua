return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    -- Keybind to open Yazi in the current file's directory
    {
      "<leader>y",
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    -- Keybind to open Yazi in the project root
    {
      "<leader>Y",
      "<cmd>Yazi cwd<cr>",
      desc = "Open yazi in project root",
    },
  },
  opts = {
    -- if you want to replace netrw with yazi
    open_for_directories = true,
    keymaps = {
      show_help = "<f1>",
    },
  },
}
