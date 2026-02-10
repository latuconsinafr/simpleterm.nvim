-- Highlight group management for simpleterm.nvim
local M = {}

-- Setup highlight groups that integrate with user's colorscheme
function M.setup()
  -- Get colors from existing highlight groups for better integration
  local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
  local float_border = vim.api.nvim_get_hl(0, { name = "FloatBorder" })
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })

  -- Use colorscheme colors if available, otherwise fallback to defaults
  local bg = normal_float.bg or vim.api.nvim_get_hl(0, { name = "Normal" }).bg
  local fg = comment.fg or float_border.fg

  -- Create/update our custom highlight group
  vim.api.nvim_set_hl(0, "SimpletermFooter", {
    fg = fg,
    bg = bg,
    bold = true,
    default = true, -- Allow user overrides
  })
end

-- Get mode icon based on current mode
function M.get_mode_icon(mode)
  local icons = {
    t = "󰠠",         -- Terminal mode
    nt = "",        -- Normal mode (in terminal)
    n = "",         -- Normal mode
    v = "󱠆",         -- Visual mode
    V = "󱠆",         -- Visual line mode
    ["\22"] = "󱠆", -- Visual block mode (Ctrl-V)
    c = "",         -- Command mode
    i = "",         -- Insert mode
  }

  return icons[mode] or mode:upper()
end

return M
