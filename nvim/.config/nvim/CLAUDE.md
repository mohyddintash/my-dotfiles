# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a modular Neovim configuration forked from [dam9000/kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim), which itself is based on [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). The configuration is split into multiple files for modularity while remaining small and fully documented.

**Key Philosophy**: This is a starting point for personal configuration, not a distribution. Every line should be readable and understandable by the user.

## Configuration Structure

### Entry Point
- `init.lua` - Main entry point that:
  - Sets leader key to `<space>`
  - Configures tab width to 4 spaces (not tabs)
  - Requires modular configuration files in sequence

### Core Module Loading Order (Critical)
1. `lua/options.lua` - Vim options and settings
2. `lua/keymaps.lua` - Basic keymaps and autocommands
3. `lua/lazy-bootstrap.lua` - Auto-installs lazy.nvim plugin manager
4. `lua/lazy-plugins.lua` - Loads all plugin definitions

### Plugin Architecture

**Plugin Manager**: Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management.

**Plugin Organization**:
- `lua/kickstart/plugins/*.lua` - Kickstart-provided plugins (one plugin per file)
- `lua/custom/plugins/*.lua` - User's custom plugins (auto-imported via `{ import = 'custom.plugins' }` in lazy-plugins.lua)

**Key Plugins** (lua/kickstart/plugins/):
- `lspconfig.lua` - LSP setup using mason.nvim, mason-lspconfig.nvim, mason-tool-installer.nvim, and fidget.nvim
- `treesitter.lua` - Syntax highlighting and code parsing
- `telescope.lua` - Fuzzy finder for files, grep, etc.
- `conform.lua` - Code formatting (format-on-save enabled except for C/C++)
- `blink-cmp.lua` - Auto-completion
- `which-key.lua` - Shows available keybindings
- `gitsigns.lua` - Git integration
- `neo-tree.lua` - File tree explorer (currently enabled)
- `tokyonight.lua` - Color scheme
- `mini.lua` - Collection of minimal plugins

**Custom Plugins**:
- `oil.lua` - File explorer mapped to `-` key (note: `default_file_explorer = false` so neo-tree remains primary)

### LSP Configuration (lua/kickstart/plugins/lspconfig.lua)

**LSP Architecture**:
- Uses Mason to automatically install LSP servers and tools
- Configured servers defined in the `servers` table (lines 210-252)
- Currently enabled: `astro`, `lua_ls`
- LSP keymaps are set dynamically on `LspAttach` autocmd (lines 62-164)

**LSP Keybindings** (all prefixed with `gr` for "goto reference"):
- `grn` - Rename
- `gra` - Code action
- `grr` - Find references (Telescope)
- `gri` - Go to implementation (Telescope)
- `grd` - Go to definition (Telescope)
- `grD` - Go to declaration
- `gO` - Document symbols (Telescope)
- `gW` - Workspace symbols (Telescope)
- `grt` - Go to type definition (Telescope)
- `<leader>th` - Toggle inlay hints (if supported)

**Adding New LSP Servers**:
1. Add server name and config to `servers` table in lua/kickstart/plugins/lspconfig.lua
2. Server will be auto-installed by mason-tool-installer
3. For server options, see `:help lspconfig-all` or the server's documentation

### Formatting (lua/kickstart/plugins/conform.lua)

- Format-on-save enabled by default (except C/C++)
- Manual format: `<leader>f`
- Configured formatters: `stylua` for Lua
- Add formatters in `formatters_by_ft` table

### Treesitter (lua/kickstart/plugins/treesitter.lua)

- Auto-installs parsers for configured languages
- Configured languages: astro, tsx, typescript, bash, c, diff, html, lua, luadoc, markdown, markdown_inline, query, vim, vimdoc
- Add new languages to `ensure_installed` table

## Common Commands and Workflows

### Plugin Management
- `:Lazy` - Open lazy.nvim UI to view/manage plugins
- `:Lazy update` - Update all plugins
- `:Lazy sync` - Install/update/clean plugins based on config

### LSP and Tools
- `:Mason` - Open Mason UI to view/install LSP servers and tools
- `:checkhealth` - Check Neovim health (useful for debugging)
- `:LspInfo` - Show LSP client info for current buffer
- `:ConformInfo` - Show conform.nvim formatter info

### Telescope
- `<space>sh` - Search help documentation
- `<space>sk` - Search keymaps
- `<space>sf` - Search files
- `<space>sg` - Search by grep
- `<space>sr` - Resume last telescope search

### Development Workflow

When adding a new plugin:
1. Create a new file in `lua/custom/plugins/` (e.g., `lua/custom/plugins/myplug.lua`)
2. Return a table with plugin spec (see existing files for examples)
3. Restart Neovim or run `:Lazy sync`

When modifying plugin configuration:
1. Edit the relevant file in `lua/kickstart/plugins/` or `lua/custom/plugins/`
2. Restart Neovim or reload config (`:source $MYVIMRC` may not work for all changes)

## Code Style

- **Indentation**: 4 spaces (set in init.lua) for this config repo
- **Plugin files**: Each plugin returns a table or list of tables
- **Modeline**: Files end with `-- vim: ts=2 sts=2 sw=2 et` for 2-space indent (Kickstart convention)
- **Lua style**: Use dot notation for module requires (e.g., `require 'module.name'` not `require('module.name')`)
- **Comments**: Extensive inline documentation following Kickstart philosophy

## Important Notes

- Leader key is `<space>` (set in init.lua before plugins load)
- Nerd Font is disabled by default (`vim.g.have_nerd_font = false`)
- Git status shows untracked `lua/custom/plugins/oil.lua` and modified kickstart files
- Configuration uses spaces not tabs (expandtab = true)
- This is a dotfiles repo symlinked to `~/.config/nvim`
