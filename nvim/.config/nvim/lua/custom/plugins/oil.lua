return {
  'stevearc/oil.nvim',
  opts = {
    -- Oil will take over directory buffers (e.g. `:e .`)
    default_file_explorer = false,
    -- Columns to display in the oil buffer
    columns = {
      'icon',
      -- "permissions",
      -- "size",
      -- "mtime",
    },
    -- Common keymaps - most are default, uncomment to customize
    -- keymaps = {
    --   ['g?'] = 'actions.show_help',
    --   ['<CR>'] = 'actions.select',
    --   ['<C-s>'] = { 'actions.select', opts = { vertical = true } },
    --   ['<C-h>'] = { 'actions.select', opts = { horizontal = true } },
    --   ['<C-t>'] = { 'actions.select', opts = { tab = true } },
    --   ['<C-p>'] = 'actions.preview',
    --   ['<C-c>'] = 'actions.close',
    --   ['<C-l>'] = 'actions.refresh',
    --   ['-'] = 'actions.parent',
    --   ['_'] = 'actions.open_cwd',
    --   ['`'] = 'actions.cd',
    --   ['~'] = { 'actions.cd', opts = { scope = 'tab' } },
    --   ['gs'] = 'actions.change_sort',
    --   ['gx'] = 'actions.open_external',
    --   ['g.'] = 'actions.toggle_hidden',
    --   ['g\\'] = 'actions.toggle_trash',
    -- },
    use_default_keymaps = true,
    -- view_options = {
    --   show_hidden = false,
    -- },
  },
  -- Most useful default keymaps that are now active:
  -- - : Go to parent directory
  -- <CR> : Open file/directory
  -- g? : Show help
  -- <C-p> : Preview file
  -- <C-l> : Refresh
  -- g. : Toggle hidden files
  -- <C-s>, <C-h>, <C-t> : Open in split/tab
  -- Optional dependencies for icons
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  keys = {
    {
      '-',
      '<cmd>Oil<CR>',
      desc = 'Open parent directory',
    },
  },
}
