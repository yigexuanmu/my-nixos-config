# niri → mangowm 配置对照表

依据：
- mangowm 官方 wiki（`https://github.com/mangowm/mango.wiki`，已 clone 到 `/tmp/mango-wiki`）
- 本机 mango nightly 自带参考配置：`/nix/store/pp5jx22pphgdcv3jm47lnb65166lh3dh-mango-nightly/etc/mango/config.conf`（305 行默认配置）
- 关键字拼写已用 `strings .../bin/mango` 核对过：`window_rule` / `window_rule_once` / `layer_rule` / `tag_rule` / `monitor_rule` / `exec` / `exec_once` / `source_optional` / `tag_num` / `xkb_rules_layout` / `cursor_theme`
- 对照对象：main 分支 `configuration/home/programs/Desktop/niri/dotfiles/{config,binds,blur,pop-drop}.kdl`

---

## 0. 概念模型差异（先看这个，很多条目不"一一对应"）

| niri | mango | 说明 |
| --- | --- | --- |
| 工作区 workspace（动态创建、纵向排列） | tag（固定数量，默认 `tag_num=9`） | mango 每个显示器各有一套 1–9 tag（tagset），不存在"全局工作区列表" |
| 列 column（窗口竖直堆叠） | scroller 布局里的"竖直栈 stack" | scroller = 水平卷动的窗口条，同栈内窗口竖直堆叠，≈ niri 的列 |
| 窗口 window | client | mango 以 client 为最小单位 |
| 布局不是"可选"的（niri 只有一个滚动布局） | `layout_name`: `tile`/`scroller`/`dwindle`/`monocle`/`deck`/`grid`/`center_tile`/`vertical_*`/`fair` 等，**按 tag 指定** | 想复刻 niri 就全局 `tag_rule=id:*,layout_name:scroller` |
| 输出 output | monitor | |
| 配置文件 `config.kdl`（KDL） | `config.conf`（真的 `key=value`，非 ini 段）或 `config.toml` | |

配置位置与加载顺序（wiki basics）：

1. `~/.config/mango/config.conf` → 2. `~/.config/mango/config.toml` → 3. `/etc/mango/config.conf`
2. 校验语法：`mango -c ~/.config/mango/config.conf -p`
3. 自己指定路径启动：`mango -c /path/config.conf`
4. 拆分配置：`source=./bind.conf`、`source_optional=./optional.conf`（不存在也不报错）
5. 自定义变量：`var=term,kitty` → 用 `$term` / `${term}` 引用（必须在定义之后使用）
6. 热重载：`auto_reload_config=1`（默认开，监视主配置和所有 source 文件），或 `bind=SUPER,r,reload_config`

> 注意：`env=` 定义的环境变量**每次 reload 都会被重置**。

---

## 1. 输出 / 显示器

| niri (`config.kdl`) | mango |
| --- | --- |
| `output "DP-1" { mode "2560x1600@165.040" }` | `monitor_rule=name:^DP-1$,width:2560,height:1600,refresh:165.04` |
| `scale 1` | `...,scale:1` |
| `transform "normal"` | `...,rr:0`（0–7，0=不旋转） |
| `position x=0 y=0` | `...,x:0,y:0` |
| （无） | `vrr:1`、`hdr:1`、`icc:/path.icc`、`primary:1`、`disable:1`、`custom:1` |

要点：
- `name` 是**正则**，精确匹配要写 `^DP-1$`。
- 设了 `name`/`make`/`model`/`serial` 中任意多个字段时，**必须全部匹配**；多条规则只取第一条命中。
- XWayland 下**坐标不要用负数**（已知点击错位 bug），从 `0,0` 往正方向排。

---

## 2. 布局与间隙

