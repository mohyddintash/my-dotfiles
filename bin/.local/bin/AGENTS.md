# AGENTS.md — dev-setup / dev-setup-prompt maintenance notes

Agent-facing notes for maintaining `dev-setup` and `dev-setup-prompt`. See `README.md` in this directory for the user-facing description.

## Dependencies

- `hyprctl eval` — dispatches each app into a workspace via
  `hl.dsp.exec_cmd(cmd, { workspace = "N silent" })`, so no window-class
  match rules are needed. **Not** `hyprctl dispatch exec "[workspace N
  silent] cmd"` — that old bracket-modifier text broke under Quattro's
  Hyprland: `hyprctl dispatch <X> <Y>` now evaluates as Lua `hl.dispatch(X
  Y)`, and the bracket text isn't valid Lua (confirmed by actually
  reproducing the parse error, then checking the current syntax against
  the live Hyprland wiki — `hyprwm/hyprland-wiki`,
  `content/Configuring/Basics/Dispatchers.md` — rather than guessing;
  Hyprland's dispatcher/rule syntax has changed multiple times before).
  `$cmd`, which may already contain its own quoting (see the `-ic "..."`
  case below), is passed through `jq -Rs .` first — that renders it as a
  JSON string literal, which is also valid Lua string syntax, so nothing
  has to be manually escaped.
- `uwsm-app --` — prefix used for every launch, for correct systemd scope tracking (matches the convention already used in `~/dotfiles/hyprland/.config/hypr/bindings.lua`).
- `gum` (`/usr/bin/gum`) — used by `dev-setup-prompt` for the styled box (`gum style`), the 3-way picker (`gum choose`), and the Customize input prompts (`gum input`). Same tool Omarchy's own `omarchy-update-confirm` uses.
- `yq` + `jq` — both already on this machine (`yq` here is the python-yq flavor: it converts YAML→JSON and pipes through `jq`, confirmed via `yq --version` reporting `jq-1.8.2`). `yq` reads each profile's YAML; `jq` extracts fields from each entry and builds/reads the override JSON. On a fresh machine: `sudo pacman -S yq jq`.
- `omarchy-launch-floating-terminal-with-presentation` — the Omarchy binary that opens `dev-setup-prompt` in a centered floating terminal, both at login and when run manually (`omarchy-launch-floating-terminal-with-presentation dev-setup-prompt` — see user-facing README). Do not reimplement this; it already has the correct window rule (`+floating-window` tag on `org.omarchy.terminal`) in `/usr/share/omarchy/default/hypr/apps/system.lua`.

## Workspace-to-monitor mapping

Defined in `~/dotfiles/hyprland/.config/hypr/monitors.lua` (stowed to `~/.config/hypr/monitors.lua`):

- Ultrawide (`HDMI-A-1`): workspaces 1-6
- Laptop (`eDP-1`): workspaces 7-0

Each `apps[]` entry's `workspace` in a profile file under
`dev-setup/.config/dev-setup/profiles/` (its own package, see `CLAUDE.md`'s
Packages table) must target a workspace number consistent with this split,
or an app will silently land on the wrong monitor. If the monitor pinning
in `monitors.lua` ever changes (e.g. different monitor names after a
hardware swap — check with `hyprctl monitors`), update both files together.

## Profiles — `dev-setup/.config/dev-setup/profiles/*.yml`

Each `.yml` file under `profiles/` is a complete, independent config using
the schema below — a "profile" (e.g. `default.yml`, `work.yml`,
`personal.yml`). There is no registry file listing them; both scripts just
glob `profiles/*.yml` at runtime, so **adding a profile is just adding a
file**. No script changes required.

`profiles/TEMPLATE.yml.example` is a fully-commented schema reference for
this purpose — copy it, not `default.yml` (which is a real profile with
the user's actual project paths in it, not a template). It's named
`*.yml.example` specifically so the `*.yml` glob in both scripts never
picks it up as a real, selectable profile.

`dev-setup` resolves which profile to use in this order: an explicit `$1`
(`dev-setup work` → `profiles/work.yml`), then `DEV_SETUP_CONFIG` (an
explicit path — used by the test-shim workflow below), then
`profiles/default.yml`. `dev-setup-prompt` lists `profiles/*.yml` basenames
and only shows a `gum choose` picker when there's more than one — with
just `default.yml` present, it's used with no picker shown, so the picker
"activates itself" the first time you add a second profile.

## Config schema (per profile file)

```yaml
terminal: "uwsm-app -- alacritty"   # default terminal emulator launch command

apps:
  - id: term-dev          # unique — used as the override key, see below
    workspace: 2
    terminal: true         # true = launched via `terminal:`, cwd/run apply
    cwd: ~/dev
    run: npm run dev       # optional; omit for a plain shell

  - id: firefox
    workspace: 3
    cmd: "uwsm-app -- firefox"   # non-terminal entry: literal launch command
```

`dev-setup` reads the resolved profile file with `yq -c '.apps[]'` (one
compact JSON object per line) and `jq` to pull fields out of each. A
`terminal: true` entry expands `cwd`'s leading `~` itself (yq/jq don't do
shell expansion) and, if `run` is set, launches `bash -ic "$run; exec
bash"` so the terminal stays open and usable after the startup command
finishes. A plain `cmd` entry is used as-is.

