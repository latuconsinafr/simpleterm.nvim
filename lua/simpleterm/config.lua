-- Configuration management for simpleterm.nvim
local M = {}

-- Default configuration
M.defaults = {
  -- Window configuration
  window = {
    width = 0.8,  -- 80% of editor width
    height = 0.8, -- 80% of editor height
    border = "rounded", -- "single", "double", "rounded", "solid", "shadow", or array
    row_offset = 0.1, -- Vertical offset (0.0 = center, negative = up, positive = down)
  },

  -- Terminal configuration
  terminal = {
    shell = vim.o.shell, -- Use system default shell
    start_in_insert = true, -- Auto-enter insert mode
  },

  -- Footer configuration
  footer = {
    enabled = true,
    position = "right", -- "left", "center", "right"
    show_mode = true,
    show_position = true, -- Show line position in normal mode
    show_search_count = true, -- Show search matches
    yank_icon = "󰆏",  -- Icon shown briefly after a clean yank (false to disable)
    -- Mode icons - customize icons for different modes
    -- Defaults cover common terminal modes, with fallback to mode letter for others
    mode_icons = {
      t = "󰠠",        -- Terminal mode
      nt = "",       -- Terminal-normal mode
      n = "",        -- Normal mode
      no = "󰪣",       -- Operator-pending mode (e.g. while typing gy + motion)
      v = "󱠆",        -- Visual mode
      V = "󱠆",        -- Visual line mode
      ["\22"] = "󱠆",  -- Visual block mode (Ctrl-V)
      c = "",        -- Command mode
      -- Any undefined mode will show as uppercase letter (e.g., "R", "I")
    },
  },

  -- Keymaps (set to false to disable default keymaps)
  keymaps = {
    toggle = "\\",      -- \ to toggle terminal (false to disable)
    clean_yank = "gy",  -- yank visual selection without PTY line breaks (false to disable)
  },
}

-- Current active configuration
M.options = {}

-- Setup configuration by merging user options with defaults
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  return M.options
end

-- Get current configuration
function M.get()
  return M.options
end

return M