| niri | mango |
| --- | --- |
| `layout { gaps 10 }` | `gap_outer_horizontal=10`、`gap_outer_vertical=10`、`gap_inner_horizontal=10`、`gap_inner_vertical=10` |
| `center-focused-column "never"` | `scroller_focus_center=0`、`scroller_prefer_center=0`（`"always"`≈`scroller_focus_center=1`） |
| `preset-column-widths { proportion 0.33333 / 0.5 / 0.66667 }` | `scroller_proportion_preset=0.33333,0.5,0.66667` |
| `default-column-width { proportion 0.5 }` | `scroller_default_proportion=0.5` |
| （单窗口自适应） | `scroller_default_proportion_single=1.0` + `scroller_ignore_proportion_single=0` |
| `struts { }` | 无对应（自动） |
| `smart-gaps`（niri 无） | `smart_gaps=1` |
| （niri 无） | `scroller_structs=20`（比例 1 时两侧留白）、`edge_scroller_pointer_focus=1` |

坑：`scroller_prefer_overspread`(默认 1) > `scroller_focus_center` > `scroller_prefer_center`，高优先级为 1 时低优先级不生效。

### 布局不是"锁死"的

`tag_rule` 里的 `layout_name` 只是该 tag 的**初始**布局，运行时可随时切换，且各 tag 独立：

- `bind=SUPER,n,switch_layout` —— 按 `circle_layout` 的顺序循环
- `bind=SUPER+ALT,1,setlayout,scroller` —— 直接指定（`set_layout` 用 `strcmp` 精确匹配名字）

`circle_layout=scroller,vertical_scroller,tile,dwindle,grid,monocle,deck,fair`

全部可用布局（`src/layout/arrange.c: layouts[]`，注意符号大小写敏感）：

| 符号 | 名字 | 说明 |
| --- | --- | --- |
| T | `tile` | 等分平铺（mango 默认） |
| S | `scroller` | 横向卷动的列，同栈内窗口竖直堆叠（≈ niri） |
| G | `grid` | 网格 |
| M | `monocle` | 单窗口铺满 |
| K | `deck` | 卡片层叠 |
| CT / RT | `center_tile` / `right_tile` | 居中 / 靠右平铺 |
| DW | `dwindle` | 二分（考虑 `dwindle_split_*` 选项） |
| F | `fair` | 均衡平铺 |
| VS / VT / VG / VK / VF | `vertical_scroller` / `vertical_tile` / `vertical_grid` / `vertical_deck` / `vertical_fair` | 纵向版本 |

`scroller_*` 那批参数（`scroller_default_proportion`、`scroller_proportion_preset`、
`scroller_focus_center` 等）只在 scroller 类布局下生效，切到别的布局不影响它们；
`set_proportion` 也会在非 scroller 布局下直接返回。


---

## 3. 边框 / 圆角 / 阴影 / 透明度 / 模糊 / 暗化

| niri | mango | 备注 |
| --- | --- | --- |
| `focus-ring { width 3.5, active-color "#7fc8ff", inactive-color "#505050" }` | `border_px=3`（整数）+ `focus_color=0x7fc8ffff` + `border_color=0x505050ff` | **mango 只有一层边框**，focus-ring 和 border 合并成一个，双色/双宽效果丢失 |
| `border { off; width 4; active-color "#ffc87f"; inactive-color "#505050"; urgent-color "#9b0000" }` | 同上 + `urgent_color=0x9b0000ff` | `off` 就是 `border_px=0` |
| `shadow { softness 30; spread 5; offset x=0 y=5; color "#0007" }` | `shadows=1`、`shadows_blur=30`(≈softness)、`shadows_size=5`(≈spread)、`shadows_position_x=0`、`shadows_position_y=5`、`shadows_color=0x00000077` | 还有 `shadow_only_floating=1`、`layer_shadows=1` |
| `geometry-corner-radius 12` | `border_radius=12` | **只能全局**，不能按窗口规则设（只有 `no_radius:1` 关掉） |
| `background-effect { blur true; xray false }` | `blur=1`（窗口）、`blur_layer=1`（waybar/noctalia 等层） | `blur_params_radius/num_passes/noise/brightness/contrast/saturation`；`blur_optimized=1` 默认 |
| `draw-border-with-background`、`clip-to-geometry` | —— | mango 无对应 |
| 窗口透明度（niri 无） | `focused_opacity=1.0`、`unfocused_opacity=1.0`，或 per-window `window_rule=focused_opacity:0.8,...` | |
| （niri 无） | `dim_enable=1` + `dim_focused_color` / `dim_unfocused_color`（给非聚焦窗口盖一层半透明遮罩，不影响点击） | |

