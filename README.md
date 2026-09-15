# my-nixos-config / wsl

NixOS-WSL 发行版配置，部署位置 `/etc/nixos`，主机名 `mioha-wsl`，用户 `mioha`（fish）。

## flake inputs

- `nixpkgs`（nixos-unstable）、`home-manager`、`lazyvim-nix`、`NixOS-WSL`、`stylix`、`Miyu`

## 输出

- `nixosConfigurations.mioha-wsl`：系统配置，内嵌 `home-manager.users.mioha`
- `homeConfigurations.mioha`：独立 home 配置，与内嵌共用同一 `home.nix`，`nh os switch` 和 `nh home switch` 都可用

## 目录

```text
flake.nix                          # 入口
configuration/
  mioha-wsl/                       # home.nix / system.nix / modules.nix 聚合入口
  system/                          # wsl / nix / networking / user / i18n / fonts / environment
  modules/
    programs/neovim.nix            # 默认编辑器 + Python3
    services/openssh.nix           # SSH，允许密码登录，禁 root 密码登录
    virtualisation/podman.nix      # 容器引擎 + docker 兼容
  home/
    programs.nix / session.nix     # 用户名、家目录、EDITOR、LazyVim、git
    programs/Develop/              # rg、jq、yq、python314 + uv + pipx、ffmpeg、hugo、glow、opencode、android-tools 等
    programs/Terminal/             # fish、starship、btop、fzf、yazi、fastfetch、eza，外加 fish / fastfetch dotfiles
  wallpaper/wallpaper.png          # stylix 壁纸 + matugen 取色源
```

## WSL 适配

- `wsl.enable` + `wsl.defaultUser = "mioha"`，`wheel` 免密 sudo
- GPU-PV：`wsl.useWindowsDriver` + `hardware.graphics`，`LD_LIBRARY_PATH` 指向 `/usr/lib/wsl/lib`，`GALLIUM_DRIVER=d3d12`，附 `mesa-demos` / `vulkan-tools` 验证（`glxinfo -B` / `vulkaninfo --summary`）
- 容器 GPU：静态 CDI 规格 `/etc/cdi/nvidia.yaml`，podman / docker 均可 `--device nvidia.com/gpu=all`
- nix-ld（含 `NIX_LD_LIBRARY_PATH` 合并 `/usr/lib/wsl/lib`，供 `nvidia-smi` 等通用二进制使用）
- 补 `wsl-mnt-guard.service` 缺的 `/bin/true` 符号链接
- nix 配置：flakes、清华 / 中科大镜像、自动优化与回收，`stateVersion` 保持 `26.05`
- 时区上海，中英 locale，Noto CJK + Emoji + JetBrainsMono Nerd Font

## 主题

stylix，深色。壁纸经 matugen（M3 TonalSpot，与 noctalia 同管线）构建期取色，按 M3 dark role 映射为 base16（映射表见 `configuration/home/theme.nix`），下发给 fish、starship（catppuccin powerline 预设套 `base16` 调色板）、btop、fzf、yazi。Neovim 交给 LazyVim。WSL 无 D-Bus 会话，dconf 已禁用。

## 使用

```sh
nh os switch /etc/nixos
nh home switch /etc/nixos   # 同一份 home.nix，独立切换
```

说明：`~/.config/fastfetch/logo.png` 需自行放置（仅影响显示）。`configuration.nix.bak` 为安装器原文件备份，未纳入本分支。
