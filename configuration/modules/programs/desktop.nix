# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/home/programs/Desktop/default.nix（自动：desktop 的配置；同名 fuzzel）
# ────────────────────────────────────────────────────────────

{ 
  pkgs,
  inputs,
  ...
}: {
  # 保留 xserver: 仅为其 XKB 键盘配置供 ly/niri/XWayland 使用，不启图形 X 会话
  services.xserver.enable = true;
  services.displayManager.ly.enable = true;
  services.gvfs.enable = true;
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  programs.niri = {
    enable = true;
    package = inputs.niri-mioha.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
  programs.firefox.enable = true;

  # niri 下屏幕共享、截图、polkit 授权都依赖 xdg-desktop-portal。
  # 只装 wlr 后端包不够，需要启用模块并给 screencast 指定 fuzzel 选择器。
  xdg.portal = {
    enable = true;
    config.common.default = "*";
    extraPortals = [pkgs.xdg-desktop-portal-gtk];

    wlr.enable = true;
    wlr.settings.screencast = {
      chooser_type = "dmenu";
      chooser_cmd = "${pkgs.fuzzel}/bin/fuzzel -d -l 10 -p 'Select display to share: '";
    };
  };
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi
      obs-gstreamer
      obs-vkcapture
    ];
  };
}
