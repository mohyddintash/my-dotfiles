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
