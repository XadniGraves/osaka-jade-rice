-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- Populate the five-workspace command deck once per Hyprland session. The
-- launcher keeps workspace 3 focused and waits for Ghost's welcome animation
-- to finish before opening Codex there.
local home = os.getenv("HOME") or ""
o.exec_on_start(home .. "/.local/bin/osaka-startup-layout")
