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
-- Uses icons from config with fallback to uppercase mode letter
function M.get_mode_icon(mode, mode_icons)
  -- Use provided icons or fallback to uppercase mode letter
  return mode_icons[mode] or mode:upper()
end

return M
