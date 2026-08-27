-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Populate the focused command deck once per Hyprland session. The launcher
-- keeps the monitoring tools on workspace 2 and workspace 3 focused, then
-- waits for Ghost's welcome animation before opening Herdr there. Herdr
-- restores Codex in its saved Work session.
local home = os.getenv("HOME") or ""
o.exec_on_start(home .. "/.local/bin/osaka-startup-layout")