> **模糊的重要差异**：mango 的 `blur_optimized=1` 会缓存壁纸，只对**壁纸**做模糊——不会像 niri 的 `xray false` 那样"透出下层的窗口内容"。关闭 `blur_optimized` 才接近真实背景模糊，但 GPU 开销大幅上升（wiki 明确警告，官方 FAQ 也承认这是设计取舍）。

---

## 4. 动画

| niri | mango |
| --- | --- |
| `animations { slowdown 0.98 }` | 无全局 slowdown，只能逐个改 `animation_duration_*` |
| `window-open { duration-ms 350; curve "ease-out-expo" }` | `animations=1` + `animation_type_open=slide`（或 `zoom`/`fade`/`none`）+ `animation_duration_open=350` + `animation_curve_open=0.16,1,0.3,1`（≈ease-out-expo） |
| `window-close { duration-ms 350; curve "linear" }` | `animation_type_close=fade` + `animation_duration_close=350` + `animation_curve_close=0,0,1,1` |
| `window-open/close { custom-shader "..." }`（下落+旋转 GLSL） | **不支持自定义 shader**。只能选 4 种内置类型 + 贝塞尔曲线 |
| `window-movement { spring ... }` | `animation_duration_move=500` + `animation_curve_move=...`（无弹簧物理模型） |
| `window-resize { spring ... }` | 无独立配置（跟 move） |
| `workspace-switch` / `horizontal-view-movement` | `animation_duration_tag` + `animation_curve_tag` + `tag_animation_direction=1`(水平)/`0`(垂直) |
| `overview-open-close` | 无独立配置 |
| `screenshot-ui-open` | 无（mango 无内置截图 UI） |
| （niri 无） | `animation_fade_in/out`、`fade_in_begin_opacity`、`zoom_initial_ratio`、`zoom_end_ratio` |
| layer 动画 | `layer_animations=1` + `layer_animation_type_open/close`，或按层用 `layer_rule=animation_type_open:zoom,layer_name:rofi` |

`blur.kdl` 里的 `cursor-effect { ... }`（niri 的光标拖尾/粒子特效）**mango 完全没有对应物**。

`pop-drop.kdl` 的两个 custom-shader 是本次迁移中"必须放弃"的部分——这是 niri 独有的 GLSL 能力。

---

## 5. 输入设备

| niri | mango |
| --- | --- |
| `input { keyboard { xkb { layout "us" } } }` | `xkb_rules_layout=us`（还有 `xkb_rules_variant` / `xkb_rules_options` / `xkb_rules_model` / `xkb_rules_rules`） |
| `keyboard { numlock }` | `numlock_on=1` |
| `repeat-rate` / `repeat-delay` | `repeat_rate=25` / `repeat_delay=600` |
| `touchpad { tap }` | `tap_to_click=1` |
| `touchpad { natural-scroll }` | `trackpad_natural_scrolling=1` |
| `touchpad { dwt }` | `trackpad_disable_while_typing=1` |
| `touchpad { drag-lock }` | `drag_lock=1` |
| `touchpad { drag false }` | `tap_and_drag=0` |
| `mouse { accel-profile "flat" }` | `mouse_accel_profile=1`（0=none,1=flat,2=adaptive） |
| `touchpad { accel-speed }` | `trackpad_accel_speed` |
| `focus-follows-mouse max-scroll-amount="0%"` | `sloppy_focus=1`（没有 max-scroll-amount 这一层语义） |
| `warp-mouse-to-focus` | `warp_cursor=1` |
| `cursor { xcursor-theme "Windows-Cursor"; xcursor-size 48 }` | `cursor_theme=Windows-Cursor`、`cursor_size=48` |
| `cursor { hide-after-inactive-ms 3000 }` | `cursor_hide_timeout=3`（秒） |
| 键盘布局切换（fcitx 用不到） | `bind=alt,shift_l,switch_keyboard_layout`、`xkb_rules_layout=us,us` + `xkb_rules_variant=,dvorak` |
| （niri 无） | `device_rule=...` 按设备覆盖；`mmsg watch all-devices` 查设备名 |
| （niri 无） | `drag_tile_to_tile=1`（拖拽窗口互换位置）、`enable_border_resize=1`（边缘拖拽缩放） |

