-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- assign a keymap to Dbee in which key style
-- also leader d is configured to debug but I don't want +debug keymapping in which key
vim.keymap.set("n", "<leader>db", "<cmd>Dbee<cr>", { desc = "Database" })