**To add/remove/edit an app: edit the profile's YAML file only.**
`dev-setup-prompt`'s popup summary is generated from it every time — there
is no separate static text to keep in sync anymore (the old bash-array
version of this script had that footgun; the YAML version doesn't).

**Do not put unverified example paths in a real profile file** —
`default.yml`'s `term-pixeleers` entry once pointed at `~/dev/astro-mizar`,
which doesn't exist on disk. That path wasn't invented from nothing: it was
copied from the pre-existing `tmux-project-bootstrapper ~/dev/astro-mizar`
example already sitting in this file's `tm-sessionizer` section (`mizar`
was the project's real former name before it was renamed to `pixeleers` —
confirmed via `git log --all` in that repo), just never checked against
the current filesystem before being reused elsewhere. Caught during user
testing, fixed to the real current path
(`/home/mo/dev/astro-themes/pixeleers`). Lesson: verify a path against the
actual filesystem (`ls`/`test -d`) before writing it into a config that
will actually run, even if it looks like it's drawn from something real —
"looks real" and "confirmed current" are not the same thing.

## Override mechanism — `DEV_SETUP_OVERRIDES`

`dev-setup-prompt`'s "Customize" choice lets you override **any entry in
any workspace** — terminal or plain-`cmd` — for one login only, without
touching the profile's YAML file. It's two steps:

1. A `gum choose --no-limit --label-delimiter=$'\t'` checkbox list of
   *every* entry in the profile (not just terminals) — options are built
   as `"<label>\t<id>"` pairs, so gum displays the label but the selection
   output is just the `id`s. This exists so you're only prompted for
   entries you actually want to change, not walked through every single
   one (the v2 version did the latter and it was tedious — flagged during
   user testing).
2. Only the selected `id`s get a `gum input` prompt, and what's being
   asked for differs by entry type:
   - `terminal: true` entry → replacement `run` command (pre-filled with
     the current one; blank is a *meaningful* override — plain shell, no
     command).
   - plain-`cmd` entry → replacement for the whole `cmd` (pre-filled with
     the current one; blank here means "declined" and is **not** recorded
     as an override, since an empty `cmd` would try to launch nothing —
     see the `[[ -n $answer ]] &&` guard in the plain-`cmd` branch).

   Everything not selected is left exactly as the profile has it.

The answers are collected into a JSON object mapping `id` → override
value (e.g. `{"term-pixeleers":"npm run build","firefox":"uwsm-app --
google-chrome-stable --restore-last-session"}`) and exported as
`DEV_SETUP_OVERRIDES` before calling `dev-setup`. Inside `dev-setup`, for
each entry `jq -r --arg id "$id" '.[$id] // empty'` looks up an override
for that `id` — applied to `run` for a `terminal: true` entry, applied to
`cmd` outright (full replacement) for a plain-`cmd` entry.

For "override the whole layout for this session" (swap every app, not
just one), a **profile** (see above) is still the better tool — this
mechanism is for one-off tweaks to a handful of entries within a profile.

**Gotcha:** don't default this var with `"${DEV_SETUP_OVERRIDES:-{}}"` —
bash misparses a literal `{}` inside a `${VAR:-default}` expansion and
leaks a stray `}` into the value when the var *is* set (confirmed by
testing: `FOO='{"a":1}'; echo "${FOO:-{}}"` prints `{"a":1}}`). Default it
across two lines instead — see the top of `dev-setup`.

## Testing changes

- Non-destructive dry run: shadow `hyprctl` with a `PATH`-prepended shim
  script that just echoes its arguments (e.g. `echo "DISPATCH: $*"`),
  named **exactly** `hyprctl` — a differently-named script won't shadow
  anything and `dev-setup` will silently launch real windows against the
  live Hyprland session instead. Verify the shim actually took effect
  (`command -v hyprctl` should print the `PATH`-prepended path) before
  trusting the output.
- Run `dev-setup` directly in a terminal (without the shim) to launch for
  real without the confirm prompt.
- Run `dev-setup-prompt` directly to test the popup and the 3-way choice —
  needs a real TTY; it will fail with `could not open a new TTY` in a
  non-interactive/sandboxed shell.
- After editing `monitors.lua` or `autostart.lua`, validate with
  `hyprctl reload && hyprctl configerrors`.
- The login popup itself (`o.exec_on_start(...)` in `autostart.lua`) only
  fires on a real login/reboot — `hyprctl reload` does not re-trigger it.
  Run `omarchy-launch-floating-terminal-with-presentation dev-setup-prompt`
  directly instead to test it without logging out.