触摸板手势（niri 用 `Mod+滚轮` 模拟，mango 有真手势）：
```ini
gesturebind=none,left,3,focusdir,left
gesturebind=none,left,4,viewtoleft   # 三/四指滑动
```

---

## 6. 环境变量与自启动

| niri | mango |
| --- | --- |
| `environment { LANG "zh_CN.UTF-8" ... }` | `env=LANG,zh_CN.UTF-8`（一行一个；**每次 reload 重置**） |
| `spawn-at-startup "noctalia"` | `exec_once=noctalia` |
| `spawn-at-startup "sh" "-c" "sleep 2; exec waybar"` | `exec_once=sh -c 'sleep 0.1; exec "$(command -v waybar \|\| echo "$HOME/.nix-profile/bin/waybar")"'`（`command -v` 兜底是因为 HM 装的 waybar 在 `~/.nix-profile/bin`，不一定在 mango 继承到的 PATH 里） |
| `spawn-at-startup "fcitx5"` | `exec_once=fcitx5` |
| （niri 无） | `exec=`：**每次 reload 都执行**，适合刷新脚本 |
| `hotkey-overlay { skip-at-startup }` + `hotkey-overlay-title=` | **mango 没有快捷键提示浮层**，这些标注信息丢失 |
| `prefer-no-csd` | 已经是 mango 默认行为（`allow_csd` 默认 0），需要 CSD 时用 `window_rule=allow_csd:1,app_id:firefox` |
| `screenshot-path "~/Pictures/Screenshots/..."` | 无内置截图。做法：`var=shot,~/Pictures/Screenshots` + `bind=Print,spawn_shell,grim $shot/$(date +%Y%m%d%H%M%S).png` |

要复刻 niri 那段 IME 环境变量（`config.kdl` 里的 `environment` 块）：
```ini
env=LANG,zh_CN.UTF-8
env=LC_ALL,zh_CN.UTF-8
env=LC_MESSAGES,zh_CN.UTF-8
env=LANGUAGE,zh_CN:en
env=XMODIFIERS,@im=fcitx
env=GTK_IM_MODULE,fcitx
env=QT_IM_MODULE,fcitx
env=QT_IM_MODULES,wayland;fcitx;ibus
env=QT_QPA_PLATFORMTHEME,qt6ct
env=GSK_RENDERER,gl
env=QS_ICON_THEME,Papirus-Dark
```

本仓库 `dotfiles/config.conf` 里实际的自启动段：

```ini
exec_once=fcitx5
exec_once=noctalia
exec_once=sh -c 'sleep 0.1; exec "$(command -v waybar || echo "$HOME/.nix-profile/bin/waybar")"'
```

- `exec_once` 在 `main.c` 里于 `set_activation_env()` **之后**执行，所以子进程能拿到
  `WAYLAND_DISPLAY`、`MANGO_INSTANCE_SIGNATURE`（waybar 的 `mango/*` 模块就靠它找 IPC socket）。
- `exec_once` 只在第一次启动跑，`reload_config` 不重跑；要每次 reload 都执行用 `exec=`。
- 走 `exec_once` 的进程没有 systemd 托管，崩了不会自动拉起；想托管就用
  `systemd.user.services.<name>` + `WantedBy=mango-session.target`
  （该 target 由 mango 包自带，`BindsTo=graphical-session.target`，mango 启动时会
  `systemctl --user import-environment MANGO_INSTANCE_SIGNATURE ...` 后再 start 它）。


---

## 7. 规则：window-rule / layer-rule

### 语法

```ini
window_rule=参数:值,参数:值,app_id:正则,title:正则     # 每次打开都应用
window_rule_once=...                                   # 只在打开时应用一次
layer_rule=参数:值,layer_name:正则
tag_rule=id:1|*|3|5,参数:值,monitor_name:xxx
```

