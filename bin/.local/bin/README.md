# tm-sessionizer

Note: You may need to install fzf if you haven't already (`pacman -S fzf`, `sudo apt install fzf`, `brew install fzf`, etc.).

## Use it

Assuming this package is stowed from the dotfiles dir (`stow bin`) and `~/.local/bin` is in your `$PATH`, from any terminal just type:

```sh
tm-sessionizer
```

An fzf menu will pop up listing project directories under `~/dev`, `~/projects`, and `~/work`. Start typing the name of any project, use the arrow keys to select, press Enter, and you'll be dropped directly into its tmux session.

Under the hood, `tm-sessionizer` uses `find` + `fzf` to pick a directory, then hands it off to `tmux-project-bootstrapper`, which creates (or attaches to) a tmux session for that project.

### Bootstrapping a single project directly

You can also call the bootstrapper directly for one project, skipping the fzf picker:

```sh
tmux-project-bootstrapper ~/dev/astro-mizar
```

# dev-setup

Launches the daily app layout into fixed workspaces: 3 terminals in `~/dev`, Firefox, Zen Browser, and Typora. Relies on the workspace-to-monitor pinning in `~/.config/hypr/monitors.conf` (ultrawide = workspaces 1-6, laptop = workspaces 7-0) to land each app on the right screen.

## Use it

```sh
dev-setup
```

Runs immediately, no prompt — safe to bind to a keybind later if you want to re-snap into the layout mid-session.

To add or remove an app, edit the `APPS` array at the top of the script — each entry is `"workspace|command"`.

## dev-setup-prompt

A confirmation wrapper around `dev-setup`, styled like Omarchy's own update-confirm popup (`gum style` + `gum confirm`). This is what actually runs at login — see `exec-once` in `~/.config/hypr/autostart.conf`, which opens it in a floating centered terminal a few seconds after you log in. Answering "No" just skips, leaving a clean desktop.
