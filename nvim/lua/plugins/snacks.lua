return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    explorer = {
      show_hidden = true, -- Show hidden files
      width = 30, -- Set the width of the explorer window
      auto_open = false, -- Automatically open the explorer on startup
      auto_close = true, -- Automatically close the explorer when it's the last window
    },
  },
}
