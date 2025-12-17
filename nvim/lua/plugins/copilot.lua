return {
  "zbirenbaum/copilot.lua",
  opts = {
    copilot_node_command = vim.fn.expand("$HOME") .. "/.local/share/fnm/node-versions/v25.2.1/installation/bin/node",
    server_opts_overrides = {
      settings = {
        telemetry = {
          telemetryLevel = "off",
        },
      },
    },
  },
}