`app_id` 和 `title` 同时给时必须**同时匹配**；都支持正则。查层的名字：`mmsg get last_open_surface`。

### window-rule 对照

| niri | mango |
| --- | --- |
| `match app-id=r#"^org\.wezfurlong\.wezterm$"#` | `app_id:^org\.wezfurlong\.wezterm$` |
| `match title="^Picture-in-Picture$"` | `title:^Picture-in-Picture$` |
| `match is-floating=true` | `is_floating:1` |
| `open-floating true` | `is_floating:1` |
| `open-focused false` | `is_open_silent:1` |
| `default-column-width { fixed 1080 }` + `default-window-height { fixed 920 }` | `width:1080,height:920`（**只对浮动窗口生效**；<1 视为屏幕比例） |
| `open-on-workspace "x"` | `tags:3`（tag mask，`0` = 特殊 overlay，`1\|3` 多 tag） |
| `background-effect { blur true }` | 无 per-window 开启；只有 `no_blur:1` 关闭 |
| `background-effect { xray false }` | **无对应**（mango 的模糊不做透叠） |
| `geometry-corner-radius 12` | 无 per-window；`no_radius:1` 关闭 |
| `clip-to-geometry true` / `draw-border-with-background false` | 无对应 |
| `block-out-from "screen-capture"` | `shield_when_capture:1`（截图时遮住窗口，语义接近但不完全相同） |
| （niri 无） | `monitor:HDMI-A-1`、`tags:9`、`offset_x/offset_y`、`no_border:1`、`no_shadow:1`、`no_animation:1`、`focused_opacity/unfocused_opacity`、`is_global:1`(全 tag 粘住)、`is_overlay:1`(永远置顶)、`scroller_proportion:0.5`、`animation_type_open:zoom`、`force_tearing:1`、`global_key_binding:ctrl+alt-o`、`is_term:1`(终端吞窗口) |

**注意**：niri 的 window-rule 是"逐条累积"，mango 是"每个参数各自生效、多条命中会叠加"。niri 里那条"所有 app_id 都加圆角+裁切"的 `window-rule { geometry-corner-radius 12; clip-to-geometry true }` **无法等价迁移**——只能全局 `border_radius=12`。

### layer-rule 对照

| niri | mango |
| --- | --- |
| `layer-rule { match namespace="^noctalia-(bar-...)$" background-effect { xray false } }` | 无 `background-effect`/`xray`；可用 `layer_rule=no_blur:1,layer_name:^noctalia-...$` 或全局 `blur_layer=1` |
| `layer-rule { match namespace="^noctalia-backdrop"; place-within-backdrop true }` | **无对应** |
| （niri 无） | `animation_type_open/close`、`no_animation:1`、`no_shadow:1`、`shield_when_capture:1` |

noctalia 常用的两条（官方默认配置里的写法风格）：
```ini
layer_rule=no_animation:1,no_shadow:1,layer_name:^swaync
layer_rule=no_animation:1,no_blur:1,layer_name:selection   # slurp 选区，避免截图重影
```

> `config.kdl` 里 `include "noctalia.kdl"` 引用的那个文件从来没提交到 git（只在你机器上手写过），迁移时等于要重写——正好用上面的 `layer_rule` 形式。

---

## 8. 快捷键逐条对照（`binds.kdl` → `bind=`）

格式：`bind[flags]=修饰键,键,dispatcher,参数`，修饰键 `SUPER/CTRL/ALT/SHIFT/NONE` 用 `+` 组合，niri 的 `Mod` = `SUPER`。
flags：`l`=锁屏时也生效（≈`allow-when-locked`）、`s`=按 keysym、`r`=松开触发、`p`=透传给客户端、`c`=允许冲突。
`hotkey-overlay-title`、`repeat=false`、`cooldown-ms` **没有对应项**。

