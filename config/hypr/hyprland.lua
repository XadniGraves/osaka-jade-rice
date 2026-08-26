-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- RuneLite loading screen: float and center
o.window({
  class = "net-runelite-client-RuneLite",
  initial_title = "RuneLite Launcher",
}, {
  float = true,
  center = true,
})

o.window({
  class = "net-runelite-client-RuneLite",
  initial_title = "RuneLite",
}, {
  workspace = "emptyn",
  maximize = true,
})

-- Kitty transparency, including the dedicated startup terminals.
o.window("(kitty|org\\.omarchy\\.startup-.*)", {
  opacity = "0.88 0.75",
})

-- Silent startup workspace assignments. Suppressing activation requests keeps
-- background applications from pulling focus away from workspace 3.
o.window("(spotify|Spotify)", {
  workspace = "1 silent",
  no_initial_focus = true,
  suppress_event = "activate activatefocus",
})

o.window("org\\.omarchy\\.startup-(terminal|btop)", {
  workspace = "2 silent",
  no_initial_focus = true,
  suppress_event = "activate activatefocus",
})

o.window("(vesktop|Vesktop)", {
  workspace = "4 silent",
  no_initial_focus = true,
  suppress_event = "activate activatefocus",
})

o.window("steam.*", {
  workspace = "5 silent",
  no_initial_focus = true,
  suppress_event = "activate activatefocus",
})

o.window("org\\.omarchy\\.startup-codex", {
  workspace = "3 silent",
})
