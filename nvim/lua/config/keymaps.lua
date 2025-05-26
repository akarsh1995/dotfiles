-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- assign a keymap to Dbee in which key style
-- also leader d is configured to debug but I don't want +debug keymapping in which key
vim.keymap.set("n", "<leader>db", "<cmd>Dbee<cr>", { desc = "Database" })
vim.keymap.set("n", "<C-a>", function()
  vim.cmd("normal! ggVG")
end, { desc = "Select whole buffer" })
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { desc = "Move Line Down" })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { desc = "Move Line Up" })
vim.keymap.set("i", "jk", "<ESC>", { desc = "Exit Insert Mode" })