| niri action | mango dispatcher |
| --- | --- |
| `spawn "kitty"` | `bind=SUPER,T,spawn,kitty` |
| `spawn "kitty" "--class" "opencode" "-e" "opencode"` | `bind=SUPER+ALT,O,spawn,kitty --class opencode -e opencode` |
| `spawn-sh "pkill fcitx5 \|\| fcitx5"` | `bind=SUPER,F1,spawn_shell,pkill fcitx5 \|\| fcitx5` |
| `noctalia msg panel-toggle launcher` | `bind=SUPER,E,spawn,noctalia msg panel-toggle launcher` |
| `screenshot` | 无 dispatcher，用 `spawn_shell,grim ...`（或用 fuzzel/grim/satty 脚本） |
| `close-window` | `killclient,`（`killclient,force` 强杀；`smartkillclient`） |
| `quit` | `quit` |
| `toggle-overview` / `toggle-grid-overview` | `toggleoverview` / `togglejump`（jump 模式）/ `enteroverview` `leaveoverview` |
| `maximize-column` | `togglemaximizescreen` |
| `fullscreen-window` | `togglefullscreen`（`togglefakefullscreen` = 假全屏） |
| `toggle-window-floating` | `togglefloating` |
| `focus-column-left/right` | `focusdir,left` / `focusdir,right` |
| `focus-window-up/down`（列内上下） | `focusdir,up` / `focusdir,down`（scroller 栈内按方向选） |
| `move-column-left/right` | `move_client,left` / `move_client,right` |
| `move-window-up/down`（栈内调序） | `move_client,up` / `move_client,down` |
| `focus-monitor-*` | `focusmon,left/right/up/down`（或 `focusmon,next/prev`、`focusmon,DP-1`） |
| `move-column-to-monitor-*` | `tagmon,left/right/up/down`（跨屏需 `exchange_cross_monitor=1`；`tagmon,keeptag` 第 2 参数可选） |
| `move-workspace-to-monitor-*` | 无直接对应（tag 属于每个显示器；用 `tagcrossmon,mask,monitor_spec`） |
| `focus-workspace-down/up` | `viewtoright` / `viewtoleft`（或 `view,-1` = 回到上一个 tagset） |
| `focus-workspace N` | `view,N`（tag mask；`view,00` = 显示全部） |
| `move-column-to-workspace-down/up` | `tagtoright` / `tagtoleft` |
| `move-column-to-workspace N` | `tag,N`（`tagsilent,N` = 不跟随焦点） |
| `focus-column-first/last` | 无对应（可连按 `focusdir` 或用 `mmsg`） |
| `move-column-to-first/last` | 无对应 |
| `consume-or-expel-window-left/right` | `scroller_stack,left` / `scroller_stack,right` |
| `consume-window-into-column` / `expel-window-from-column` | 同上 `scroller_stack,left/right`（mango 把"列"和"栈"合并成一个概念） |
| `switch-preset-column-width` | `switch_proportion_preset` |
| `set-column-width "+5%"` | `set_proportion,0.55`（**绝对值 0.0–1.0**，没有相对步进） |
| `switch-preset-window-height` / `reset-window-height` / `set-window-height` | 无对应（mango 不控制栈内窗口高度） |
| `expand-column-to-available-width` | 近似 `set_proportion,1.0` |
| `center-column` | 无对应（`centerwin` 只对浮动窗口）；要始终居中就 `scroller_focus_center=1` |
| `switch-focus-between-floating-and-tiling` | 无对应（浮动窗口本来就参与 `focusdir`；可用 `togglefloating` 绕） |
| `toggle-keyboard-shortcuts-inhibit` | 无对应 dispatcher（只有 `allow_shortcuts_inhibit` 配置项） |
| `toggle-magnifier` / `adjust-magnifier-zoom` | 无对应（mango 无放大镜） |
| `toggle-cursor-effect` | 无对应 |
| `toggle-grid-overview` | `togglejump` / `toggleoverview 1` |

### 键位对照（niri 绑定 → mango，可直接抄）

