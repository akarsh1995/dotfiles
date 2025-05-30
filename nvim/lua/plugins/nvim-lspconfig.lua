return {
  "neovim/nvim-lspconfig",
  event = "LazyFile",
  dependencies = {
    "mason.nvim",
    { "williamboman/mason-lspconfig.nvim", config = function() end },
  },
  opts = {
    servers = {
      -- postgres_lsp = { enabled = true },
      sqls = { enabled = true },
      vtsls = {
        settings = {
          typescript = {
            preferences = {
              includeCompletionsForModuleExports = true,
              includeCompletionsForImportStatements = true,
              importModuleSpecifier = "relative",
              preferTypeOnlyAutoImports = true,
              includeAutomaticOptionalChainCompletions = true,
            },
          },
        },
      },
    },
  },
}
