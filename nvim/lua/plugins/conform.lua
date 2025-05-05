return {
  "stevearc/conform.nvim",

  default_format_opts = {
    lsp_format = "fallback",
  },
  -- If this is set, Conform will run the formatter on save.
  -- It will pass the table to conform.format().
  -- This can also be a function that returns the table.
  format_on_save = {
    -- I recommend these options. See :help conform.format for details.
    lsp_format = "fallback",
    timeout_ms = 500,
  },
  -- If this is set, Conform will run the formatter asynchronously after save.
  -- It will pass the table to conform.format().
  -- This can also be a function that returns the table.
  format_after_save = {
    lsp_format = "fallback",
  },

  formatters_by_ft = {
    sql = { "sqlfluff" },
  },
  formatters = {
    sqlfluff = {
      command = "sqlfluff",
      args = { "format", "--dialect=postgres", "-" },
      stdin = true,
    },
  },
}