```ini
# 应用
bind=SUPER,F1,spawn_shell,pkill fcitx5 || fcitx5 &
bind=SUPER,B,spawn,google-chrome
bind=SUPER+ALT,B,spawn,firefox
bind=SUPER+ALT,O,spawn,kitty --class opencode -e opencode
bind=SUPER,T,spawn,kitty
bind=SUPER,X,spawn,thunar
bind=SUPER,E,spawn,noctalia msg panel-toggle launcher
bind=SUPER,Q,killclient,
bind=SUPER,Print,spawn_shell,grim ~/Pictures/Screenshots/$(date +%Y%m%d%H%M%S).png

# 声音/亮度（bindl = 锁屏时也生效 ≈ allow-when-locked）
bindl=NONE,XF86AudioRaiseVolume,spawn_shell,swayosd-client --output-volume +5 || wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+
bindl=NONE,XF86AudioLowerVolume,spawn_shell,swayosd-client --output-volume -5 || wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-
bindl=NONE,XF86AudioMute,spawn_shell,swayosd-client --output-volume mute-toggle || wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindl=NONE,XF86AudioMicMute,spawn_shell,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindl=NONE,XF86MonBrightnessUp,spawn,brightnessctl --class=backlight set +5%
bindl=NONE,XF86MonBrightnessDown,spawn,brightnessctl --class=backlight set 5%-

# 焦点 / 移动（H J K L + 方向键）
bind=SUPER,Left,focusdir,left
bind=SUPER,Right,focusdir,right
bind=SUPER,Up,focusdir,up
bind=SUPER,Down,focusdir,down
bind=SUPER,H,focusdir,left
bind=SUPER,L,focusdir,right
bind=SUPER,K,focusdir,up
bind=SUPER,J,focusdir,down
bind=SUPER+CTRL,Left,move_client,left
bind=SUPER+CTRL,Right,move_client,right
bind=SUPER+CTRL,Up,move_client,up
bind=SUPER+CTRL,Down,move_client,down
bind=SUPER+CTRL,H,move_client,left
bind=SUPER+CTRL,L,move_client,right
bind=SUPER+CTRL,K,move_client,up
bind=SUPER+CTRL,J,move_client,down

# 显示器（单屏可留空）
bind=SUPER+SHIFT,Left,focusmon,left
bind=SUPER+SHIFT+CTRL,Left,tagmon,left

# 工作区（tag）
bind=SUPER,U,viewtoright
bind=SUPER,I,viewtoleft
bind=SUPER+CTRL,U,tagtoright
bind=SUPER+CTRL,I,tagtoleft
bind=SUPER,1,view,1
bind=SUPER,2,view,2
bind=SUPER,3,view,3
bind=SUPER,4,view,4
bind=SUPER,5,view,5
bind=SUPER,6,view,6
bind=SUPER,7,view,7
bind=SUPER,8,view,8
bind=SUPER,9,view,9
bind=SUPER+CTRL,1,tag,1
bind=SUPER+CTRL,2,tag,2
bind=SUPER+CTRL,3,tag,3
bind=SUPER+CTRL,4,tag,4
bind=SUPER+CTRL,5,tag,5
bind=SUPER+CTRL,6,tag,6
bind=SUPER+CTRL,7,tag,7
bind=SUPER+CTRL,8,tag,8
bind=SUPER+CTRL,9,tag,9

# scroller（列/栈）
bind=SUPER,BracketLeft,scroller_stack,left
bind=SUPER,BracketRight,scroller_stack,right
bind=SUPER,A,scroller_stack,left
bind=SUPER,D,scroller_stack,right
bind=SUPER,R,switch_proportion_preset
bind=SUPER,F,togglemaximizescreen
bind=SUPER+SHIFT,F,togglefullscreen
bind=SUPER,V,togglefloating
bind=SUPER,O,toggleoverview
bind=SUPER,G,toggleoverview

# 窗口/标记
bind=SUPER+SHIFT,E,quit
bind=SUPER,R,reload_config
```

### 滚轮与鼠标（niri 的 `Mod+WheelScroll*`）

```ini
axisbind=SUPER,UP,viewtoleft
axisbind=SUPER,DOWN,viewtoright
mousebind=SUPER,btn_middle,killclient,
mousebind=SUPER,btn_left,moveresize,curmove
mousebind=SUPER,btn_right,moveresize,curresize
```

