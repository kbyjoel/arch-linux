-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Écran d'accueil : le dashboard snacks ne s'affiche qu'au lancement sans
-- argument ; ce keymap permet d'y revenir à la main (ex. après avoir fermé
-- tous les buffers).
vim.keymap.set("n", "<leader>H", function()
  Snacks.dashboard()
end, { desc = "Dashboard (accueil)" })
