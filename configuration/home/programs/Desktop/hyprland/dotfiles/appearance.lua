-- 外观：间距、边框、圆角、阴影、模糊、光标、动画

hl.config({
    general = {
        gaps_in     = 10,
        gaps_out    = 10,
        border_size = 3,

        resize_on_border = true,
        allow_tearing    = false,
    },

    decoration = {
        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 3,
            offset       = {0, 5},
            color        = "rgba(00000077)",
        },

        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            noise    = 0.02,
            vibrancy = 0.3,
        },
    },

    animations = {
        enabled = true,
    },

    -- niri: hide-after-inactive-ms 3000；Hyprland 单位为秒
    cursor = {
        inactive_timeout = 3,
    },
})

-- 动画曲线（Hyprland 默认集，未使用 niri 的 pop-drop.kdl）
hl.curve("easeOutQuint",   { type = "bezier", points = {{0.23, 1},    {0.32, 1}} })
hl.curve("easeInOutCubic", { type = "bezier", points = {{0.65, 0.05}, {0.36, 1}} })
hl.curve("linear",         { type = "bezier", points = {{0, 0},       {1, 1}} })
hl.curve("almostLinear",   { type = "bezier", points = {{0.5, 0.5},   {0.75, 1}} })
hl.curve("quick",          { type = "bezier", points = {{0.15, 0},    {0.1, 1}} })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })
