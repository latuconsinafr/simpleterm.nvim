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
  return mode_icons[mode] or mode:upper()
end

-- Get yank icon, with plain-text fallback for users without a Nerd Font
function M.get_yank_icon(yank_icon)
  if yank_icon == false then
    return false
  end
  return yank_icon or "Y"
end

return M
