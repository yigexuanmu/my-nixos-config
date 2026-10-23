-- 窗口 / layer 规则

-- Firefox 画中画浮动
hl.window_rule({
    name  = "firefox-pip",
    match = { class = "firefox$", title = "^Picture-in-Picture$" },
    float = true,
})

-- noctalia 设置窗口
hl.window_rule({
    name  = "noctalia-settings",
    match = { class = "dev.noctalia.Noctalia.Settings" },
    float = true,
    size  = {1080, 920},
    center = true,
})

-- QQ 资料卡不抢焦点
hl.window_rule({
    name  = "qq-profile-card",
    match = { title = "^资料卡$" },
    no_initial_focus = true,
})

-- QQ 图片查看器
hl.window_rule({
    name  = "qq-image-viewer",
    match = { title = "^图片查看器$" },
    float = true,
    size  = {1200, 800},
    center = true,
})

-- noctalia 的 layer 表面：不做合成器模糊
-- 开启 blur 会把 layer 的矩形区域整体模糊，圆角外侧出现方块状模糊底色（dock 尤其明显）。
-- niri 的 layer-rule 里 blur 也是注释掉的，这里保持一致。
hl.layer_rule({
    name  = "noctalia-layers",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$" },
    blur  = false,
})

-- XWayland 拖拽修复（自动生成配置里的条目，保留）
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})
