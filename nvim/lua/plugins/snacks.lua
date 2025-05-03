return {
  "folke/snacks.nvim",
  opts = {
    ---@class snacks.explorer.Config
    picker = {
      sources = {
        explorer = {
          hidden = true, -- Show hidden files (including .gitignored)
          ignored = true,
        },
      },
    },
  },
}
