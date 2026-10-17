-- Omarchy's stock setup makes this a relative symlink to the current theme's
-- neovim.lua, which dangles here because ~/.config/nvim is itself a stow
-- symlink into ~/dotfiles. Load it via $HOME instead so it works for any user
-- and any repo location. The theme-hotreload plugin re-requires this module on
-- theme change, which re-runs dofile and picks up the new theme.
local path = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(path) == 0 then
  return {}
end
return dofile(path)
