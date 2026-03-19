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

-- Footer update debounce: coalesce rapid CursorMoved events into one update
local footer_update_pending = false
-- Footer text cache: skip win_set_config when display hasn't changed
local last_footer_text = nil
-- Yank flash: timer handle for reverting the yank indicator
local yank_flash_timer = nil

-- Get mode display text with optional position info
local function get_mode_text()
  local opts = config.get()

  if not opts.footer.enabled or not opts.footer.show_mode then
    return ""
  end

  local mode = vim.api.nvim_get_mode().mode
  local mode_icon = highlights.get_mode_icon(mode, opts.footer.mode_icons)
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

-- Do the actual footer render (called after debounce)
local function do_update_footer()
  -- Don't overwrite the yank flash indicator while it's visible
  if yank_flash_timer then
    return
  end

  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local mode_text = get_mode_text()

  if mode_text == "" then
    return
  end

  local footer_text = string.format("  %s  ", mode_text)

  -- Skip the expensive win_set_config call if nothing changed
  if footer_text == last_footer_text then
    return
  end

  last_footer_text = footer_text

  local opts = config.get()

  -- Partial update: only pass footer fields, no need to round-trip nvim_win_get_config
  vim.api.nvim_win_set_config(state.win, {
    footer = { { footer_text, "SimpletermFooter" } },
    footer_pos = opts.footer.position,
  })
end

-- Flash a yank indicator in the footer, then revert to normal footer
local function flash_yank_footer()
  if not state.win or not vim.api.nvim_win_is_valid(state.win) then
    return
  end

  local opts = config.get()

  local icon = highlights.get_yank_icon(opts.footer.yank_icon)

  if not opts.footer.enabled or icon == false then
    return
  end

  -- Cancel any pending revert from a previous flash
  if yank_flash_timer then
    yank_flash_timer:stop()
    yank_flash_timer = nil
  end

  vim.api.nvim_win_set_config(state.win, {
    footer = { { string.format("  %s  ", icon), "SimpletermFooter" } },
    footer_pos = opts.footer.position,
  })

  yank_flash_timer = vim.defer_fn(function()
    yank_flash_timer = nil
    last_footer_text = nil
    do_update_footer()
  end, 1000)
end

-- Schedule a footer update, coalescing rapid calls (e.g. scroll events) into one
local function update_footer()
  if footer_update_pending then
    return
  end

  footer_update_pending = true

  vim.schedule(function()
    footer_update_pending = false
    do_update_footer()
  end)
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
    return false, nil
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == state.buf then
      return true, win
    end
  end

  return false, nil
end

-- Setup buffer-local keymaps for the terminal buffer
local function setup_terminal_keymaps()
  local opts = config.get()
  local key = opts.keymaps.clean_yank

  if not key then
    return
  end

  vim.keymap.set("x", key, function()
    local text
    -- PTY hard-wraps lines at exactly the terminal width. Lines shorter than
    -- that ended with a real newline (user pressed Enter, genuine multi-line
    -- output). We use this to decide whether to join lines or preserve \n.
    local pty_width = vim.api.nvim_win_get_width(state.win)

    local function join_pty_lines(lines)
      local result = {}
      for i, line in ipairs(lines) do
        result[#result + 1] = line
        if i < #lines then
          -- PTY wrap: line filled the full width → continuation, no real newline
          -- Real newline: line is shorter → preserve it
          result[#result + 1] = (#line == pty_width) and "" or "\n"
        end
      end
      return table.concat(result)
    end

    if vim.fn.exists("*getregion") == 1 then
      -- Neovim 0.10+: getregion() reads getpos("v") and getpos(".") which are
      -- live and correct inside a visual-mode callback. Returns one string per
      -- buffer line with no newline separators.
      local lines = vim.fn.getregion(
        vim.fn.getpos("."),
        vim.fn.getpos("v"),
        { mode = vim.fn.mode() }
      )
      text = join_pty_lines(lines)
    else
      -- Neovim < 0.10: noau normal! "zy is synchronous and executes in the
      -- current visual mode context, unlike feedkeys which re-queues keys.
      vim.cmd('noau normal! "zy')
      local lines = vim.split(vim.fn.getreg("z"), "\n", { plain = true })
      text = join_pty_lines(lines)
    end

    -- Exit visual mode before scratch buffer operations. The "x" keymap callback
    -- fires while visual mode is still technically active; nvim_buf_call would
    -- save/restore that state and apply the scratch buffer's ggVGy selection
    -- back onto the terminal buffer, making the whole buffer appear selected.
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
      "x", -- execute immediately, not re-queued
      false
    )

    -- Yank via a scratch buffer so Neovim's full yank pipeline fires —
    -- this respects clipboard=unnamedplus, clipboard=unnamed, TextYankPost
    -- hooks, and any other register/clipboard config automatically.
    -- nvim_buf_set_lines requires each element to be newline-free, so split first.
    local scratch_lines = vim.split(text, "\n", { plain = true })
    local scratch = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(scratch, 0, -1, false, scratch_lines)
    vim.api.nvim_buf_call(scratch, function()
      if #scratch_lines == 1 then
        vim.cmd("normal! 0y$")   -- charwise: single logical line
      else
        vim.cmd("normal! ggVGy") -- linewise: genuinely multi-line selection
      end
    end)
    vim.api.nvim_buf_delete(scratch, { force = true })

    flash_yank_footer()
  end, { buffer = state.buf, desc = "Clean yank selection (without PTY line breaks)" })
end

-- Toggle terminal visibility
function M.toggle()
  local opts = config.get()

  -- Check if terminal is already visible
  local visible, win = is_terminal_visible()

  if visible and win then
    -- Close the window
    vim.api.nvim_win_close(win, true)
    state.win = nil
    last_footer_text = nil

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

  -- Force wrap AFTER termopen: TermOpen autocmds (common in user configs) fire
  -- inside termopen() and often set nowrap, which would override an earlier setting.
  vim.wo[state.win].wrap = true

  -- Re-register keymaps every open so plugin reloads always get the latest version
  -- on the correct buffer. vim.keymap.set replaces any existing mapping safely.
  setup_terminal_keymaps()

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
  if visible and win then
    vim.api.nvim_win_close(win, true)
    state.win = nil
    last_footer_text = nil
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
