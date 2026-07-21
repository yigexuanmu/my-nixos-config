# My NixOS Configuration

基于 Flake 的 NixOS 系统配置，模块化分层管理。

## Flake Inputs

| Input | 来源 | 说明 |
|-------|------|------|
| nixpkgs | [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) | Nix 包集合 (nixos-unstable) |
| home-manager | [nix-community/home-manager](https://github.com/nix-community/home-manager) | 用户级包管理与配置 |
| lazyvim | [pfassina/lazyvim-nix](https://github.com/pfassina/lazyvim-nix) | LazyVim Neovim 配置 |
| nix-cachyos-kernel | [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) | CachyOS BORE 内核 |
| daeuniverse | [daeuniverse/flake.nix](https://github.com/daeuniverse/flake.nix) | DAED 网络代理 |
| noctalia | [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia) | Noctalia v5 Shell (follows nixpkgs) |
| miyu | [yigexuanmu/Miyu](https://github.com/yigexuanmu/Miyu) | 终端 AI 助手（TUI Diff） |
| niri | [shorin-niri-nix](https://github.com/yigexuanmu/shorin-niri-nix) | Niri 平铺窗口管理器 |
| we-layerd | [yigexuanmu/we-layerd-flake](https://github.com/yigexuanmu/we-layerd-flake) | Wallpaper Engine Wayland 运行时 + DXC |
| shorin-niri | [yigexuanmu/shorin-niri-nix](https://github.com/yigexuanmu/shorin-niri-nix) | Niri 平铺窗口管理器定制构建 |

## 目录结构

```
├── flake.nix                     # Flake 入口
├── configuration/
│   ├── mioha-main/               # 主机配置入口
│   │   ├── system.nix            # 聚合系统模块
│   │   ├── modules.nix           # 聚合 programs/services/virtualisation 模块
│   │   ├── home.nix              # 聚合 Home Manager 模块
│   │   ├── device.nix            # 导入硬件配置
│   │   └── packages.nix          # 导入自定义包
│   ├── system/                   # 纯系统级配置
│   ├── device/hardware/          # 硬件特定配置
│   ├── modules/                  # 所有 NixOS 模块
│   │   ├── programs/             # 系统级程序模块
│   │   ├── services/             # 系统服务模块
│   │   ├── virtualisation/       # 虚拟化模块
│   │   └── packages/             # 系统级包模块
│   ├── pkgs/                     # 自定义包定义
│   │   ├── data/fonts/           # 字体打包
│   │   └── tools/networking/     # 网络工具打包
│   └── home/                     # Home Manager 配置
│       └── programs/             # 用户程序分类配置
```

## 系统配置

### 硬件与引导

| 模块 | 说明 |
|------|------|
| hardware-configuration.nix | 自动生成，AMD CPU + NVMe，Btrfs（subvol=@ + @home），zstd 压缩 |
| nvidia.nix | NVIDIA 开源 GPU 内核模块驱动（nvidia-open） |
| boot.nix | GRUB 引导（EFI），CachyOS Bore v3 内核 |

### 系统基础

| 模块 | 说明 |
|------|------|
| nix.nix | 开启 Flakes，清华/中科大镜像源，自动优化，垃圾回收，stateVersion 25.05 |
| networking.nix | 主机名 `mioha-nix`，NetworkManager，关闭防火墙 |
| user.nix | 用户 `mioha`，组：wheel、networkmanager、libvirtd、kvm、input、uinput |
| i18n.nix | 时区上海，英文 locale + 中文支持，Fcitx5 输入法（中文 + 日语 Mozc + Mellow 主题） |
| environment.nix | 系统软件包（VSCode、Vim、Git、Kitty、Fish、Wine、distrobox 等），图标主题（Adwaita/MoreWaita/Papirus），光标主题 |

### 字体

| 模块 | 说明 |
|------|------|
| fonts.nix | Noto 中日韩 + Color Emoji，JetBrains Mono，Fira Code Nerd Font，文泉驿微米黑，HarmonyOS Sans（自定义打包） |
| harmonyos-sans.nix | 从 GitHub 拉取 HarmonyOS Sans 字体并安装 |

### 桌面环境

| 模块 | 说明 |
|------|------|
| desktop.nix | Niri（Wayland 平铺窗口管理器，使用 shorin-niri 定制构建），Ly 显示管理器，gvfs |
| neovim.nix | Neovim（默认编辑器 + Python3 支持） |
| firefox.nix | Firefox 浏览器（备用） |
| obs-studio.nix | OBS Studio（CUDA 加速 + 多插件：wlrobs、backgroundremoval、pipewire、vaapi、vkcapture 等） |

### 系统服务

| 模块 | 说明 |
|------|------|
| pipewire.nix | 音频服务 + PulseAudio 兼容 |
| openssh.nix | SSH 服务，允许密码登录，禁止 root 密码登录 |
| flatpak.nix | Flatpak 包管理 + xdg-desktop-portal-gtk |
| polkit.nix | Polkit 权限管理 + GNOME 认证代理 |
| daed.nix | DAED 代理（daeuniverse），监听 127.0.0.1:2023，防火墙端口 12345 |
| libvirtd.nix | KVM/QEMU 虚拟机，swtpm + virtiofsd |
| steam.nix | Steam + 远程游玩 + 专用服务器防火墙 |
| podman.nix | Podman 容器引擎 + Docker 兼容层 |
| vmware-workstation.nix | VMware Workstation 支持 |

### 自定义包

| 包 | 说明 |
|----|------|
| clash-party.nix | Clash Party（自定义打包，pkgs/tools/networking/） |
| harmonyos-sans.nix | HarmonyOS Sans 字体（自定义打包，pkgs/data/fonts/） |

## Home Manager

### 基础配置

| 模块 | 说明 |
|------|------|
| programs.nix | 用户 `mioha`，聚合所有 Home 模块，启用 LazyVim + Git |
| nixpkgs.nix | 允许非自由包，pipx 覆盖，允许不安全包 |
| session.nix | Flatpak 数据目录，终端设为 Kitty，EDITOR=nvim，BROWSER=google-chrome |

### Desktop

| 工具 | 说明 |
|------|------|
| nwg-look | GTK 主题配置 |
| wf-recorder / slurp / grim | Wayland 录屏/截图 |
| imv | 图片查看器 |
| wl-clipboard | Wayland 剪贴板 |
| niri/ | [shorin-niri-nix](https://github.com/yigexuanmu/shorin-niri-nix) — Niri 平铺窗口管理器配置 |
| thunar | XFCE 文件管理器 + tumbler 缩略图服务 |
| swww | Wayland 动态壁纸 |

### Develop

| 工具 | 说明 |
|------|------|
| ripgrep / jq / yq-go | 搜索/JSON/YAML 处理 |
| python314 + uv + pip + pipx | Python 开发 |
| ffmpeg | 音视频处理 |
| websocat | WebSocket 工具 |
| android-tools | Android ADB |
| hugo + glow | 静态站点 + Markdown 渲染 |
| nix-output-monitor | Nix 构建输出监控 |
| strace / ltrace / lsof | 调试工具 |

### Terminal

| 工具 | 说明 |
|------|------|
| yazi | 终端文件管理器 |
| kitty | 终端模拟器 |
| btop | 系统监控 |
| fastfetch | 系统信息 |
| starship | Shell 提示符 |
| eza / fzf | 增强 ls / 模糊搜索 |
| tty-clock | 终端时钟 |
| fish | Shell（默认） |
| miyu | [Miyu](https://github.com/yigexuanmu/Miyu) — 基于 Rust 的终端 AI 助手 |

### Entertain

| 工具 | 说明 |
|------|------|
| splayer | 播放器 |
| cava | 音频可视化 |
| kazumi | 漫画阅读器 |
| mpv | 媒体播放器 |
| cowsay | 说话的牛 |

### Games

| 工具 | 说明 |
|------|------|
| lutris | 游戏管理器 |
| protonplus | Proton 兼容层管理 |
| osu-lazer-bin | osu! |
| prismlauncher | Minecraft 启动器 |
| mangohud | 游戏性能监控 |

### Utility

| 工具 | 说明 |
|------|------|
| obs-studio | 录屏推流 |
| scrcpy | Android 投屏 |
| tesseract | OCR |
| showmethekey | 按键显示 |
| aria2 | 下载工具 |
| nmap / iperf3 / dnsutils / mtr | 网络工具 |
| pciutils / usbutils / lm_sensors | 硬件监控 |

## 致谢

- [SHORiN-KiWATA](https://github.com/SHORiN-KiWATA) — 配置文件参考
- [brokenshine/nixos-configs](https://gitee.com/brokenshine/nixos-configs) — NixOS 配置参考
- [NixOS-CN 安装教程](https://nixos-cn.org/tutorials/installation) — 安装教程参考
- [opencode](https://github.com/anomalyco/opencode) — 开源 AI 编程助手
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/zh) — NixOS 与 Flakes 中文教程
