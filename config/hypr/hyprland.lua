-- ============================================================
--  ZyraxonOS 9.0.0 — glass desktop
--  Hyprland configuration (Lua)
--  Real GPU blur, real transparency, real animation.
-- ============================================================

local mainMod = "SUPER"
local terminal = "kitty"
local menu     = "wofi --show drun --allow-images"
local files    = "thunar"

-- ---------------- monitors ----------------
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- ---------------- environment ----------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- ---------------- autostart ----------------
hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -i /usr/share/backgrounds/zyraxonos/aurora.png -m fill")
    hl.exec_cmd("waybar")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- ---------------- look and feel ----------------
hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 16,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(7c5cffee)", "rgba(00d4ffee)" }, angle = 45 },
            inactive_border = "rgba(ffffff22)",
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 22,
        rounding_power = 2.4,

        active_opacity   = 0.96,
        inactive_opacity = 0.86,

        dim_inactive = true,
        dim_strength = 0.06,

        shadow = {
            enabled      = true,
            range        = 32,
            render_power = 4,
            color        = 0x55000000,
        },

        blur = {
            enabled           = true,
            size              = 12,
            passes            = 4,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            noise             = 0.02,
            contrast          = 1.05,
            brightness        = 1.0,
            vibrancy          = 0.30,
            vibrancy_darkness = 0.0,
            popups            = true,
        },
    },

    animations = {
        enabled = true,
    },
})

-- ---------------- curves and animations ----------------
hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1, 1.1},  {0.1, 1.1}  } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3}, {0, 1}     } })
hl.curve("liner",  { type = "bezier", points = { {1, 1},      {1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 8,    bezier = "wind"  })
hl.animation({ leaf = "windows",       enabled = true, speed = 6,    bezier = "wind"  })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 6,    bezier = "winIn", style = "popin 88%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 4,    bezier = "winOut", style = "popin 88%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,    bezier = "wind"  })
hl.animation({ leaf = "border",        enabled = true, speed = 12,   bezier = "liner" })
hl.animation({ leaf = "borderangle",   enabled = true, speed = 30,   bezier = "liner", style = "loop" })
hl.animation({ leaf = "fade",          enabled = true, speed = 6,    bezier = "wind"  })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 6,    bezier = "wind"  })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 4,    bezier = "wind"  })
hl.animation({ leaf = "layers",        enabled = true, speed = 5,    bezier = "wind"  })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 5,    bezier = "wind", style = "slide" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 4,    bezier = "wind", style = "slide" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 6,    bezier = "wind", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 6,    bezier = "wind", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 6,    bezier = "wind", style = "slide" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "wind"  })

-- ---------------- layouts ----------------
hl.config({
    dwindle = {
        preserve_split   = true,
        smart_split      = false,
        smart_resizing   = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

-- ---------------- misc ----------------
hl.config({
    misc = {
        force_default_wallpaper   = 0,
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        mouse_move_enables_dpms   = true,
        key_press_enables_dpms    = true,
    },
})

-- ---------------- input ----------------
hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
            tap_to_click   = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- ---------------- keybinds ----------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + TAB",    hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(files))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

for i = 1, 5 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",  hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- ---------------- window rules ----------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "glass-kitty",
    match = { class = "^kitty$" },
    opacity = "0.94 0.86",
})

hl.window_rule({
    name  = "glass-thunar",
    match = { class = "^thunar$" },
    opacity = "0.96 0.88",
})

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^pavucontrol$" },
    float = true,
    size  = "800 600",
})

hl.window_rule({
    name  = "float-blueman",
    match = { class = "^blueman-manager$" },
    float = true,
})

hl.window_rule({
    name  = "float-nm",
    match = { class = "^nm-connection-editor$" },
    float = true,
})

-- ---------------- layer rules (blur the glass panels) ----------------
hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" },  blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-wofi",   match = { namespace = "^wofi$" },    blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-dunst",  match = { namespace = "^dunst$" },   blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "blur-lock",   match = { namespace = "^hyprlock$" }, blur = true, ignore_alpha = 0.2 })
