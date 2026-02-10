-- simpleterm.nvim - Plugin initialization
-- This file is automatically sourced by Neovim

-- Prevent loading plugin twice
if vim.g.loaded_simpleterm then
  return
end
vim.g.loaded_simpleterm = 1

-- Create user commands
vim.api.nvim_create_user_command("SimpletermToggle", function()
  require("simpleterm").toggle()
end, { desc = "Toggle floating terminal" })

vim.api.nvim_create_user_command("SimpletermOpen", function()
  require("simpleterm").open()
end, { desc = "Open floating terminal" })

vim.api.nvim_create_user_command("SimpletermClose", function()
  require("simpleterm").close()
end, { desc = "Close floating terminal" })
