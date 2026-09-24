# My NixOS Configuration

> [!WARNING]
> 此配置并非完全可复现，仅作为个人环境的大致参考。硬件配置、秘密信息、部分外部 flake 版本等需要手动适配。

基于 Flake 的 NixOS 系统配置，模块化分层管理，本仓库已 Git 版本控制。

## Flake Inputs

| Input | 来源 | 说明 |
|-------|------|------|
| nixpkgs | [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs) | Nix 包集合 (nixos-unstable) |
| home-manager | [nix-community/home-manager](https://github.com/nix-community/home-manager) | 用户级包管理与配置 |
| lazyvim | [pfassina/lazyvim-nix](https://github.com/pfassina/lazyvim-nix) | LazyVim Neovim 配置 |
| nix-cachyos-kernel | [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel) | CachyOS BORE 内核 |
| daeuniverse | [daeuniverse/flake.nix](https://github.com/daeuniverse/flake.nix) | DAED 网络代理 |
| disko | [nix-community/disko](https://github.com/nix-community/disko) | 声明式磁盘分区与挂载管理 |
| noctalia | [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia) | Noctalia Shell（系统包安装） |
| miyu-agent-nix | [yigexuanmu/miyu-agent-nix](https://github.com/yigexuanmu/miyu-agent-nix) | 终端 AI 助手 Miyu |
| niri-glass | [yigexuanmu/Niri-glass](https://github.com/yigexuanmu/Niri-glass) | Niri 平铺窗口管理器定制构建（beta 分支） |
| nur | [nix-community/NUR](https://github.com/nix-community/NUR) | Nix 用户仓库（zcode、workbuddy 等） |
| waydroid-nvidia-nix | [yigexuanmu/waydroid-nvidia-nix](https://github.com/yigexuanmu/waydroid-nvidia-nix) | NVIDIA GPU Waydroid 加速（Neo 分支） |
| folia-major | [yigexuanmu/folia-major](https://github.com/yigexuanmu/folia-major) | Folia (Minecraft) 相关包 |

## 目录结构

```
├── flake.nix                     # Flake 入口
├── reinstall.sh                  # LiveCD 一键重装脚本（UEFI + disko LVM/btrfs + swapfile）
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
| hardware-config.nix | 手动配置，AMD CPU + NVMe 内核模块，nixpkgs.hostPlatform，AMD CPU 微码 |
| disko.nix | GPT 5G EFI + LVM (vg-mioha) + Btrfs（卷标 pc-mioha），按功能划分 subvol：@Config→/etc、@Data→/var/lib、@Home→/home、@Library→/library、@Sandbox→/sandbox、@Snapshot→/.snapshots、System/@Boot→/boot、@Nix→/nix、@Store→/nix/store、@Guix→/gnu、@Guix-Store→/gnu/store、@Log、@Swap、@Tmp 等；swap 用 swapfile（16G，重装后手动创建） |
| nvidia.nix | NVIDIA 开源 GPU 内核模块驱动（nvidia-open） |
| boot.nix | GRUB（EFI，挂载点 /efi），CachyOS Bore x86_64-v3 内核，initrd LVM，/nix、/gnu 等 neededForBoot |

### 系统基础

| 模块 | 说明 |
|------|------|
| nix.nix | Lix (latest)，Flakes + nix-command，清华/中科大/蓝脸 attic 镜像源，cachyos-kernel overlay，stateVersion 26.05 |
| networking.nix | 主机名 `mioha-nix`，NetworkManager，防火墙关闭 |
| user.nix | 用户 `mioha`，组：wheel、networkmanager、libvirtd、kvm、input、audio、uinput、podman |
| i18n.nix | 时区上海，英文 locale + 中文支持，Fcitx5 输入法（含日语 Mozc） |
| environment.nix | 系统软件包（gcc、nh、git、distrobox、gamescope、waydroid-helper、xwayland-satellite 等），allowUnfree |
| fonts.nix | Noto 中日韩 + Color Emoji，JetBrains Mono / Fira Code Nerd Font 等 |
| noctalia.nix | 安装 Noctalia Shell（inputs.noctalia） |

### 桌面环境

| 模块 | 说明 |
|------|------|
| desktop.nix | Niri（Wayland 平铺窗口管理器，niri-glass 定制构建），Ly 显示管理器，gvfs |
| neovim.nix | Neovim（默认编辑器 + Python3 支持） |
| firefox.nix | Firefox 浏览器（备用） |
| obs-studio.nix | OBS Studio（CUDA 加速 + 多插件：wlrobs、backgroundremoval、pipewire、vaapi、vkcapture 等） |
| virt-manager.nix | Virtual Machine Manager 图形化管理前端 |
| steam.nix | Steam + 远程游玩 + 专用服务器防火墙 |

### 系统服务

| 模块 | 说明 |
|------|------|
| pipewire.nix | 音频服务 + PulseAudio 兼容 |
| openssh.nix | SSH 服务，允许密码登录，禁止 root 密码登录 |
| flatpak.nix | Flatpak 包管理 + xdg-desktop-portal-gtk |
| polkit.nix | Polkit 权限管理 + GNOME 认证代理 |
| daed.nix | DAED 代理（daeuniverse），监听 127.0.0.1:2023，防火墙端口 12345 |
| waydroid-nvidia.nix | Waydroid NVIDIA GPU 加速（flake waydroid-nvidia-nix），165Hz 刷新率 |
| guix.nix | Guix 包管理服务，SJTU/CERNET 镜像，周度 GC（保留 1 个月、≥10G 空闲、去重） |
| services.nix | 杂项服务（linyaps） |
| libvirtd.nix | KVM/QEMU 虚拟机，swtpm + virtiofsd |
| podman.nix | Podman 容器引擎 + Docker 兼容层 |
| vmware-workstation.nix | VMware Workstation + USB Arbitrator |

### 自定义包

| 包 | 说明 |
|----|------|
| clash-party.nix | Clash Party（自定义打包，pkgs/tools/networking/ 与 modules/packages/ 引用） |
| harmonyos-sans.nix | HarmonyOS Sans 字体（自定义打包，pkgs/data/fonts/） |

## Home Manager

### 基础配置

| 模块 | 说明 |
|------|------|
| programs.nix | 用户 `mioha`，聚合所有 Home 模块，启用 LazyVim + Git，stateVersion 26.05 |
| nixpkgs.nix | 允许非自由包，pipx 覆盖，不安全包白名单 |
| session.nix | Flatpak 数据目录，MIME 默认应用（目录→Nautilus、浏览器→Chrome），EDITOR=nvim、TERMINAL=kitty、BROWSER=google-chrome |
| services.nix | mpris-proxy（蓝牙媒体控制） |

### Desktop

| 工具 | 说明 |
|------|------|
| nwg-look | GTK 主题配置 |
| wf-recorder / slurp / grim | Wayland 录屏/截图 |
| imv | 图片查看器 |
| wl-clipboard | Wayland 剪贴板 |
| nautilus | GNOME 文件管理器 |
| pywalfox-native | Firefox 壁纸取色联动 |
| 主题套件 | papirus-icon-theme、papirus-folders、adw-gtk3、afterglow-cursors、qt5ct/qt6ct、gnome-keyring |
| niri/ | Niri 窗口管理器 dotfiles（binds/blur/config/pop-drop.kdl） |

### Develop

| 工具 | 说明 |
|------|------|
| ripgrep / jq / yq-go | 搜索/JSON/YAML 处理 |
| python314 + uv + pip + pipx | Python 开发 |
| nodejs | Node.js 运行时 |
| ffmpeg | 音视频处理 |
| websocat / socat | WebSocket / 网络工具 |
| android-tools | Android ADB |
| hugo + glow | 静态站点 + Markdown 渲染 |
| nix-output-monitor / nh | Nix 构建输出监控 / NixOS 系统管理 |
| strace / ltrace / lsof | 调试工具 |
| vscode / git | 编辑器与版本控制 |
| opencode / pi-coding-agent | AI 编程助手 |
| zcode / workbuddy | NUR 包（Sittymin.zcode、MCSeekeri.workbuddy） |

### Terminal

| 工具 | 说明 |
|------|------|
| yazi | 终端文件管理器 |
| kitty | 终端模拟器 |
| btop | 系统监控（包装 LD_LIBRARY_PATH→/run/opengl-driver） |
| fastfetch | 系统信息 |
| starship | Shell 提示符 |
| eza / fzf / chafa | 增强 ls / 模糊搜索 / 终端图像 |
| tty-clock | 终端时钟 |
| fish | Shell（默认） |
| miyu | [miyu-agent-nix](https://github.com/yigexuanmu/miyu-agent-nix) — 终端 AI 助手 |

### Entertain

| 工具 | 说明 |
|------|------|
| folia-major | Folia (Minecraft) 相关包（flake） |
| qq | QQ 聊天 |
| playerctl / cava | 媒体控制 / 音频可视化 |
| kazumi | 漫画阅读器 |
| mpv / google-chrome | 媒体播放器 / 浏览器 |
| cowsay / wine | 说话的牛 / Wine (stagingFull) |

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
| gimp / kdenlive | 图像编辑 / 视频剪辑 |
| scrcpy | Android 投屏 |
| tesseract | OCR |
| showmethekey / evtest | 按键显示 / 输入设备测试 |
| 归档工具 | zip、xz、unzip、p7zip、file-roller、zstd |
| 常用工具 | file、which、tree、gnused、gnutar、gawk、gnupg、wget |
| 网络工具 | aria2、nmap、iperf3、dnsutils、mtr、ldns、ipcalc、ethtool、socat |
| 硬件监控 | pciutils、usbutils、lm_sensors、iotop、iftop、sysstat |

## 重装

LiveCD 下一键重装（disko LVM/btrfs + swapfile + nixos-install）：

```bash
git clone https://github.com/yigexuanmu/my-nixos-config.git
cd my-nixos-config
sudo ./reinstall.sh [--yes]   # --yes 跳过目标盘二次确认
```

## 致谢

- [SHORiN-KiWATA](https://github.com/SHORiN-KiWATA) — 配置文件参考
- [brokenshine/nixos-configs](https://gitee.com/brokenshine/nixos-configs) — NixOS 配置参考
- [NixOS-CN 安装教程](https://nixos-cn.org/tutorials/installation) — 安装教程参考
- [opencode](https://github.com/anomalyco/opencode) — 开源 AI 编程助手
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/zh) — NixOS 与 Flakes 中文教程
