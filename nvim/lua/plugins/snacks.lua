return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        ---@class snacks.explorer.Config
        explorer = {
          hidden = true, -- Show hidden files (including .gitignored)
          ignored = true,
          exclude = {
            ".git",
            ".svn",
            ".hg",
            ".DS_Store",
            "__pycache__",
            "*.pyc",
            "*.pyo",
            "node_modules",
          },
        },
      },
    },
  },
}
