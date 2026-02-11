# simpleterm.nvim

A minimal, fast, and beautiful floating terminal plugin for Neovim.


## 📸 Screenshots

![simpleterm demo](.github/assets/demo.gif)


## ✨ Features

- 🚀 **Fast** - Optimized for instant toggle performance
- 🎨 **Beautiful** - Smart mode indicator with position tracking
- ⚙️ **Configurable** - Sensible defaults, fully customizable
- 🎯 **Zero dependencies** - Pure Lua, works out of the box
- 🔄 **Persistent** - Terminal state preserved when toggled
- 🌈 **Colorscheme aware** - Automatically adapts to your theme
- 📚 **Well documented** - Built-in help docs (`:help simpleterm`)

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "latuconsinafr/simpleterm.nvim",
  config = function()
    require("simpleterm").setup()
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "latuconsinafr/simpleterm.nvim",
  config = function()
    require("simpleterm").setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'latuconsinafr/simpleterm.nvim'

" In your init.vim or after plug#end()
lua require("simpleterm").setup()
```

## 🚀 Quick Start

### Zero Configuration

Just install and use! The plugin works perfectly with default settings:

```lua
require("simpleterm").setup()
```

Press `<Alt-i>` to toggle the terminal.

### Basic Configuration

```lua
require("simpleterm").setup({
  window = {
    width = 0.8,        -- 80% of editor width
    height = 0.8,       -- 80% of editor height
    border = "rounded", -- Border style
  },
  keymaps = {
    toggle = "\\",   -- \ to toggle (set to false to disable)
  },
})
```

## ⚙️ Configuration

### Full Options

<details>
<summary>Click to see all configuration options</summary>

```lua
require("simpleterm").setup({
  -- Window configuration
  window = {
    width = 0.8,         -- Float: percentage (0.0-1.0), Int: columns
    height = 0.8,        -- Float: percentage (0.0-1.0), Int: rows
    border = "rounded",  -- "single", "double", "rounded", "solid", "shadow"
    row_offset = 0.1,    -- Vertical offset (0.0 = center, negative = up, positive = down)
  },

  -- Terminal configuration
  terminal = {
    shell = vim.o.shell,      -- Shell to use (defaults to system shell)
    start_in_insert = true,   -- Auto-enter insert mode when opening
  },

  -- Footer configuration
  footer = {
    enabled = true,           -- Show footer with mode indicator
    position = "right",       -- "left", "center", "right"
    show_mode = true,         -- Show mode icon
    show_position = true,     -- Show line position [current/total]
    show_search_count = true, -- Show search matches [current/total]
  },

  -- Keymaps
  keymaps = {
    toggle = "\\",         -- Set to false to disable default keymap
  },
})
```

</details>

### Examples

#### Minimal Setup (No Footer)

```lua
require("simpleterm").setup({
  footer = {
    enabled = false,
  },
})
```

#### Custom Size & Border

```lua
require("simpleterm").setup({
  window = {
    width = 0.9,
    height = 0.9,
    border = "double",
  },
})
```

#### Custom Keymap

```lua
require("simpleterm").setup({
  keymaps = {
    toggle = false, -- Disable default keymap
  },
})

-- Set your own keymap
vim.keymap.set({"n", "t"}, "<C-\\>", require("simpleterm").toggle, { desc = "Toggle terminal" })
```

## 🎮 Usage

### Default Keymap

- `\` - Toggle terminal (works in normal and terminal mode)

### Commands

- `:SimpletermToggle` - Toggle floating terminal
- `:SimpletermOpen` - Open floating terminal (if not already open)
- `:SimpletermClose` - Close floating terminal (if open)

### API

```lua
local simpleterm = require("simpleterm")

-- Toggle terminal
simpleterm.toggle()

-- Open terminal (if not already open)
simpleterm.open()

-- Close terminal (if open)
simpleterm.close()

-- Get current state (for advanced usage)
local state = simpleterm.get_state()
-- Returns: { buf, win, is_valid, is_visible }

-- Get current configuration
local config = simpleterm.get_config()
```

## 🎨 Customizing Colors

The plugin automatically adapts to your colorscheme by linking to `FloatBorder`.

To customize the footer appearance, override the `SimpletermFooter` highlight group:

```lua
-- After your colorscheme is loaded (e.g., in your init.lua after colorscheme line)
vim.api.nvim_set_hl(0, "SimpletermFooter", {
  fg = "#f6c177", -- Text color
  bg = "#1f1d2e", -- Background color
  bold = true,
})
```

## 📝 Tips

### Help Documentation

View complete documentation in Neovim:
```vim
:help simpleterm
```

### Escaping Terminal Mode

Press `<C-\><C-n>` to exit terminal mode (default Neovim behavior).

Or add this to your config for easier escaping:

```lua
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
```

### Multiple Terminals

Currently, simpleterm focuses on a single, persistent terminal. This keeps the plugin minimal and fast. For multiple terminals, consider [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) or [FTerm.nvim](https://github.com/numToStr/FTerm.nvim).

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

Inspired by the excellent terminal plugins in the Neovim ecosystem:
- [FTerm.nvim](https://github.com/numToStr/FTerm.nvim)
- [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim)
- [vim-floaterm](https://github.com/voldikss/vim-floaterm)
