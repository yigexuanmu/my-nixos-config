-- Hyprland 入口配置（home-manager 托管，改动后需 git add 再 switch）
-- 各段拆到 appearance / binds / rules，require 在文件末尾

------------------
---- MONITORS ----
------------------

hl.monitor({
    output    = "DP-1",
    mode      = "2560x1600@165",
    position  = "0x0",
    scale     = 1,
    transform = 0,
})

-- 未匹配的显示器兜底：首选分辨率，自动排到已有显示器右侧
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

------------------
---- 基本配置 ----
------------------

hl.config({
    general = {
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
    input = {
        kb_layout = "us",
        kb_model = "",
        kb_variant = "",
        kb_options = "",
        kb_rules = "",

        numlock_by_default = true,
        follow_mouse = 1,
        sensitivity = 0,
        accel_profile = "flat",

        touchpad = {
            tap_to_click = true,
            natural_scroll = true,
        },
    },
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = true,
    },
})

-------------------------------
---- 环境变量（对齐 niri） ----
-------------------------------

hl.env("LANG", "zh_CN.UTF-8")
hl.env("LC_ALL", "zh_CN.UTF-8")
hl.env("LC_MESSAGES", "zh_CN.UTF-8")
hl.env("LANGUAGE", "zh_CN:en")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("GTK_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("QT_IM_MODULES", "wayland;fcitx;ibus")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GSK_RENDERER", "gl")
hl.env("QS_ICON_THEME", "Papirus-Dark")

hl.env("XCURSOR_THEME", "Windows-Cursor")
hl.env("XCURSOR_SIZE", "48")
hl.env("HYPRCURSOR_SIZE", "48")

-------------------
---- 自启动 ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("noctalia")
    hl.exec_cmd("fcitx5 -d")

    -- waybar 的 tray 模块依赖 StatusNotifierWatcher（由 noctalia 提供），
    -- 与 noctalia 同时启动时 watcher 尚未注册，glibmm 抛出的 dbus 异常会 abort 掉 waybar。
    -- 延迟 1.5s 再启动，只起一次，不循环。
    hl.timer(function()
        hl.exec_cmd("waybar")
    end, { timeout = 1500, type = "oneshot" })
end)

-------------------
---- 分文件 ----
-------------------

require("appearance")
require("binds")
require("rules")

-- 配色由 noctalia 生成到 ~/.config/hypr/noctalia.lua（非托管文件），
-- 必须放在最后加载，否则会被上面的硬编码颜色覆盖。
-- 首次启动或 noctalia 未生成该文件时不报错。
local ok, theme = pcall(require, "noctalia")
if ok and theme and theme.apply_theme then
    theme.apply_theme()
end