（`axisbind` 的连续事件合并时间由 `axis_bind_apply_timeout=100` 控制，对应 niri 的 `cooldown-ms` 效果。）

---

## 9. waybar 模块（已解决：需要 waybar 0.16）

main 分支的 waybar 用的是 niri 专用模块，mango 下要换成 `mango/*`：

| niri | mango |
| --- | --- |
| `niri/workspaces` | `mango/workspaces`（tag 按钮；overview 时显示 OVERVIEW 按钮） |
| `niri/window` | `mango/window`（`{title}` / `{app_id}`，支持 `rewrite`） |
| （niri 无） | `mango/layout`（当前布局符号，`format-<symbol>` 可自定义） |
| `niri/language` | `mango/language`（`{short}` / `{long}` / `{variant}`） |
| （niri 无） | `mango/keymode`（`setkeymode` 的模式名，默认 `default`） |

**关键点：`mango/*` 模块从 Waybar 0.16.0 才有。**

- 本机 nixpkgs 的 waybar 是 **0.15.0**：`src/modules/` 里只有 `niri`/`dwl`/`sway`/`hyprland`/`wlr`，
  编译出来的二进制里 `strings | grep mango/` 为空 —— 配置写了 `mango/workspaces` 只会得到
  `Unknown module` 警告，模块整块不显示。
- 本仓库的做法：flake 里加 `waybar = github:Alexays/Waybar`（`nixpkgs.follows`），
  在 `configuration/home/programs/Desktop/default.nix` 里用它的 `packages.<system>.default`
  并追加 `-Dmango=true`：
  ```nix
  waybar = inputs.waybar.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    mesonFlags = old.mesonFlags ++ ["-Dmango=true"];
  });
  ```
  上游 flake 的 overlay 已经负责把 `subprojects/libcava.wrap` 需要的 libcava 版本
  （`cava-8d6e963…`）在 `postUnpack` 里放好，否则 meson 会去下载子项目。

**模块名清单**（`src/modules/mango/`）：`mango/workspaces`、`mango/layout`、
`mango/window`、`mango/language`、`mango/keymode`。

**mango 模块依赖 `MANGO_INSTANCE_SIGNATURE` 环境变量**（mango 通过
`dbus-update-activation-environment` 设置）。如果 waybar 由 systemd user service 启动，
需要在该 service 里 `import-environment MANGO_INSTANCE_SIGNATURE` 或让它作为 mango 的子进程启动，
否则模块会抛 `Mango IPC: MANGO_INSTANCE_SIGNATURE not set`。

另外 `power-screenshot.sh` 里 `BACKEND_MODE=auto` 会探测 niri：mango 下会自然回退到 `grim`，
无需改动，但脚本里 `NIRI_CONFIG` 相关分支永远走不到（可选清理）。

---

---

## 10. 迁移注意清单

1. **无法迁移的 niri 特性**：`custom-shader` 动画、`cursor-effect` 粒子光标、`place-within-backdrop`、`clip-to-geometry`、`draw-border-with-background`、`background-effect xray false`（真·透窗模糊）、放大镜、hotkey-overlay 提示层、每窗口圆角、列内窗口高度控制、`switch-focus-between-floating-and-tiling`。
2. **焦点环 + 边框**会合成一层，颜色/宽度需二选一。
3. **tag 是每显示器独立的**，niri 的"工作区跟着焦点跑"语义不同；waybar 的 workspaces 模块必须换。
4. **`env=` 每次 reload 重置**，把 IME 变量写全才不会掉。
5. `bind=` 的键名按 `xkb_rules_layout` 解析成 keycode，日/俄等布局下要留意；必要时用 `code:N`。
6. mango 自带 `mangonag` 错误条：配置写错时会在屏顶弹出，可用 `mango -c ... -p` 预校验。
7. 用户配置文件位置 `~/.config/mango/config.conf`，本仓库目前既没有 nix 模块化（`programs.mango` 只有 `enable/addLoginEntry/package`）也没有该文件——需要手写或通过 `xdg.configFile` 落盘。
