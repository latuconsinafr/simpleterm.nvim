-- Highlight group management for simpleterm.nvim
local M = {}

-- Setup highlight groups that integrate with user's colorscheme
function M.setup()
  -- Simply link to FloatBorder for maximum compatibility
  -- This ensures the footer matches the border styling
  vim.api.nvim_set_hl(0, "SimpletermFooter", {
    link = "FloatBorder",
    default = true,
  })
end

-- Get mode icon based on current mode
function M.get_mode_icon(mode)
  local icons = {
    t = "󰠠", -- Terminal mode
    nt = "", -- Normal mode (in terminal)
    n = "", -- Normal mode
    v = "󱠆", -- Visual mode
    V = "󱠆", -- Visual line mode
    ["\22"] = "󱠆", -- Visual block mode (Ctrl-V)
    c = "󰻃", -- Command mode
    i = "󰠠", -- Insert mode
    R = "󰠠", -- Replay mode
  }

  return icons[mode] or mode:upper()
end

return M
