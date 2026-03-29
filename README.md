# dotfiles

Personal dotfiles for an [Omarchy](https://omarchy.org/) setup on Arch Linux with Hyprland.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each package is a directory that mirrors `$HOME`. Stow creates symlinks from
`~/.config/<pkg>` → `~/dotfiles/<pkg>/.config/<pkg>`.

```
~/dotfiles/
├── hyprland/       → ~/.config/hypr/
├── waybar/         → ~/.config/waybar/
├── nvim/           → ~/.config/nvim/        (active nvim config)
├── nvim-lazyvim/   → ~/.config/nvim/        (switch to activate)
├── nvim-nvchad/    → ~/.config/nvim/        (switch to activate)
├── ghostty/        → ~/.config/ghostty/
├── kitty/          → ~/.config/kitty/
├── alacritty/      → ~/.config/alacritty/
├── git/            → ~/.config/git/
├── fish/           → ~/.config/fish/
├── tmux/           → ~/.config/tmux/
├── zed/            → ~/.config/zed/
├── mako/           → ~/.config/mako/
├── walker/         → ~/.config/walker/
├── btop/           → ~/.config/btop/
├── fastfetch/      → ~/.config/fastfetch/
├── lazygit/        → ~/.config/lazygit/
├── lazydocker/     → ~/.config/lazydocker/
├── mise/           → ~/.config/mise/
├── imv/            → ~/.config/imv/
├── makima/         → ~/.config/makima/
├── swayosd/        → ~/.config/swayosd/
└── starship/       → ~/.config/starship.toml
```

## Install on a new machine

```bash
# 1. Install stow
sudo pacman -S stow

# 2. Clone
git clone git@github.com:mohyddintash/my-dotfiles.git ~/dotfiles

# 3. Stow all packages at once
cd ~/dotfiles
stow -t ~ hyprland waybar nvim ghostty kitty alacritty git fish tmux zed \
         mako walker btop fastfetch lazygit lazydocker mise imv makima \
         swayosd starship
```

## Switching nvim distros

Three nvim configs are available — only one can be active at a time since they
all symlink to `~/.config/nvim`.

```bash
cd ~/dotfiles

# Switch to LazyVim
stow -D -t ~ nvim
stow -t ~ nvim-lazyvim

# Switch to NvChad
stow -D -t ~ nvim-lazyvim
stow -t ~ nvim-nvchad

# Switch back to main config
stow -D -t ~ nvim-nvchad   # or nvim-lazyvim
stow -t ~ nvim
```

## Adding a new package

```bash
# 1. Create the package structure
mkdir -p ~/dotfiles/<pkg>/.config/<pkg>

# 2. Move the config into it
mv ~/.config/<pkg> ~/dotfiles/<pkg>/.config/

# 3. Stow it
cd ~/dotfiles && stow -t ~ <pkg>

# 4. Commit
git add <pkg> && git commit -m "feat: add <pkg> package"
```

## Important: Omarchy config commands

Omarchy provides commands that affect these configs. Know the difference:

| Command | Effect | Safe? |
|---------|--------|-------|
| `omarchy-restart-<app>` | Reloads the running process | ✅ always safe |
| `omarchy-restart-hyprctl` | Reloads Hyprland config (`hyprctl reload`) | ✅ always safe |
| `omarchy-refresh-<app>` | **Overwrites config with omarchy defaults** (creates `.bak` first) | ⚠️ destructive |

Never run `omarchy-refresh-*` unless you intend to reset that config to omarchy
defaults. If you accidentally do, your config is backed up with a timestamp suffix
(e.g. `config.jsonc.bak.1234567890`) and also recoverable from this git repo.

## Branches

| Branch | Contents |
|--------|----------|
| `master` | Current Omarchy setup — all active configs |
| `old-distro-backup` | Previous distro configs (i3, polybar, wofi, etc.) preserved for reference |
