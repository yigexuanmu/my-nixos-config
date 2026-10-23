-- 键位：沿用 niri 的 SUPER 主修饰键与布局无关的部分；
-- niri 的列操作（consume/expel、预设宽度、overview）在 dwindle 下无对应，未迁移。

local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "thunar"
local menu = "noctalia msg panel-toggle launcher"

------------------
---- 程序启动 ----
------------------

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal), { description = "终端" })
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd(fileManager), { description = "文件管理器" })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(menu), { description = "启动台" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("google-chrome"), { description = "Chrome" })
hl.bind(mainMod .. " + ALT + B", hl.dsp.exec_cmd("firefox"), { description = "Firefox" })
hl.bind(mainMod .. " + ALT + O", hl.dsp.exec_cmd("kitty --class opencode -e opencode"), { description = "opencode" })

-- 截图：交给 noctalia（区域截图）
hl.bind("Print", hl.dsp.exec_cmd("noctalia msg screenshot-region"), { description = "截图" })

-- 输入法
hl.bind(mainMod .. " + F1", hl.dsp.exec_cmd("sh -c 'pkill fcitx5 || fcitx5 -d'"), { description = "开关输入法" })

------------------
---- 窗口操作 ----
------------------

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "关闭窗口" })
hl.bind(mainMod .. " + mouse:274", hl.dsp.window.close())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }), { description = "切换浮动" })
hl.bind(mainMod .. " + N", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + grave", hl.dsp.window.float({ action = "toggle" }))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "最大化" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle" }), { description = "全屏" })

-- 平铺下按方向移动焦点（niri 的列语义已去掉，这里就是普通方向焦点）
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- 移动窗口
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "d" }))

-- 跨显示器焦点 / 移动窗口 / 移动整个工作区
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.focus({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.focus({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.focus({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.focus({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.focus({ monitor = "d" }))

hl.bind(mainMod .. " + SHIFT + CTRL + left", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + right", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + up", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + down", hl.dsp.window.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + CTRL + H", hl.dsp.window.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + CTRL + L", hl.dsp.window.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + CTRL + K", hl.dsp.window.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + CTRL + J", hl.dsp.window.move({ monitor = "d" }))

hl.bind(mainMod .. " + SHIFT + ALT + left", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + ALT + right", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + ALT + up", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + ALT + down", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + ALT + H", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + ALT + L", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + ALT + K", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + ALT + J", hl.dsp.workspace.move({ monitor = "d" }))
hl.bind(mainMod .. " + SHIFT + ALT + A", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + ALT + D", hl.dsp.workspace.move({ monitor = "r" }))
hl.bind(mainMod .. " + SHIFT + ALT + W", hl.dsp.workspace.move({ monitor = "u" }))
hl.bind(mainMod .. " + SHIFT + ALT + S", hl.dsp.workspace.move({ monitor = "d" }))

-- 窗口拖拽 / 缩放（保留鼠标）
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

------------------
---- 工作区 ----
------------------

for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + CTRL + " .. i, hl.dsp.window.move({ workspace = i, follow = false }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mainMod .. " + CTRL + 0", hl.dsp.window.move({ workspace = 10, follow = false }))

hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + Page_Up", hl.dsp.focus({ workspace = "-1" }))

hl.bind(mainMod .. " + CTRL + U", hl.dsp.window.move({ workspace = "+1", follow = false }))
hl.bind(mainMod .. " + CTRL + I", hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(mainMod .. " + CTRL + Page_Down", hl.dsp.window.move({ workspace = "+1", follow = false }))
hl.bind(mainMod .. " + CTRL + Page_Up", hl.dsp.window.move({ workspace = "-1", follow = false }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "+1", follow = false }))
hl.bind(mainMod .. " + CTRL + mouse_up", hl.dsp.window.move({ workspace = "-1", follow = false }))
hl.bind(mainMod .. " + CTRL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "+1", follow = false }))
hl.bind(mainMod .. " + CTRL + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "-1", follow = false }))

------------------
---- 媒体键 ----
------------------

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("sh -c 'swayosd-client --output-volume +5 || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+'"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("sh -c 'swayosd-client --output-volume -5 || wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-'"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("sh -c 'swayosd-client --output-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle'"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl --class=backlight set +5%"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl --class=backlight set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

------------------
---- 退出 ----
------------------

hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"), { description = "退出 Hyprland" })
