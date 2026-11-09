# My NixOS Configuration

> [!WARNING]
> 此配置并非完全可复现，仅作为个人环境的大致参考。硬件配置、秘密信息、部分外部 flake 版本等需要手动适配。
> 本配置使用了 LLM。

以 [MangoWM](https://github.com/mangowm/mango) 为主，基于 Flake 的 NixOS 系统配置，模块化分层管理。桌面为 Mango + Waybar + Noctalia（配色/壁纸），登录管理器为 ly。

## Flake Inputs

| Input | 来源 | 说明 |
|-------|------|------|
| nixpkgs | [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) | Nix 包集合 (nixos-unstable) |
| home-manager | [nix-community/home-manager](https://github.com/nix-community/home-manager) | 用户级包管理与配置 |
| lazyvim | [pfassina/lazyvim-nix](https://github.com/pfassina/lazyvim-nix) | LazyVim Neovim 配置 |
| nix-cachyos-kernel | [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) | CachyOS BORE 内核（`overlays.pinned`） |
| disko | [nix-community/disko](https://github.com/nix-community/disko) | 声明式磁盘分区与挂载管理 |
| miyu-agent-nix | [yigexuanmu/miyu-agent-nix](https://github.com/yigexuanmu/miyu-agent-nix) | 终端 AI 助手 Miyu |
| nur | [nix-community/NUR](https://github.com/nix-community/NUR) | Nix 用户仓库（`nur.repos.MCSeekeri.workbuddy`） |
| noctalia | [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia) | Noctalia（壁纸 / matugen 配色生成） |
| mangowm | [mangowm/mango](https://github.com/mangowm/mango) | Mango 合成器 + NixOS 模块 |
| waybar | [Alexays/Waybar](https://github.com/Alexays/Waybar) | Waybar 上游 master（0.16 才带 `mango/*` 模块，本地加 `-Dmango=true` 编译） |
| waydroid-nvidia-nix | [yigexuanmu/waydroid-nvidia-nix](https://github.com/yigexuanmu/waydroid-nvidia-nix) | NVIDIA GPU Waydroid 加速（`nvidia-prolapse` 模式） |
| folia-major | [yigexuanmu/folia-major](https://github.com/yigexuanmu/folia-major) | Folia 相关包 |
| linuxqq-wayland-fix | [SHORIN-KIWATA/linuxqq-wayland-fix](https://github.com/SHORIN-KIWATA/linuxqq-wayland-fix) | QQ Wayland 修复 |

## 目录结构

```
├── flake.nix                          # Flake 入口（nixosConfigurations.mioha-nix + homeConfigurations.mioha）
├── flake.lock
├── reinstall.sh                       # LiveCD 一键重装脚本（UEFI + disko LVM/btrfs + swapfile）
├── docs/
│   └── mango-vs-niri.md               # niri → mango 配置对照表（概念模型 / 输出 / 布局 / 键位）
├── guix-configuration/                # Guix 独立配置（channels.scm + home-configuration.scm）
│   ├── channels.scm                   # 锁定 commit 的 guix 通道
│   └── home-configuration.scm         # 最小 Guix Home（glibc-locales/htop/ripgrep/fd）
└── configuration/
    ├── mioha-main/                    # 主机配置入口（仅 imports 聚合）
    │   ├── system.nix                 # 聚合系统模块
    │   ├── modules.nix                # 聚合 programs/services/security/virtualisation 模块
    │   ├── home.nix                   # 聚合 Home Manager 模块
    │   ├── device.nix                 # 导入硬件配置
    │   ├── packages.nix               # 导入自定义包安装模块
    │   └── modules/security/sudo-rs.nix   # 重复副本（未被导入，实际生效的是 modules/security/sudo-rs.nix）
    ├── system/                        # 纯系统级配置（单主题单文件）
    ├── device/
    │   ├── disko.nix                  # 磁盘布局
    │   └── hardware/                  # 硬件配置（hardware-config/nvidia/bluetooth）
    ├── modules/                       # 所有 NixOS 模块
    │   ├── programs/                  # 系统级程序模块
    │   ├── services/                  # 系统服务模块
    │   ├── virtualisation/            # 虚拟化模块（vmware 已注释停用）
    │   ├── security/                  # 安全模块（sudo-rs、wrappers）
    │   └── packages/                  # 系统级包模块
    ├── pkgs/                          # 自定义包定义（以 overlay 形式注入）
    │   ├── data/cursors/              # Windows 光标方案 → XCursor 主题（转换器 + source.zip）
    │   ├── data/fonts/                # 字体打包
    │   └── tools/networking/          # 网络工具打包
    └── home/                          # Home Manager 配置
        ├── programs.nix               # 用户名/家目录 + 聚合所有 Home 模块
        ├── nixpkgs.nix                # Home 作用域 nixpkgs 覆盖
        ├── session.nix                # 会话变量、xdg 终端默认
        ├── mango-session.nix          # mango → systemd 用户会话 target
        └── programs/                  # 用户程序分类配置
            ├── Desktop/               # cursor / fuzzel / mango / waybar（含 dotfiles）
            ├── Develop/  Entertain/  Games/  Terminal/  Utility/
```

## 系统配置

### 硬件与引导

| 模块 | 说明 |
|------|------|
| device/hardware/hardware-config.nix | 手动配置，AMD CPU + NVMe 内核模块，`nixpkgs.hostPlatform`，AMD 微码（`updateMicrocode`） |
| device/disko.nix | GPT 5G ESP→`/efi` + LVM (`vg-mioha`) + Btrfs（卷标 `pc-mioha`，按 by-id 引用 `nvme-HYV512X3`），按功能划分 subvol：`@Config`→`/etc`、`@Data`→`/var/lib`、`@Home`→`/home`、`@Library`→`/library`、`@Sandbox`→`/sandbox`、`@Snapshot`→`/.snapshots`、`System/@Boot`→`/boot`、`System/@Build`→`/var/build`、`System/@Nix`→`/nix`、`System/@Store`→`/nix/store`、`System/@Guix`→`/gnu`、`System/@Guix-Store`→`/gnu/store`、`System/@Log`→`/var/log`、`System/@Swap`→`/swap`、`System/@Tmp`→`/var/tmp`，`compress=zstd` + `noatime`；`/` 与 `/var/lock` 为 tmpfs；`swapDevices` 声明于文件末尾（swapfile 4G，重装后手动创建） |
| device/hardware/nvidia.nix | NVIDIA 开源 GPU 内核模块（`open = true`，`nvidiaPackages.new_feature`，modesetting + nvidiaSettings + 32 位图形 + `nvidia-vaapi-driver`） |
| device/hardware/bluetooth.nix | 蓝牙硬件（`powerOnBoot = false`，开启 Source/Sink/Media/Socket + Experimental）+ blueman |
| boot.nix | Limine（EFI，挂载点 `/efi`），CachyOS Bore x86_64-v3 内核，initrd LVM，`transparent_hugepage=never`（避免 kcompactd0 高 CPU），`amd_iommu=on iommu=pt`，预加载 `vfio`/`vfio_iommu_type1`/`vfio_pci`（不静态绑定设备，直通只在运行期绑定），`kvm ignore_msrs=1`（macOS guest），`/boot`、`/etc`、`/nix`、`/nix/store` neededForBoot |

### 系统基础

| 模块 | 说明 |
|------|------|
| nix.nix | Lix (`lixPackageSets.lix_2_96`)，Flakes + nix-command，allowUnfree，本地 `nix-serve`（127.0.0.1:5000）+ 清华/中科大/官方/lantian/CUDA/flox/noctalia/miyu 缓存源，周度 GC（删 14 天前），系统作用域 `permittedInsecurePackages`（pnpm-9），stateVersion 26.05 |
| overlays.nix | nixpkgs overlays：`nix-cachyos-kernel.overlays.pinned` + 从 `lixPackageSets.latest` 取 nixpkgs-review / nix-direnv / nix-eval-jobs / nix-fast-build / colmena |
| networking.nix | 主机名 `mioha-nix`，NetworkManager，防火墙**关闭**（nftables 也关闭），自装 dnsmasq；`programs.clash-verge`（serviceMode + tunMode + 自启动） |
| user.nix | 用户 `mioha`，组：wheel、networkmanager、libvirtd、kvm、input、audio、uinput、podman |
| i18n.nix | 时区 `Asia/Shanghai`，默认 locale `zh_CN.UTF-8`（支持 en_US + zh_CN） |
| input-method.nix | Fcitx5：`fcitx5-rime`（override `rimeDataPkgs = [rime-data rime-wanxiang]`，万象拼音必须注入到 librime 数据目录否则无候选框）+ 中文插件 + GTK/Qt 支持 + Mellow 主题；万象语法模型需手动放入 `~/.local/share/fcitx5/rime/` |
| environment.nix | 系统软件包（gcc、nh、git、distrobox、libxkbcommon） |
| tmpfiles.nix | `/var/tmp`（1777）、`/var/build` 目录规则 |
| fonts.nix | Noto 中日韩 + Color Emoji、JetBrains Mono / Fira Code Nerd Font、文泉驿微米黑、HarmonyOS Sans；fontconfig 默认 sans=HarmonyOS Sans SC、mono=JetBrainsMono NF |
| journald.nix | 日志上限：`SystemMaxUse=1G`、`SystemMaxFileSize=100M`、`RuntimeMaxUse=256M` |

### 桌面环境

| 模块 | 说明 |
|------|------|
| programs/desktop.nix | `services.xserver.enable`，gvfs，**登录管理器 ly**，`programs.mango.enable`（Mango 合成器），Noctalia（flake 包），XDG portal（`config.common.default = "*"` + portal-gtk + `wlr` 截屏，chooser 用 fuzzel），Firefox，OBS Studio（CUDA 版 + backgroundremoval/pipewire/vaapi/gstreamer/vkcapture 插件 + 虚拟摄像头） |
| programs/neovim.nix | Neovim（默认编辑器，Python3 支持，vi/vim 别名） |
| programs/nix-ld.nix | nix-ld 动态库补全（GL/Vulkan/X11/Wayland/SDL2/alsa 等，服务 Phira 等预编译程序），另装 zenity 供运行时对话框 |
| programs/virt-manager.nix | Virtual Machine Manager 图形化管理前端 |
| programs/steam.nix | Steam（全局防火墙已关闭，`openFirewall` 不设） |

### 系统服务

| 模块 | 说明 |
|------|------|
| services/pipewire.nix | 音频服务 + PulseAudio 兼容 |
| services/openssh.nix | SSH 服务，允许密码登录，`PermitRootLogin = "prohibit-password"` |
| services/flatpak.nix | Flatpak（XDG portal 配置已迁移到 programs/desktop.nix） |
| services/waydroid-nvidia.nix | Waydroid NVIDIA 加速（flake waydroid-nvidia-nix），`mode = "nvidia-prolapse"`，165Hz，`waydroid-nvidia-full` 包，waydroid-helper |
| services/guix.nix | Guix 包管理服务（20 个 build user），SJTU/CERNET 镜像 + 官方回退，周度 GC（保留 1 个月、≥10G 空闲、`--optimize` 去重）；`/gnu`、`/gnu/store` neededForBoot |
| services/polkit.nix | Polkit + GNOME 认证代理（`polkit_gnome`，作为 systemd 用户服务随 graphical-session 拉起） |

### 虚拟化

| 模块 | 说明 |
|------|------|
| virtualisation/libvirtd.nix | KVM/QEMU（`qemu_kvm`，`runAsRoot`），swtpm + virtiofsd；配合 boot.nix 的 vfio 设置可做 macOS / 显卡直通 |
| virtualisation/podman.nix | Podman 容器引擎 + Docker 兼容层（`dockerCompat`） |
| virtualisation/vmware-workstation.nix | VMware Workstation（启用 3D / 不支持的驱动/设备），**当前在 modules.nix 中被注释停用** |

### 自定义包

| 包 | 说明 |
|----|------|
| clash-party.nix | Clash Party 2.0.0（解包 GitHub release 的 .deb，`autoPatchelfHook` 修补，安装于 modules/packages/clash-party.nix；并由 security/wrappers.nix 给 `mihomo-party` 加网络 capabilities） |
| windows-cursor.nix | Windows 光标方案（.ani/.cur）转 XCursor 主题（`pkgs/data/cursors/`，含 Python 转换器 `tool/win2xcursor.py`；动画 + 多尺寸） |
| harmonyos-sans.nix | HarmonyOS Sans 字体（自定义打包，pkgs/data/fonts/，GitHub huawei-fonts/HarmonyOS-Sans） |

`pkgs/default.nix` 以 overlay 属性暴露：`harmonyos-sans`、`windows-cursor-theme`、`clash-party`。

### 安全

| 模块 | 说明 |
|------|------|
| security/wrappers.nix | `mihomo-party` capability wrapper（`cap_net_bind_service,cap_net_raw,cap_net_admin`） |
| security/sudo-rs.nix | sudo-rs 替代传统 sudo（`security.sudo-rs.enable = true`，`security.sudo.enable = false`） |

## Home Manager

入口 `homeConfigurations.mioha`，`home.stateVersion = 26.05`，并入 NUR 的 homeManager 模块。

### 基础配置

| 模块 | 说明 |
|------|------|
| programs.nix | 用户 `mioha`（`/home/mioha`），聚合所有 Home 模块，启用 LazyVim + Git + home-manager（`programs.home-manager.enable`）+ `services.mpris-proxy` |
| nixpkgs.nix | allowUnfree，`pipx` 关闭检查的 overlay，Home 作用域 `permittedInsecurePackages`（electron / pnpm-10） |
| session.nix | Flatpak 数据目录（xdg.systemDirs.data），`xdg.terminal-exec` 默认 kitty，`EDITOR="kitty -e nvim"`、`TERMINAL=kitty`、`BROWSER=google-chrome` |
| mango-session.nix | 提供 `mango-session.target`（BindsTo/Wants `graphical-session.target`），解决 ly 直接 fork mango 导致 `graphical-session.target` 永不为 active、xdg-desktop-portal 激活失败（OBS 屏幕捕获 / 截图 / polkit 不可用）的问题；并固定 `XDG_CURRENT_DESKTOP=mango` |

### Desktop

| 工具/配置 | 说明 |
|------|------|
| mango | `~/.config/mango/config.conf`（tag_num=9，monitor_rule DP-1 2560x1600@165，`scroller` 类布局；`source_optional=~/.config/mango/noctalia.conf`） |
| waybar | 上游 master 编译（`-Dmango=true`），config/modules/modules-dividers/style + 一组脚本（cava、更新检查、命令中心、截图/录屏、蓝牙/网络切换、重载等） |
| fuzzel | 应用启动器 + `fuzzel-web-search` 脚本（兼作 wlr 截屏选择器） |
| noctalia | 配色模板（`templates.toml` + `waybar-colors.css`），终端配色由 noctalia 快照固化（base `#121316`） |
| 文件/通知 | nautilus（+ ffmpegthumbnailer、open-any-terminal）、swaynotificationcenter、mako 替代方案的 swayosd、wlsunset、cliphist |
| 截图/录屏 | grim、slurp、satty、swappy、wl-screenrec、wf-recorder、hyprpicker、brightnessctl、wlr-randr、ddcutil |
| 主题套件 | papirus-icon-theme、papirus-folders、adw-gtk3、afterglow-cursors-recolored、qt5ct/qt6ct、gnome-keyring、nwg-look |
| 其他 | imv、wl-clipboard、libnotify、GNOME 时钟/日历、xdg-user-dirs、adwaita-fonts、lxgw-wenkai-screen、font-awesome_7、matugen |
| cursor.nix | 光标主题 `Windows-Cursor`：48px，XCursor，XCURSOR / GTK settings.ini / dconf / systemd 用户环境同步 |

### 光标主题

Windows 光标方案由 `configuration/pkgs/data/cursors/windows-cursor.nix` 构建成 XCursor 主题，`home/programs/Desktop/cursor.nix` 应用到 Wayland/Xwayland 与 GTK。

| 项 | 值/说明 |
|----|---------|
| 主题名 | `Windows-Cursor`（固定名） |
| 格式 | `cursors/` + `index.theme` |
| 尺寸 | 48（`XCURSOR_SIZE`） |
| 生成档位 | 24/30/32/36/42/48/60/64/72/96 |
| 动画 | 读取 ANI 帧与 rate 延时（jiffy = 1/60 s）；静止 `.cur` 单帧 |
| 转换器 | `configuration/pkgs/data/cursors/tool/win2xcursor.py`（`python -m win2xcursor`，Pillow + xcursorgen；构建时在 `$TMPDIR` 建临时 venv，不依赖用户目录） |
| 角色映射 | `.inf` 的 `[Wreg]`（Arrow/Hand/SizeNS…）优先，无 `.inf` 时按文件名回退 |

更换方案：替换 `configuration/pkgs/data/cursors/source.zip` 后 `nh home switch /etc/nixos`。已运行的 X11/GTK 进程需重启才会重新读取 `XCURSOR_*`。

### Develop

| 工具 | 说明 |
|------|------|
| ripgrep / jq / yq-go | 搜索 / JSON / YAML 处理 |
| python314 + uv + pip + pipx | Python 开发 |
| nodejs | Node.js 运行时 |
| ffmpeg | 音视频处理 |
| websocat | WebSocket 工具 |
| android-tools | Android ADB |
| hugo + glow | 静态站点 + Markdown 渲染 |
| nix-output-monitor / nh | Nix 构建输出监控 / NixOS 系统管理 |
| strace / lsof | 调试工具 |
| vscode / git | 编辑器与版本控制 |
| pi-coding-agent | AI 编程助手 |
| workbuddy | 来自 NUR（`nur.repos.MCSeekeri.workbuddy`） |

### Terminal

| 工具 | 说明 |
|------|------|
| kitty | 终端模拟器（默认，`~/.config/kitty/kitty.conf`） |
| fish | Shell（默认），dotfiles 托管 `config.fish` |
| yazi | 终端文件管理器 |
| zellij | 终端复用器 |
| btop | 系统监控（包装 `LD_LIBRARY_PATH` → `/run/opengl-driver/lib`） |
| fastfetch | 系统信息（`config.jsonc` dotfiles） |
| starship | Shell 提示符 |
| eza / fzf / chafa | 增强 ls / 模糊搜索 / 终端图像 |
| tty-clock | 终端时钟 |
| miyu | [miyu-agent-nix](https://github.com/yigexuanmu/miyu-agent-nix) — 终端 AI 助手 |

### Entertain

| 工具 | 说明 |
|------|------|
| folia-major | Folia (Minecraft) 相关包（flake） |
| go-musicfox | TUI 网易云播放器 |
| qq | QQ 聊天（配合 linuxqq-wayland-fix） |
| playerctl / cava | 媒体控制 / 音频可视化（cava 有 noctalia 主题 dotfiles） |
| kazumi | 看番软件 |
| mpv / google-chrome | 媒体播放器 / 浏览器 |
| cowsay / wine | 说话的牛 / Wine (`wineWow64Packages.stagingFull`) |

### Games

| 工具 | 说明 |
|------|------|
| lutris | 游戏管理器 |
| protonplus | Proton 兼容层管理 |
| osu-lazer-bin | osu! |
| prismlauncher | Minecraft 启动器 |
| mangohud | 游戏性能监控 |
| gamescope | 游戏会话 |

### Utility

| 工具 | 说明 |
|------|------|
| gimp / kdenlive | 图像编辑 / 视频剪辑（`kdePackages.kdenlive`） |
| imagemagick | 图像处理 |
| scrcpy | Android 投屏 |
| tesseract | OCR |
| showmethekey / evtest | 按键显示 / 输入设备测试 |
| 归档工具 | zip、xz、unzip、p7zip、file-roller、zstd |
| 常用工具 | file、which、tree、gnused、gnutar、gawk、gnupg、wget、dmg2img |
| 网络工具 | aria2、nmap、iperf3、dnsutils、mtr、ldns、ipcalc、ethtool、socat |
| 硬件监控 | pciutils、usbutils、lm_sensors、iotop、iftop、sysstat |
| 蓝牙 TUI | bluetui、bluetuith、impala |
| 快照 | snapper |

## 常用操作

```bash
sudo nh os switch /etc/nixos      # 系统（默认构建并切换）
sudo nh os boot /etc/nixos        # 只构建 + 写入引导项，重启生效
nh home switch /etc/nixos         # Home Manager
```

## 重装

LiveCD 下一键重装（disko LVM/btrfs + swapfile + nixos-install）：

```bash
git clone https://github.com/yigexuanmu/my-nixos-config.git
cd my-nixos-config
sudo ./reinstall.sh [--yes]   # --yes 跳过目标盘二次确认
```

## 致谢

- [mangowm](https://github.com/mangowm/mango) — Mango 合成器与 wiki（`docs/mango-vs-niri.md` 的主要依据）
- [SHORiN-KiWATA](https://github.com/SHORiN-KiWATA) — 配置文件参考，waybar 及脚本参考修改，linuxqq-wayland-fix（Miyu 很好用）
- [Zer05ky](https://github.com/sky1234762/ZEK-niri) — waybar 及脚本参考修改（提供 waybar 和 noctalia 结合的灵感）
- [brokenshine/nixos-configs](https://gitee.com/brokenshine/nixos-configs) — NixOS 配置文件拆分参考
- [NixOS-CN 安装教程](https://nixos-cn.org/tutorials/installation) — 安装教程参考
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/zh) — NixOS 与 Flakes 中文教程
- [opencode](https://github.com/anomalyco/opencode) — 开源 AI 编程助手（虽然我现在不用了 XD）
- [DeepSeek](https://www.deepseek.com/) — 帮我拆 Nix 文件，大规模重写，打一些包（NixOS 是 VibeOS，有没有懂的 XD）
