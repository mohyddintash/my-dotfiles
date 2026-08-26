-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Prompt to launch the dev setup a few seconds after login.
-- Floats centered for free: omarchy-launch-floating-terminal-with-presentation
-- opens app-id org.omarchy.terminal, which Omarchy's own
-- ~/.local/share/omarchy/default/hypr/apps/system.lua already tags +floating-window.
-- Full design/rationale: bin/.local/bin/AGENTS.md
-- Not o.launch_on_start: that wraps in uwsm-app, which doesn't belong on a
-- bare `sleep && ...` shell chain (uwsm-app is for launching the actual app).
o.exec_on_start("sleep 4 && omarchy-launch-floating-terminal-with-presentation dev-setup-prompt")
