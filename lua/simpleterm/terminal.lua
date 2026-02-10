-- Core terminal functionality for simpleterm.nvim
local config = require("simpleterm.config")
local highlights = require("simpleterm.highlights")

local M = {}

-- Terminal state
local state = {
  buf = nil,
  win = nil,
  augroup = nil,
}

-- Get mode display text with optional position info
local function get_mode_text()
  local opts = config.get()
  if not opts.footer.enabled or not opts.footer.show_mode then
    return ""
  end

  local mode = vim.api.nvim_get_mode().mode
  local mode_icon = highlights.get_mode_icon(mode)
  local extra_info = ""

  -- Show position in normal/terminal-normal mode
  if opts.footer.show_position and (mode == "nt" or mode == "n") then
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
      local ok, cursor = pcall(vim.api.nvim_win_get_cursor, state.win)
      if ok and state.win and vim.api.nvim_win_is_valid(state.win) then
        local total_lines = vim.api.nvim_buf_line_count(state.buf)
        extra_info = string.format(" [%d/%d]", cursor[1], total_lines)
      end
    end
  end

  -- Show search count if searching
  if opts.footer.show_search_count and vim.v.hlsearch == 1 and vim.fn.getreg("/") ~= "" then
    local ok, search_count = pcall(vim.fn.searchcount, { recompute = 1, maxcount = -1 })
    if ok and search_count.total > 0 then
      extra_info = string.format(" [%d/%d]", search_count.current, search_count.total)
    end
  end

  return mode_icon .. extra_info
end

-- Update footer with current mode and info
local function update_footer()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local mode_text = get_mode_text()
  if mode_text == "" then
    return
  end

  local win_config = vim.api.nvim_win_get_config(state.win)
  local opts = config.get()

  win_config.footer = { { string.format("  %s  ", mode_text), "SimpletermFooter" } }
  win_config.footer_pos = opts.footer.position

  vim.api.nvim_win_set_config(state.win, win_config)
end

-- Setup autocmds for footer updates
local function setup_footer_autocmds()
  local opts = config.get()
  if not opts.footer.enabled then
    return
  end

  if not state.augroup then
    state.augroup = vim.api.nvim_create_augroup("SimpletermFooter", { clear = true })
  end

  -- Update on mode changes
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = state.augroup,
    callback = update_footer,
  })

  -- Update on cursor movement (for position tracking)
  if opts.footer.show_position then
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = state.augroup,
      buffer = state.buf,
      callback = update_footer,
    })
  end

  -- Update after search (for search count)
  if opts.footer.show_search_count then
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = state.augroup,
      callback = function()
        vim.defer_fn(update_footer, 50)
      end,
    })
  end

  -- Initial update
  vim.defer_fn(update_footer, 50)
end

-- Calculate window dimensions and position
local function calculate_window_config()
  local opts = config.get()
  local width = math.floor(vim.o.columns * opts.window.width)
  local height = math.floor(vim.o.lines * opts.window.height)

  -- Calculate position with offset
  local row = math.floor((vim.o.lines - height) / 2)
  row = row - math.floor(row * opts.window.row_offset)
  local col = math.floor((vim.o.columns - width) / 2)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    border = opts.window.border,
    style = "minimal",
  }

  -- Add footer if enabled
  if opts.footer.enabled then
    win_config.footer = { { "  󰠠  ", "SimpletermFooter" } }
    win_config.footer_pos = opts.footer.position
  end

  return win_config
end

-- Check if terminal buffer is visible in any window
local function is_terminal_visible()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return false
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.buf then
      return true, win
    end
  end

  return false
end

-- Toggle terminal visibility
function M.toggle()
  local opts = config.get()

  -- Check if terminal is already visible
  local visible, win = is_terminal_visible()
  if visible then
    -- Close the window
    vim.api.nvim_win_close(win, true)
    state.win = nil
    return
  end

  -- Create terminal buffer if needed
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    state.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[state.buf].buflisted = false
  end

  -- Open floating window
  local win_config = calculate_window_config()
  state.win = vim.api.nvim_open_win(state.buf, true, win_config)

  -- Setup footer updates
  setup_footer_autocmds()

  -- Start terminal if buffer is empty (first time)
  local is_empty = vim.api.nvim_buf_line_count(state.buf) == 1
    and vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] == ""

  if is_empty then
    vim.fn.termopen(opts.terminal.shell)
  end

  -- Enter insert mode if configured
  if opts.terminal.start_in_insert then
    vim.cmd("startinsert")
  end
end

-- Open terminal (if not already open)
function M.open()
  if not is_terminal_visible() then
    M.toggle()
  end
end

-- Close terminal (if open)
function M.close()
  local visible, win = is_terminal_visible()
  if visible then
    vim.api.nvim_win_close(win, true)
    state.win = nil
  end
end

-- Get terminal state (for debugging/advanced usage)
function M.get_state()
  return {
    buf = state.buf,
    win = state.win,
    is_valid = state.buf and vim.api.nvim_buf_is_valid(state.buf),
    is_visible = is_terminal_visible(),
  }
end

return M
