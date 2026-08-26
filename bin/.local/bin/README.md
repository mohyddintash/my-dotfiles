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
tmux-project-bootstrapper ~/dev/astro-themes/pixeleers
```

# dev-setup

Launches a daily app layout into fixed workspaces: terminals, browsers, editor, whatever you configure. Relies on the workspace-to-monitor pinning in `~/.config/hypr/monitors.lua` (ultrawide = workspaces 1-6, laptop = workspaces 7-0) to land each app on the right screen.

The app list is **data, not code**, and lives in **profiles** — YAML files under `~/.config/dev-setup/profiles/` (stowed from `~/dotfiles/dev-setup/.config/dev-setup/profiles/`), not in the script itself. Ships with one profile, `default`, but you can add more (e.g. `work`, `personal`, `browsing`) — see below.

## Use it

```sh
dev-setup          # uses the "default" profile
dev-setup work      # uses profiles/work.yml instead
```

Runs immediately, no prompt — safe to bind to a keybind later if you want to re-snap into the layout mid-session.

## Profiles — `~/.config/dev-setup/profiles/*.yml`

Each file is a complete, independent layout using the schema below. To add a new profile (say, `work`), copy the **template** — not `default.yml`, which is your real working profile and carries your actual project paths:

```sh
cp ~/.config/dev-setup/profiles/TEMPLATE.yml.example ~/.config/dev-setup/profiles/work.yml
# edit work.yml's placeholder values (marked in the template's comments)
```

`TEMPLATE.yml.example` is a fully-commented reference covering every field — it's deliberately named `*.yml.example`, not `*.yml`, so it's never picked up as a real, selectable profile itself. No script changes needed to add a profile — `dev-setup work` picks it up immediately, and `dev-setup-prompt`'s profile picker (see below) appears automatically once a second profile file exists.

### Schema

```yaml
terminal: "uwsm-app -- alacritty"   # default terminal emulator launch command

apps:
  - id: term-dev
    workspace: 2
    terminal: true
    cwd: ~/dev

  - id: term-pixeleers
    workspace: 2
    terminal: true
    cwd: /home/mo/dev/astro-themes/pixeleers
    run: npm run dev              # optional: command to run on start

  - id: firefox
    workspace: 3
    cmd: "uwsm-app -- firefox"
```

Every entry needs a unique `id` (used to target overrides — see below) and a `workspace` number. Then either:

- `terminal: true` + `cwd`, and optionally `run` — opens the default terminal (or whatever `terminal:` at the top of the file is set to) in that working directory. If `run` is set, it executes on start and then drops you into an interactive shell, so the terminal stays open and usable afterward (e.g. leave a dev server running and still have a usable prompt).
- `cmd` — a literal full launch command, for anything that isn't a terminal (a browser, an editor, ...).

`run` is just a shell command string — chain multiple steps exactly like you would on a normal command line:

```yaml
run: cd subdir && npm install && npm run dev
run: npm run lint && npm run build && npm run preview
```

**Note:** `terminal:` at the top of the file applies to every `terminal: true` entry in that profile — there's currently no way to give individual entries a different terminal emulator within the same profile.

To add, remove, or edit an app: just edit the profile's YAML file. Nothing else needs updating — the login popup's summary text is generated from it every time, not hand-maintained.

## dev-setup-prompt

The interactive wrapper around `dev-setup`, styled like Omarchy's own update-confirm popup (`gum style`). This is what actually runs at login — see `o.exec_on_start(...)` in `~/.config/hypr/autostart.lua`, which opens it in a floating centered terminal a few seconds after you log in.

**To run it manually** (re-trigger the popup any time, not just at login):

```sh
omarchy-launch-floating-terminal-with-presentation dev-setup-prompt
```

(Running `dev-setup-prompt` directly also works, just without the floating/centered window treatment — it needs a real TTY either way.)

1. **Profile picker** — only shown if more than one profile exists; with just `default`, this step is skipped.
2. A live summary of the chosen profile, then three choices (`gum choose`):
   - **Launch now** — runs `dev-setup` exactly as configured.
   - **Customize** — first shows a checkbox list of *every* entry in that profile — terminals and apps alike, across every workspace (space to select, enter to confirm). Only the ones you pick get prompted, one-off, for this login only:
     - a terminal entry asks for a replacement `run` command (blank = plain shell, no command)
     - a plain-`cmd` entry (Firefox, Zen, Typora, ...) asks for a whole replacement launch command, pre-filled with its current one — e.g. swap Firefox for `uwsm-app -- google-chrome-stable --restore-last-session` just for today (blank = declined, keeps the configured default)

     Everything you don't select is left exactly as configured. Nothing is written back to the profile's YAML file — it's a same-session override, gone after this launch.
   - **Skip** — leaves a clean desktop, does nothing.
