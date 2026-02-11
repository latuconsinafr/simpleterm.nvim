-- simpleterm.nvim - A minimal, fast, and beautiful floating terminal for Neovim
-- Main entry point

local M = {}

local config = require("simpleterm.config")
local highlights = require("simpleterm.highlights")
local terminal = require("simpleterm.terminal")

-- Plugin state
local _initialized = false

-- Setup function - called by users in their config
function M.setup(opts)
  if _initialized then
    vim.notify("simpleterm.nvim: Already initialized", vim.log.levels.WARN)

    return
  end

  -- Setup configuration
  config.setup(opts)

  -- Setup highlight groups
  highlights.setup()

  -- Re-setup highlights when colorscheme changes
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("SimpletermHighlights", { clear = true }),

    callback = function()
      highlights.setup()
    end,
  })

  -- Setup default keymap if configured
  local user_config = config.get()

  if user_config.keymaps.toggle then
    vim.keymap.set({ "n", "t" }, user_config.keymaps.toggle, function()
      M.toggle()
    end, { desc = "Toggle Simpleterm", silent = true })
  end

  _initialized = true
end

-- Public API functions
M.toggle = terminal.toggle
M.open = terminal.open
M.close = terminal.close

-- Advanced API (for power users)
M.get_state = terminal.get_state
M.get_config = config.get

return M
