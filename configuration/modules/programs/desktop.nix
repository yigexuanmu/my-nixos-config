# ────────────────────────────────────────────────────────────
# 文件关联（仅 /etc/nixos 范围）
#   上游（引用本文件）：configuration/mioha-main/modules.nix
#   下游（本文件引用）：无
#   相关（语义关联）：configuration/home/programs/Desktop/default.nix（自动：desktop 的配置）
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
    xdg-desktop-portal-wlr
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  programs.niri = {
    enable = true;
    package = inputs.niri-mioha.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
  programs.firefox.enable = true;
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
